import os
import math
import json
from typing import List, Dict
from sqlalchemy.orm import Session
from langchain_chroma import Chroma
from langchain_core.documents import Document
from src.utils.llm_utils import llm_generate_to_string
from src.routes.search_route import LocalEmbeddings

class CandidateSearchService:
    def __init__(self):
        self.vector_dir = os.path.join(os.path.dirname(__file__), "..", "..", "vectordb", "candidates")
        os.makedirs(self.vector_dir, exist_ok=True)
        self.embeddings = LocalEmbeddings()
        self.vectorstore = Chroma(
            collection_name="candidates",
            persist_directory=self.vector_dir,
            embedding_function=self.embeddings,
            collection_metadata={"hnsw:space": "cosine"}
        )

    def init_embeddings(self, documents: List[Document]) -> bool:
        """Adds documents to the vector store. Returns True if added, False if skipped."""
        if not documents:
            return False
        
        # 1. Get unique interview IDs from documents
        interview_ids = list(set([str(doc.metadata["interview_id"]) for doc in documents]))
        
        # 2. Check existence and log
        contains_existing = False
        for iid in interview_ids:
            existing = self.vectorstore._collection.get(where={"interview_id": iid})
            if existing["ids"]:
                contains_existing = True
                print(f"      - [AI Embed] Status: ALREADY embedded. Skipping this candidate.")
                break
        
        if contains_existing:
            return False

        # 3. Add to vector store
        print(f"      - [AI Embed] Status: NEW. Preparing to embed {len(documents)} document chunks...")
        self.vectorstore.add_documents(documents)
        print(f"      - [AI Embed] Successfully added chunks to VectorDB.")
        return True

    def search_candidates(self, job_id: int, query: str, k: int = 10) -> List[Dict]:
        """Performs Hybrid RAG search and returns ranked candidates."""
        print(f"\n[AI Search] Original query: '{query}'")
        
        # 1. Query Rewrite (New Step)
        rewritten_query = self._rewrite_query(query)
        print(f"[AI Search] Rewritten query: '{rewritten_query}'")
        
        # 2. Vector Search for top chunks (Step 2 in flow)
        # We use rewritten_query for better vector matching
        results = self.vectorstore.similarity_search_with_score(
            rewritten_query,
            k=50, 
            filter={"job_id": str(job_id)}
        )
        
        if not results:
            print("[AI Search] No chunks found for this job.")
            return []

        # 3. Hybrid Scoring (0.7 Vector + 0.3 Keyword)
        # We still use original query terms for keyword matching to stick to user's exact words
        query_terms = query.lower().split()
        candidate_data = {}

        for doc, distance in results:
            cid = doc.metadata["candidate_id"]
            content = doc.page_content.lower()
            
            # Normalization: Cosine distance to similarity (0-1)
            vector_sim = 1.0 - (distance / 2.0)
            
            # Simple keyword matching score
            matches = sum(1 for term in query_terms if term in content)
            keyword_score = min(matches / len(query_terms), 1.0) if query_terms else 0
            
            # Hybrid Score formula: 0.7 * vector + 0.3 * keyword
            hybrid_score = (0.7 * vector_sim) + (0.3 * keyword_score)
            
            if cid not in candidate_data:
                candidate_data[cid] = {
                    "candidate_id": cid,
                    "interview_id": doc.metadata["interview_id"],
                    "best_score": hybrid_score,
                    "chunks": [doc.page_content],
                }
            else:
                # Update candidate's best score and collect chunks
                if hybrid_score > candidate_data[cid]["best_score"]:
                    candidate_data[cid]["best_score"] = hybrid_score
                
                if len(candidate_data[cid]["chunks"]) < 5:
                    candidate_data[cid]["chunks"].append(doc.page_content)

        # 4. Sort candidates by Hybrid Score and identify Top 10 for LLM Ranking
        top_10 = sorted(candidate_data.values(), key=lambda x: x["best_score"], reverse=True)[:10]
        
        print(f"[AI Search] Hybrid search found {len(candidate_data)} candidates. Selected Top {len(top_10)} for LLM.")
        for i, c in enumerate(top_10):
            print(f"  #{i+1}: Candidate {c['candidate_id']} (Score: {c['best_score']:.4f})")

        # 6. LLM Ranking (Use ORIGINAL query to ensure intent is met)
        return self._rank_with_llm(query, top_10)

    def _rewrite_query(self, query: str) -> str:
        """Transforms the user query into a more descriptive prompt for better retrieval."""
        prompt = f"""
You are an HR Recruitment Expert. 
Your task is to take a short search query from HR and expand it into a detailed description to improve candidate retrieval.
Identify relevant Skills, Qualities, and Experiences related to the query.

Original Query: "{query}"

Return ONLY the "enhanced search query" without any preamble or summary. The output should be primarily in Thai to match the resume content.
"""
        rewritten = llm_generate_to_string(prompt).strip()
        # Clean markdown if present
        if rewritten.startswith('"') and rewritten.endswith('"'):
            rewritten = rewritten[1:-1]
        return rewritten

    def _rank_with_llm(self, query: str, candidates: List[Dict]) -> List[Dict]:
        """Uses LLM to rank the top candidates based on their context chunks."""
        
        if not candidates:
            return []

        # Format candidates for prompt
        candidates_str = ""
        print("[AI Search] Preparing context for LLM ranking...")
        for i, cand in enumerate(candidates):
            chunks_text = "\n".join([f"- {c}" for c in cand["chunks"]])
            candidates_str += f"\nCandidate ID: {cand['candidate_id']}\nInterview ID: {cand['interview_id']}\nContext:\n{chunks_text}\n"
            print(f"  - Candidate {cand['candidate_id']}: Using {len(cand['chunks'])} context blocks.")

        prompt = f"""
You are an HR Expert. 
Evaluate the following candidates based on this search query: "{query}"

Candidates and relevant context:
{candidates_str}

Score each candidate from 0.0 to 10.0 based on their match with the query. 
Provide a brief reason for the score in Thai for the HR user.

Return ONLY a JSON Array in this exact format:
[
  {{
    "candidate_id": "ID",
    "interview_id": "ID",
    "score": 0.0,
    "reason": "Brief justification in Thai..."
  }}
]
Do not include any other text or explanation.
"""

        print(prompt)
        
        response_text = llm_generate_to_string(prompt)
        
        try:
            # Clean response text if it contains markdown
            if "```json" in response_text:
                response_text = response_text.split("```json")[1].split("```")[0].strip()
            elif "```" in response_text:
                 response_text = response_text.split("```")[1].split("```")[0].strip()
            
            rankings = json.loads(response_text)
            
            # Map evidence chunks back to the ranked results
            temp_map = {str(c["candidate_id"]): c["chunks"] for c in candidates}
            
            for res in rankings:
                # Include the top 3 chunks as evidence for clarity and space
                res["evidence"] = temp_map.get(str(res["candidate_id"]), [])[:3]
            
            # Sort by LLM score desc
            rankings.sort(key=lambda x: x.get("score" , 0), reverse=True)
            return rankings[:5] # Take top 5 as requested
            
        except Exception as e:
            print(f"Error parsing LLM ranking: {e}")
            # Fallback to vector ranking if LLM fails
            fallback = []
            for cand in candidates[:5]:
                fallback.append({
                    "candidate_id": cand["candidate_id"],
                    "interview_id": cand["interview_id"],
                    "score": round(cand["best_score"] * 10, 1),
                    "reason": "Score based on text similarity (Fallback)",
                    "evidence": cand["chunks"][:3]
                })
            return fallback

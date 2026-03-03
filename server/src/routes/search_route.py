from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from src.databases.db_connect import get_db
from src.utils.auth_utils import get_current_user_id
from src.schemas.search_schema import SearchRequest

import os
import hashlib
import numpy as np

from huggingface_hub import InferenceClient
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_chroma import Chroma
from langchain_core.documents import Document
from langchain_core.embeddings import Embeddings

search_router = APIRouter()

VECTOR_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "vectordb", "search_job")
HASH_FILE = os.path.join(VECTOR_DIR, "hash.txt")

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=100,
    chunk_overlap=10,
    separators=["\n\n", "\n", ".", " ", ""],
)


def _load_hash() -> str | None:
    if os.path.exists(HASH_FILE):
        with open(HASH_FILE, "r") as f:
            return f.read().strip()
    return None


def _save_hash(h: str):
    os.makedirs(VECTOR_DIR, exist_ok=True)
    with open(HASH_FILE, "w") as f:
        f.write(h)


class HFEmbeddings(Embeddings):
    def __init__(self):
        self.client = InferenceClient(
            provider="scaleway",
            api_key=os.environ["HF_TOKEN"],
        )
        self.model = "Qwen/Qwen3-Embedding-8B"

    def embed_documents(self, texts: list[str]) -> list[list[float]]:
        vectors = []
        for t in texts:
            vec = self.client.feature_extraction(t, model=self.model)
            vectors.append(np.array(vec).flatten().tolist())
        return vectors

    def embed_query(self, text: str) -> list[float]:
        vec = self.client.feature_extraction(text, model=self.model)
        return np.array(vec).flatten().tolist()


embeddings = HFEmbeddings()
vectorstore = Chroma(
    collection_name="jobs",
    persist_directory=VECTOR_DIR,
    embedding_function=embeddings,
)


def _compute_hash(rows: list[dict]) -> str:
    raw = "".join(f"{r['id']}|{r['title']}|{r['description']}" for r in rows)
    return hashlib.md5(raw.encode()).hexdigest()


def _sync_chroma(db: Session):
    rows_raw = db.execute(
        text("SELECT id, title, description FROM jobs")
    ).fetchall()
    rows = [dict(r._mapping) for r in rows_raw]

    current_hash = _compute_hash(rows)
    if current_hash == _load_hash():
        return

    existing = vectorstore._collection.get()
    if existing["ids"]:
        vectorstore._collection.delete(ids=existing["ids"])

    documents = []
    for r in rows:
        full_text = f"{r['title']} {r['description']}"
        chunks = text_splitter.split_text(full_text)

        for idx, chunk in enumerate(chunks):
            documents.append(
                Document(
                    page_content=chunk,
                    metadata={
                        "job_id": str(r["id"]),
                        "title": r["title"],
                        "description": r["description"],
                        "chunk_index": idx,
                    },
                )
            )

    if documents:
        vectorstore.add_documents(documents)

    _save_hash(current_hash)


@search_router.post("/")
def search(
    search_request: SearchRequest,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id),
):
    _sync_chroma(db)

    results = vectorstore.similarity_search_with_relevance_scores(
        search_request.query,
        k=20,
    )

    seen_jobs = {}
    for doc, score in results:
        job_id = doc.metadata["job_id"]
        if job_id not in seen_jobs or score > seen_jobs[job_id]["similarity"]:
            seen_jobs[job_id] = {
                "title": doc.metadata["title"],
                "description": doc.metadata["description"],
                "similarity": score,
            }

    output = sorted(seen_jobs.values(), key=lambda x: x["similarity"], reverse=True)

    return {"message": output[:10]}
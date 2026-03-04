from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from src.databases.db_connect import get_db
from src.utils.auth_utils import get_current_user_id
from src.schemas.search_schema import SearchRequest

import os
import hashlib
import numpy as np

from FlagEmbedding import BGEM3FlagModel
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


_model = None

def _get_model() -> BGEM3FlagModel:
    global _model
    if _model is None:
        _model = BGEM3FlagModel("BAAI/bge-m3", use_fp16=True)
    return _model


class LocalEmbeddings(Embeddings):
    def embed_documents(self, texts: list[str]) -> list[list[float]]:
        model = _get_model()
        result = model.encode(texts)
        return result["dense_vecs"].tolist()

    def embed_query(self, text: str) -> list[float]:
        model = _get_model()
        result = model.encode([text])
        return result["dense_vecs"][0].tolist()


os.makedirs(VECTOR_DIR, exist_ok=True)

embeddings = LocalEmbeddings()
vectorstore = Chroma(
    collection_name="jobs",
    persist_directory=VECTOR_DIR,
    embedding_function=embeddings,
    collection_metadata={"hnsw:space": "cosine"}
)


def _compute_hash(rows: list[dict]) -> str:
    raw = "".join(f"{r['id']}|{r['title']}|{r['description']}" for r in rows)
    return hashlib.md5(raw.encode()).hexdigest()


def _sync_chroma(db: Session):
    rows_raw = db.execute(
        text("SELECT id, title, description FROM jobs WHERE is_active = true")
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
    try:
        _sync_chroma(db)
    except Exception as e:
        import traceback
        traceback.print_exc()

    if vectorstore._collection.count() == 0:
        return {"message": []}

    results = vectorstore.similarity_search_with_score(
        search_request.query,
        k=20,
    )

    seen_jobs = {}
    import math
    for doc, distance in results:
        job_id = doc.metadata["job_id"]
        similarity = 1.0 - (distance / 2.0)
        if math.isnan(similarity):
            similarity = 0.0
            
        if job_id not in seen_jobs or similarity > seen_jobs[job_id]["similarity"]:
            seen_jobs[job_id] = {
                "id": job_id,
                "title": doc.metadata["title"],
                "description": doc.metadata["description"],
                "similarity": similarity,
            }

    output = sorted(seen_jobs.values(), key=lambda x: x["similarity"], reverse=True)

    return {"message": output}
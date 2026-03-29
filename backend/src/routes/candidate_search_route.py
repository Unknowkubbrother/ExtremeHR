from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from src.databases.db_connect import get_db
from src.utils.auth_utils import get_current_user_id
from src.services.candidate_embedding_service import CandidateEmbeddingService
from src.services.candidate_search_service import CandidateSearchService
from src.models.interview_model import Interview
from src.models.job_model import Job
from src.models.auth_model import User
from src.models.interview_question_model import InterviewQuestion
from src.models.chat_history_model import ChatHistory
from src.models.interview_summary_model import InterviewSummary
from src.enums.apply_status_enum import ApplyStatusEnum

candidate_search_router = APIRouter()

class CandidateInitRequest(BaseModel):
    job_id: int

class CandidateSearchRequest(BaseModel):
    job_id: int
    query: str

@candidate_search_router.post("/init-embedding")
def init_embedding(
    request: CandidateInitRequest,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id),
):
    """Initializes or updates embeddings for all candidates of a job."""
    
    # 1. Get all viewed interviews for this job
    # User: "init_embeddings เอาแค่ interview ที่เป็น view เท่านั้นนะ"
    interviews = db.query(Interview).filter(
        Interview.job_id == request.job_id,
        Interview.status == ApplyStatusEnum.VIEWED.value,
        Interview.is_active == True
    ).all()
    
    if not interviews:
        return {"message": "No interviews found for this job."}

    emb_service = CandidateEmbeddingService()
    search_service = CandidateSearchService()
    
    embedded_count = 0
    for interview in interviews:
        # Check if already embedded (simplified internal check)
        # Based on user: "ตรวจตลอดว่าคนไหน emb แล้วหรือยัง ไม่ emb ซ้ำนะ"
        
        # 1. Extract data chunks
        documents = emb_service.extract_candidate_data(db, interview.id)
        if documents:
            # 2. Add to Chroma with check for existence
            search_service.init_embeddings(documents)
            embedded_count += 1
            
    return {
        "message": f"Successfully processed {embedded_count} candidates.",
        "total_interviews": len(interviews)
    }

@candidate_search_router.post("/search")
def search_candidates(
    request: CandidateSearchRequest,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id),
):
    """Performs RAG + LLM search for candidates."""
    search_service = CandidateSearchService()
    
    try:
        results = search_service.search_candidates(request.job_id, request.query)
        
        # Hydrate results with candidate names if needed
        # (Chroma only has IDs, we can join with User table)
        final_results = []
        for res in results:
            user = db.query(User).filter(User.id == int(res["candidate_id"])).first()
            res["candidate_name"] = user.username if user else "Unknown"
            final_results.append(res)
            
        return {"results": final_results}
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

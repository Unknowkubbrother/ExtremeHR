from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel

from src.databases.db_connect import get_db
from src.llm.question_generated.service import generate_interview_questions, save_generated_questions

class GenerateRequest(BaseModel):
    interview_id: int
    hr_prompt: str

interview_question_router = APIRouter()

@interview_question_router.post("/test-generate")
def test_generate_questions(request: GenerateRequest, db: Session = Depends(get_db)):
    import traceback
    import sys
    
    try:
        results = generate_interview_questions(
            db=db,
            interview_id=request.interview_id,
            hr_prompt=request.hr_prompt
        )
        save_generated_questions(db, request.interview_id, results)
        
        return {"message": request.hr_prompt, "questions": results.model_dump()}
    except ValueError as e:
        # Known business logic errors (e.g. "Interview not found")
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        # Unexpected errors: log to backend, show generic to frontend
        print("=== ERROR DURING QUESTION GENERATION ===", file=sys.stderr)
        traceback.print_exc()
        print("========================================", file=sys.stderr)
        
        raise HTTPException(
            status_code=500, 
            detail="เกิดข้อผิดพลาดในการสร้างคำถามสัมภาษณ์ (Internal Server Error)."
        )

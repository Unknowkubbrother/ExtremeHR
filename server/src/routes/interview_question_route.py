from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel

from src.databases.db_connect import get_db
from src.llm.question_generated.service import generate_interview_questions, save_generated_questions
from src.llm.evl_question.evl_question import evaluate_single_answer as evaluate_llm_answer

class GenerateRequest(BaseModel):
    interview_id: int
    hr_prompt: str

class EvaluateRequest(BaseModel):
    question_id: int
    user_answer: str

interview_question_router = APIRouter()

@interview_question_router.post("/test-evaluate")
def test_evaluate_answer(request: EvaluateRequest, db: Session = Depends(get_db)):
    try:
        result = evaluate_llm_answer(
            db=db,
            question_id=request.question_id,
            user_answer=request.user_answer
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

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

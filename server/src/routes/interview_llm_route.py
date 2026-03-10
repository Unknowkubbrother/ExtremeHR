from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from sqlalchemy import text

from src.databases.db_connect import SessionLocal, get_db
from src.enums.apply_status_enum import ApplyStatusEnum
from src.llm.interview_summary.agent import (
    InterviewSummaryModel,
    LLMConfigurationError as SummaryLLMConfigurationError,
)
from src.llm.interview_summary.service import (
    generate_interview_summary,
    get_saved_interview_summary,
    save_interview_summary,
)
from src.llm.question_generated.agent import LLMConfigurationError
from src.llm.question_generated.service import generate_interview_questions, save_generated_questions
from src.routes.job_route import require_hr_role
from src.schemas.interview_schema import ApplyJobResponse

from src.utils.auth_utils import get_current_user_id
import asyncio

from src.utils.llm_utils import llm_generate_to_string

from src.llm.evl_question.evl_question import evaluate_llm_answer

class GenerateRequest(BaseModel):
    interview_id: int
    hr_prompt: str


class GenerateInterviewSummaryRequest(BaseModel):
    interview_id: int

class EvaluateRequest(BaseModel):
    question_id: int
    user_answer: str


interview_llm_router = APIRouter()

def _require_hr_interview_access(db: Session, interview_id: int, hr_user_id: int):
    sql_check = text("""
        SELECT i.id
        FROM interviews i
        JOIN jobs j ON i.job_id = j.id
        WHERE i.id = :interview_id AND j.user_id = :hr_user_id
    """)
    interview = db.execute(
        sql_check,
        {"interview_id": interview_id, "hr_user_id": hr_user_id},
    ).first()

    if not interview:
        raise HTTPException(
            status_code=403,
            detail="Not authorized or interview not found",
        )


def _require_interview_status(
    db: Session,
    interview_id: int,
    expected_status: ApplyStatusEnum,
):
    sql_check = text("""
        SELECT status
        FROM interviews
        WHERE id = :interview_id
    """)
    interview = db.execute(sql_check, {"interview_id": interview_id}).first()

    if not interview:
        raise HTTPException(status_code=404, detail="Interview not found")

    if interview.status != expected_status.value:
        raise HTTPException(
            status_code=409,
            detail=f"Interview must be in '{expected_status.value}' status before generating summary",
        )


def _require_hr_question_access(db: Session, question_id: int, hr_user_id: int):
    sql_check = text("""
        SELECT iq.id
        FROM interview_questions iq
        JOIN interviews i ON iq.interview_id = i.id
        JOIN jobs j ON i.job_id = j.id
        WHERE iq.id = :question_id AND j.user_id = :hr_user_id
    """)
    question = db.execute(
        sql_check,
        {"question_id": question_id, "hr_user_id": hr_user_id},
    ).first()

    if not question:
        raise HTTPException(
            status_code=403,
            detail="Not authorized or question not found",
        )


def _evaluate_answer_in_thread(question_id: int, user_answer: str):
    db = SessionLocal()
    try:
        return evaluate_llm_answer(
            db=db,
            question_id=question_id,
            user_answer=user_answer,
        )
    finally:
        db.close()


def _save_local_hr_evaluation(
    db: Session,
    question_id: int,
    hr_user_id: int,
    score: float,
    reason: str,
):
    question_row = db.execute(
        text("""
            SELECT iq.interview_id
            FROM interview_questions iq
            JOIN interviews i ON iq.interview_id = i.id
            JOIN jobs j ON i.job_id = j.id
            WHERE iq.id = :question_id AND j.user_id = :hr_user_id
        """),
        {"question_id": question_id, "hr_user_id": hr_user_id},
    ).first()

    if not question_row:
        raise HTTPException(
            status_code=403,
            detail="Not authorized or question not found",
        )

    sql_insert = text("""
        INSERT INTO chat_histories (interview_id, user_id, message, created_at)
        VALUES (:interview_id, :user_id, :message, NOW())
    """)
    db.execute(
        sql_insert,
        {
            "interview_id": question_row.interview_id,
            "user_id": hr_user_id,
            "message": (
                f"[AI][HR_LOCAL_EVAL:{question_id}] "
                f"Evaluation Score: {score:.2f}\nReason: {reason}"
            ),
        },
    )
    db.commit()

@interview_llm_router.get("/context/{interview_id}", tags=["Interview-llm"])
async def get_interview_context(interview_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    sql_check_user = text("SELECT role FROM users WHERE id = :user_id")
    user_record = db.execute(sql_check_user, {"user_id": user_id}).first()
    
    if not user_record or user_record.role.lower() != "candidate":
        return ApplyJobResponse(isSuccess=True)

    sql_check_context = text("SELECT context FROM interviews WHERE id = :interview_id AND user_id = :user_id")
    interview_record = db.execute(sql_check_context, {"interview_id": interview_id, "user_id": user_id}).first()
    
    if not interview_record:
        raise HTTPException(status_code=403, detail="Not authorized or interview not found")
        
    if interview_record.context:
        return ApplyJobResponse(isSuccess=True)

    sql_job = text("""
        SELECT j.title as jobtitle, j.description as jobdescription, j.responsibilities as jobresponsibilities,
               j.qualifications as jobqualifications, j.skills as jobskills
        FROM interviews i
        JOIN jobs j ON i.job_id = j.id
        WHERE i.id = :interview_id AND i.user_id = :user_id
    """)
    detail_job = db.execute(sql_job, {"interview_id": interview_id, "user_id": user_id}).first()
    if not detail_job:
        raise HTTPException(status_code=403, detail="Not authorized or interview not found")

    job_context = {
        "jobtitle": detail_job.jobtitle,
        "jobdescription": detail_job.jobdescription,
        "jobresponsibilities": detail_job.jobresponsibilities,
        "jobqualifications": detail_job.jobqualifications,
        "jobskills": detail_job.jobskills
    }

    if not job_context:
        raise HTTPException(status_code=404, detail="Job context not found")

    
    sql_get_resume = text("SELECT * FROM resumes WHERE user_id = :user_id")
    resume = db.execute(sql_get_resume, {"user_id": user_id}).first()
    
    if not resume:
        raise HTTPException(status_code=404, detail="Resume not found")
    
    resume_id = resume.id
    
    skills = db.execute(text("SELECT name FROM resume_skills WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    education = db.execute(text("SELECT degree,faculty,major,gpax  FROM resume_education WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    experience = db.execute(text("SELECT company,role,description FROM resume_experience WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    
    projects = db.execute(text("SELECT title,description FROM resume_projects WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    projects_list = [dict(p._mapping) for p in projects]
    
    resume_context = dict()
    resume_context["skills"] = [dict(row._mapping) for row in skills]
    resume_context["education"] = [dict(row._mapping) for row in education]
    resume_context["experience"] = [dict(row._mapping) for row in experience]
    resume_context["projects"] = projects_list


    prompt_template = f"""
คุณคือผู้ช่วย HR สำหรับเตรียม context ก่อนสัมภาษณ์งาน

โปรดวิเคราะห์ข้อมูล job และ resume แล้วสรุปเป็นข้อความภาษาไทยแบบกระชับ
โดยให้เนื้อหาครอบคลุมประเด็นต่อไปนี้อย่างเป็นธรรมชาติในย่อหน้าเดียว:
ตำแหน่งนี้ต้องการทักษะหรือคุณสมบัติสำคัญอะไร ผู้สมัครมีประสบการณ์ ทักษะ การศึกษา หรือโปรเจกต์ใดที่เกี่ยวข้อง
ผู้สมัครมีความเหมาะสมกับตำแหน่งนี้ในด้านใดบ้าง และมีประเด็นไหนที่ HR ควรถามเพิ่มเพื่อประเมินให้ชัดขึ้น

กติกา:
ตอบเป็น plain text เท่านั้น
ห้ามใช้ markdown ทุกชนิด
ห้ามทำเป็นข้อ
ห้ามใส่สัญลักษณ์นำหน้า
ห้ามแต่งข้อมูลเพิ่มจาก input
หากข้อมูลซ้ำกันให้สรุปรวมอย่างกระชับ
ความยาวไม่เกิน 1200 ตัวอักษร

job:
{job_context}

resume:
{resume_context}
"""
    result_context = await asyncio.to_thread(llm_generate_to_string, prompt_template)

    if not result_context:
        raise HTTPException(status_code=404, detail="llm context not found")


    sql_update = text("""
                UPDATE interviews
                SET context = :result_context, updated_at = NOW()
                WHERE id = :interview_id
            """)

    isUpdated = db.execute(sql_update, {
                "result_context": result_context,
                "interview_id": interview_id
            })
            
    if not isUpdated:
        raise HTTPException(status_code=400, detail="Can't update context")

    db.commit()

    return ApplyJobResponse(isSuccess=True)

@interview_llm_router.post("/generate-question", tags=["Interview-llm"])
def generate_questions(
    request: GenerateRequest,
    db: Session = Depends(get_db),
    hr_user_id: int = Depends(require_hr_role),
):
    import traceback

    try:
        _require_hr_interview_access(db, request.interview_id, hr_user_id)

        results = generate_interview_questions(
            db=db,
            interview_id=request.interview_id,
            hr_prompt=request.hr_prompt
        )

        results = save_generated_questions(db, request.interview_id, results)
        
        return {"message": request.hr_prompt, "questions": results.model_dump()}
    except LLMConfigurationError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except LookupError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        traceback.print_exc()

        raise HTTPException(
            status_code=500, 
            detail="เกิดข้อผิดพลาดในการสร้างคำถามสัมภาษณ์ (Internal Server Error)."
        )


@interview_llm_router.post(
    "/generate-summary",
    tags=["Interview-llm"],
    response_model=InterviewSummaryModel,
)
def generate_summary(
    request: GenerateInterviewSummaryRequest,
    db: Session = Depends(get_db),
    hr_user_id: int = Depends(require_hr_role),
):
    import traceback

    try:
        _require_hr_interview_access(db, request.interview_id, hr_user_id)
        _require_interview_status(
            db,
            request.interview_id,
            ApplyStatusEnum.VIEWED,
        )

        summary = generate_interview_summary(
            db=db,
            interview_id=request.interview_id,
        )
        return save_interview_summary(db, request.interview_id, summary)
    except SummaryLLMConfigurationError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except LookupError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception:
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail="เกิดข้อผิดพลาดในการสรุปผลสัมภาษณ์ (Internal Server Error).",
        )


@interview_llm_router.get(
    "/summary/{interview_id}",
    tags=["Interview-llm"],
    response_model=InterviewSummaryModel,
)
def get_interview_summary(
    interview_id: int,
    db: Session = Depends(get_db),
    hr_user_id: int = Depends(require_hr_role),
):
    _require_hr_interview_access(db, interview_id, hr_user_id)

    summary = get_saved_interview_summary(db, interview_id)
    if summary is None:
        raise HTTPException(status_code=404, detail="Interview summary not found")

    return summary

@interview_llm_router.post(
    "/evaluate-question",
    tags=["Interview-llm"],
)
async def evaluate_answer(
    request: EvaluateRequest,
    db: Session = Depends(get_db),
    hr_user_id: int = Depends(require_hr_role),
):
    try:
        _require_hr_question_access(db, request.question_id, hr_user_id)
        result = await asyncio.to_thread(
            _evaluate_answer_in_thread,
            request.question_id,
            request.user_answer,
        )
        _save_local_hr_evaluation(
            db,
            request.question_id,
            hr_user_id,
            float(result.get("score", 0)),
            str(result.get("reason", "")),
        )
        return result
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

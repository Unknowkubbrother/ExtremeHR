from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from src.databases.db_connect import get_db
from src.schemas.interview_schema import ApplyJobResponse, InterviewsResponse, HRCandidateResponse
from src.enums.apply_status_enum import ApplyStatusEnum
from src.utils.auth_utils import get_current_user_id
from src.routes.job_route import require_hr_role
from typing import List

interview_router = APIRouter()

@interview_router.post("/apply/{job_id}",response_model=ApplyJobResponse, tags=["Interview"])
def apply_job(job_id: int,db:Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):

    sql_check_job = text("SELECT id FROM jobs WHERE id = :id AND is_active = true")
    job = db.execute(sql_check_job, {"id": job_id}).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")

    sql_check_user = text("SELECT id FROM users WHERE id = :id AND role = 'candidate' AND is_active = true")
    user = db.execute(sql_check_user, {"id": user_id}).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    sql_check_apply = text("SELECT id, is_active FROM interviews WHERE user_id = :user_id AND job_id = :job_id")
    apply = db.execute(sql_check_apply, {"user_id": user_id, "job_id": job_id}).first()
    if apply:
        if apply.is_active:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You have already applied for this job")
        else:
            sql_reapply = text(f"UPDATE interviews SET is_active = true, status = '{ApplyStatusEnum.WAITING.value}' WHERE id = :id")
            db.execute(sql_reapply, {"id": apply.id})
            db.commit()
            return ApplyJobResponse(isSuccess=True)

    sql_apply_job = text(f"INSERT INTO interviews (user_id, job_id, status) VALUES (:user_id, :job_id, '{ApplyStatusEnum.WAITING.value}')")
    db.execute(sql_apply_job, {"user_id": user_id, "job_id": job_id})
    db.commit()

    return ApplyJobResponse(isSuccess=True)

@interview_router.post("/cancel/{job_id}", response_model=ApplyJobResponse, tags=["Interview"])
def cancel_job(job_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    sql_check_apply = text("SELECT id, status FROM interviews WHERE user_id = :user_id AND job_id = :job_id AND is_active = true")
    apply = db.execute(sql_check_apply, {"user_id": user_id, "job_id": job_id}).first()
    if not apply:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Application not found")
    
    if apply.status != ApplyStatusEnum.WAITING:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot cancel application that is not in waiting status")
        
    sql_cancel = text("UPDATE interviews SET is_active = false WHERE id = :id")
    db.execute(sql_cancel, {"id": apply.id})
    db.commit()
    
    return ApplyJobResponse(isSuccess=True)

@interview_router.get("/interviews", response_model=List[InterviewsResponse], tags=["Interview"])
def get_all(db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    sql_get_all = text("""
    SELECT i.id, i.status, i.created_at, 
           j.title as jobtitle, i.job_id,
           c.name as companyname 
    FROM interviews i
    JOIN jobs j ON i.job_id = j.id
    JOIN companies c ON j.user_id = c.user_id
    WHERE i.user_id = :user_id AND j.is_active = true AND i.is_active = true
    """)

    interviews = db.execute(sql_get_all, {"user_id": user_id}).mappings().all()

    return interviews

@interview_router.get("/hr/job/{job_id}/candidates", response_model=List[HRCandidateResponse], tags=["Interview"])
def get_job_candidates(job_id: int, db: Session = Depends(get_db), hr_user_id: int = Depends(require_hr_role)):
    # Verify the job belongs to this HR
    sql_check_job = text("SELECT id FROM jobs WHERE id = :job_id AND user_id = :hr_user_id")
    job = db.execute(sql_check_job, {"job_id": job_id, "hr_user_id": hr_user_id}).first()
    if not job:
        raise HTTPException(status_code=403, detail="Not authorized or job not found")

    sql_get_candidates = text("""
    SELECT i.id, i.status, i.created_at, i.job_id,
           u.id as candidate_id, u.username as candidate_name
    FROM interviews i
    JOIN users u ON i.user_id = u.id
    WHERE i.job_id = :job_id AND i.is_active = true
    """)

    candidates = db.execute(sql_get_candidates, {"job_id": job_id}).mappings().all()
    return candidates

@interview_router.post("/hr/interview/{interview_id}/reject", response_model=ApplyJobResponse, tags=["Interview"])
def reject_interview(interview_id: int, db: Session = Depends(get_db), hr_user_id: int = Depends(require_hr_role)):
    # Verify HR owns the job for this interview
    sql_check = text("""
        SELECT i.id FROM interviews i
        JOIN jobs j ON i.job_id = j.id
        WHERE i.id = :interview_id AND j.user_id = :hr_user_id
    """)
    auth_check = db.execute(sql_check, {"interview_id": interview_id, "hr_user_id": hr_user_id}).first()
    if not auth_check:
        raise HTTPException(status_code=403, detail="Not authorized or interview not found")

    sql_update = text("UPDATE interviews SET status = :status WHERE id = :interview_id")
    db.execute(sql_update, {"status": ApplyStatusEnum.REJECTED.value, "interview_id": interview_id})
    db.commit()

    return ApplyJobResponse(isSuccess=True)

@interview_router.post("/hr/interview/{interview_id}/interview", response_model=ApplyJobResponse, tags=["Interview"])
def interview_candidate(interview_id: int, db: Session = Depends(get_db), hr_user_id: int = Depends(require_hr_role)):
    # Verify HR owns the job for this interview
    sql_check = text("""
        SELECT i.id FROM interviews i
        JOIN jobs j ON i.job_id = j.id
        WHERE i.id = :interview_id AND j.user_id = :hr_user_id
    """)
    auth_check = db.execute(sql_check, {"interview_id": interview_id, "hr_user_id": hr_user_id}).first()
    if not auth_check:
        raise HTTPException(status_code=403, detail="Not authorized or interview not found")

    sql_update = text("UPDATE interviews SET status = :status WHERE id = :interview_id")
    db.execute(sql_update, {"status": ApplyStatusEnum.INTERVIEW.value, "interview_id": interview_id})
    db.commit()

    return ApplyJobResponse(isSuccess=True)

@interview_router.post("/hr/interview/{interview_id}/end", response_model=ApplyJobResponse, tags=["Interview"])
def end_interview(interview_id: int, db: Session = Depends(get_db), hr_user_id: int = Depends(require_hr_role)):
    # Verify HR owns the job for this interview
    sql_check = text("""
        SELECT i.id FROM interviews i
        JOIN jobs j ON i.job_id = j.id
        WHERE i.id = :interview_id AND j.user_id = :hr_user_id
    """)
    auth_check = db.execute(sql_check, {"interview_id": interview_id, "hr_user_id": hr_user_id}).first()
    if not auth_check:
        raise HTTPException(status_code=403, detail="Not authorized or interview not found")

    sql_update = text("UPDATE interviews SET status = :status WHERE id = :interview_id")
    db.execute(sql_update, {"status": ApplyStatusEnum.VIEWED.value, "interview_id": interview_id})
    db.commit()

    return ApplyJobResponse(isSuccess=True)
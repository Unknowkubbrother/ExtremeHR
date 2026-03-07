from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List

from src.databases.db_connect import get_db
from src.schemas.job_schema import JobListItemResponse, JobDetailResponse, JobCreate, JobUpdate, JobHRResponse
from src.utils.auth_utils import get_current_user_id

def require_hr_role(user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    sql_check_role = text("SELECT role FROM users WHERE id = :id")
    user = db.execute(sql_check_role, {"id": user_id}).first()
    if not user or user.role != "hr":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized. HR role required.")
    return user_id

job_router = APIRouter()

@job_router.get("/", response_model=List[JobListItemResponse], tags=["jobs"])
def get_jobs(filter: str = None, db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    query = """
        SELECT j.id, j.title, COALESCE(c.name, '-') as company, COALESCE(c.location, '-') as location, j."maxSalary" as salary 
        FROM jobs j
        JOIN users u ON j.user_id = u.id
        LEFT JOIN companies c ON u.id = c.user_id
        WHERE j.is_active = true
    """
    params = {}
    if filter and filter != "All":
        query += " AND :filter = ANY(j.job_fields)"
        params["filter"] = filter
        
    sql_get_jobs = text(query)
    results = db.execute(sql_get_jobs, params).fetchall()
    
    jobs_list = [
        {
            "id": row.id,
            "title": row.title,
            "company": row.company,
            "location": row.location,
            "salary": row.salary
        }
        for row in results
    ]
    return jobs_list

@job_router.get("/{job_id}", response_model=JobDetailResponse, tags=["jobs"])
def get_job_detail(job_id: int, db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    sql_get_job = text("""
        SELECT j.*, COALESCE(c.name, '-') as company, COALESCE(c.location, '-') as location 
        FROM jobs j
        JOIN users u ON j.user_id = u.id
        LEFT JOIN companies c ON u.id = c.user_id
        WHERE j.id = :id AND j.is_active = true
    """)
    job = db.execute(sql_get_job, {"id": job_id}).first()
    
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    job_dict = dict(job._mapping)
    
    sql_check_applied = text("SELECT id, status FROM interviews WHERE user_id = :user_id AND job_id = :job_id AND is_active = true")
    applied = db.execute(sql_check_applied, {"user_id": current_user_id, "job_id": job_id}).first()
    
    job_dict["is_applied"] = bool(applied)
    job_dict["application_status"] = applied.status if applied else None

    return job_dict


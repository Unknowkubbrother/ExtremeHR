from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List

from src.databases.db_connect import get_db
from src.schemas.job_schema import JobListItemResponse, JobDetailResponse, JobCreate
from src.utils.auth_utils import get_current_user_id

def require_hr_role(user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    sql_check_role = text("SELECT role FROM users WHERE id = :id")
    user = db.execute(sql_check_role, {"id": user_id}).first()
    if not user or user.role != "hr":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized. HR role required.")
    return user_id

job_router = APIRouter()

@job_router.get("/", response_model=List[JobListItemResponse], tags=["jobs"])
def get_jobs(db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user_id)):
    sql_get_jobs = text("SELECT id, title, company, location, \"maxSalary\" as salary FROM jobs")
    results = db.execute(sql_get_jobs).fetchall()
    
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
    sql_get_job = text("SELECT * FROM jobs WHERE id = :id")
    job = db.execute(sql_get_job, {"id": job_id}).first()
    
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    return dict(job._mapping)

@job_router.post("/", response_model=JobDetailResponse, status_code=status.HTTP_201_CREATED, tags=["jobs"])
def create_job(job_data: JobCreate, db: Session = Depends(get_db), hr_user_id: int = Depends(require_hr_role)):
    sql_insert = text("""
        INSERT INTO jobs (
            title, company, location, description, responsibilities, 
            qualifications, skills, headcount, "minAge", "maxAge", "minSalary", "maxSalary"
        ) 
        VALUES (
            :title, :company, :location, :description, :responsibilities, 
            :qualifications, :skills, :headcount, :minAge, :maxAge, :minSalary, :maxSalary
        ) 
        RETURNING *
    """)
    
    result = db.execute(sql_insert, job_data.model_dump())
    db.commit()
    new_job = result.first()
    
    return dict(new_job._mapping)

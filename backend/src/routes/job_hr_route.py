from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List

from src.databases.db_connect import get_db
from src.schemas.job_schema import JobDetailResponse, JobCreate, JobUpdate, JobHRResponse, JobStats, recentApplyResponse
from src.enums.apply_status_enum import ApplyStatusEnum
from src.utils.auth_utils import get_current_user_id
from src.routes.job_route import require_hr_role
from src.routes.job_route import get_job_detail

job_hr_router = APIRouter()

@job_hr_router.post("/create", response_model=JobDetailResponse, status_code=status.HTTP_201_CREATED, tags=["jobs hr"])
def create_job(job_data: JobCreate, db: Session = Depends(get_db), hr_user_id: int = Depends(require_hr_role)):
    sql_insert = text("""
        INSERT INTO jobs (
            title, description, responsibilities, 
            qualifications, skills, headcount, "minAge", "maxAge", "minSalary", "maxSalary", user_id,job_field
        ) 
        VALUES (
            :title, :description, :responsibilities, 
            :qualifications, :skills, :headcount, :minAge, :maxAge, :minSalary, :maxSalary, :user_id, :job_field
        ) 
        RETURNING id
    """)
    
    params = job_data.model_dump()
    params["user_id"] = hr_user_id
    
    result = db.execute(sql_insert, params)
    job_id = result.fetchone()[0]
    db.commit()
    
    return get_job_detail(job_id, db, hr_user_id)

@job_hr_router.post("/update", response_model=JobDetailResponse, tags=["jobs hr"])
def update_job(job_data: JobUpdate, db: Session = Depends(get_db), hr_user_id: int = Depends(require_hr_role)):
    update_data = job_data.model_dump(exclude_unset=True)
    job_id = update_data.pop("id")
    
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields provided for update")

    set_clauses = []
    for key in update_data.keys():
        # Wrap column names in double quotes to handle case-sensitive (e.g., minAge)
        # and reserved words in PostgreSQL automatically.
        set_clauses.append(f'"{key}" = :{key}')

    sql_update = text(f"""
        UPDATE jobs 
        SET {', '.join(set_clauses)}
        WHERE id = :id AND user_id = :user_id
    """)
    
    params = update_data
    params["id"] = job_id
    params["user_id"] = hr_user_id
    
    result = db.execute(sql_update, params)
    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Job not found or not authorized")
    
    db.commit()
    
    return get_job_detail(job_id, db, hr_user_id)

@job_hr_router.post("/delete/{job_id}", response_model=bool, tags=["jobs hr"])
def delete_job(job_id: int, db: Session = Depends(get_db), hr_user_id: int = Depends(require_hr_role)):
    sql_toggle = text("""
        UPDATE jobs 
        SET is_active = false
        WHERE id = :id AND user_id = :user_id
    """)
    
    result = db.execute(sql_toggle, {"id": job_id, "user_id": hr_user_id})
    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Job not found or not authorized")
    
    db.commit()
    return True

@job_hr_router.get("/hr", response_model=List[JobHRResponse], tags=["jobs hr"])
def get_hr_jobs(db: Session = Depends(get_db), hr_user_id: int = Depends(require_hr_role)):
    sql_get_jobs = text(f"""
        SELECT j.id, j.title, COALESCE(c.name, '-') as company, 
               (SELECT COUNT(i.id) FROM interviews i WHERE i.job_id = j.id AND i.is_active = true) as candidate_count, 
               (SELECT COUNT(i.id) FROM interviews i WHERE i.job_id = j.id AND i.is_active = true AND i.status = '{ApplyStatusEnum.ACCEPTED.value}') as approved_count,
               (SELECT COUNT(i.id) FROM interviews i WHERE i.job_id = j.id AND i.is_active = true AND i.status = '{ApplyStatusEnum.INTERVIEW.value}') as interview_count,
               (SELECT COUNT(i.id) FROM interviews i WHERE i.job_id = j.id AND i.is_active = true AND i.status = '{ApplyStatusEnum.WAITING.value}') as waiting_count,
               j.headcount,
               j."postedAt" 
        FROM jobs j
        JOIN users u ON j.user_id = u.id
        LEFT JOIN companies c ON u.id = c.user_id
        WHERE j.user_id = :hr_user_id AND j.is_active = true
        ORDER BY j."postedAt" DESC
    """)
    results = db.execute(sql_get_jobs, {"hr_user_id": hr_user_id}).fetchall()
    return [dict(row._mapping) for row in results]

@job_hr_router.get("/hr/stats", response_model=JobStats, tags=["jobs hr"])
def get_hr_stats(db: Session = Depends(get_db), hr_user_id: int = Depends(require_hr_role)):
    sql_stats = text(f"""
        SELECT 
            COUNT(DISTINCT j.id) FILTER (WHERE j.is_active = true) as active_jobs,
            COUNT(i.id) FILTER (WHERE i.is_active = true) as interviews,
            COUNT(i.id) FILTER (WHERE i.is_active = true AND i.status = '{ApplyStatusEnum.ACCEPTED.value}') as approved
        FROM jobs j
        LEFT JOIN interviews i ON j.id = i.job_id
        WHERE j.user_id = :hr_user_id
    """)
    stats = db.execute(sql_stats, {"hr_user_id": hr_user_id}).first()
    return JobStats(**stats._mapping)

@job_hr_router.get("/hr/recent", response_model=List[recentApplyResponse], tags=["jobs hr"])
def get_hr_recent_jobs(db: Session = Depends(get_db), hr_user_id: int = Depends(require_hr_role)):
    sql_get_recent = text(f"""
        SELECT i.id, j.title, u.username as candidate_name, i.created_at as date_at 
        FROM interviews i
        JOIN jobs j ON i.job_id = j.id
        JOIN users u ON i.user_id = u.id
        WHERE j.user_id = :hr_user_id AND i.is_active = true
        ORDER BY i.created_at DESC
    """)
    results = db.execute(sql_get_recent, {"hr_user_id": hr_user_id}).fetchall()
    return [dict(row._mapping) for row in results]

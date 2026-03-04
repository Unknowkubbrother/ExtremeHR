from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List

from src.databases.db_connect import get_db
from src.schemas.resume_schema import ResumeCreate, ResumeResponse
from src.utils.auth_utils import get_current_user_id

resume_router = APIRouter()

def require_candidate_role(user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    sql_check_role = text("SELECT role FROM users WHERE id = :id")
    user = db.execute(sql_check_role, {"id": user_id}).first()
    if not user or user.role != "candidate":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized. Candidate role required.")
    return user_id

@resume_router.post("/", response_model=ResumeResponse, status_code=status.HTTP_201_CREATED, tags=["resume"])
def create_or_update_resume(resume_data: ResumeCreate, db: Session = Depends(get_db), user_id: int = Depends(require_candidate_role)):
    # Check if resume already exists
    sql_check_resume = text("SELECT id FROM resumes WHERE user_id = :user_id")
    db_resume = db.execute(sql_check_resume, {"user_id": user_id}).first()
    
    if db_resume:
        resume_id = db_resume.id
        # Update existing resume
        sql_update_resume = text("""
            UPDATE resumes 
            SET full_name = :full_name, age = :age, phone = :phone, 
                email = :email, address = :address, updated_at = NOW()
            WHERE id = :id
        """)
        db.execute(sql_update_resume, {
            "full_name": resume_data.full_name,
            "age": resume_data.age,
            "phone": resume_data.phone,
            "email": resume_data.email,
            "address": resume_data.address,
            "id": resume_id
        })
        
        # Clear existing nested data using text SQL
        db.execute(text("DELETE FROM resume_skills WHERE resume_id = :resume_id"), {"resume_id": resume_id})
        db.execute(text("DELETE FROM resume_education WHERE resume_id = :resume_id"), {"resume_id": resume_id})
        db.execute(text("DELETE FROM resume_experience WHERE resume_id = :resume_id"), {"resume_id": resume_id})
    else:
        # Create new resume
        sql_insert_resume = text("""
            INSERT INTO resumes (user_id, full_name, age, phone, email, address)
            VALUES (:user_id, :full_name, :age, :phone, :email, :address)
            RETURNING id
        """)
        result = db.execute(sql_insert_resume, {
            "user_id": user_id,
            "full_name": resume_data.full_name,
            "age": resume_data.age,
            "phone": resume_data.phone,
            "email": resume_data.email,
            "address": resume_data.address
        })
        resume_id = result.first().id

    # Add nested data using text SQL
    if resume_data.skills:
        sql_insert_skill = text("INSERT INTO resume_skills (resume_id, name) VALUES (:resume_id, :name)")
        for skill in resume_data.skills:
            db.execute(sql_insert_skill, {"resume_id": resume_id, "name": skill.name})
    
    if resume_data.education:
        sql_insert_edu = text("""
            INSERT INTO resume_education (
                resume_id, institution, degree, faculty, major, gpax, 
                start_year, start_month, end_year, end_month
            ) VALUES (
                :resume_id, :institution, :degree, :faculty, :major, :gpax, 
                :start_year, :start_month, :end_year, :end_month
            )
        """)
        for edu in resume_data.education:
            db.execute(sql_insert_edu, {
                "resume_id": resume_id,
                "institution": edu.institution,
                "degree": edu.degree,
                "faculty": edu.faculty,
                "major": edu.major,
                "gpax": edu.gpax,
                "start_year": edu.start_year,
                "start_month": edu.start_month,
                "end_year": edu.end_year,
                "end_month": edu.end_month
            })
        
    if resume_data.experience:
        sql_insert_exp = text("""
            INSERT INTO resume_experience (
                resume_id, company, role, start_year, start_month, 
                end_year, end_month, description
            ) VALUES (
                :resume_id, :company, :role, :start_year, :start_month, 
                :end_year, :end_month, :description
            )
        """)
        for exp in resume_data.experience:
            db.execute(sql_insert_exp, {
                "resume_id": resume_id,
                "company": exp.company,
                "role": exp.role,
                "start_year": exp.start_year,
                "start_month": exp.start_month,
                "end_year": exp.end_year,
                "end_month": exp.end_month,
                "description": exp.description
            })

    db.commit()
    
    # Return the full resume (can re-use get_my_resume logic)
    return get_my_resume(db, user_id)

@resume_router.get("/me", response_model=ResumeResponse, tags=["resume"])
def get_my_resume(db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    sql_get_resume = text("SELECT * FROM resumes WHERE user_id = :user_id")
    resume = db.execute(sql_get_resume, {"user_id": user_id}).first()
    
    if not resume:
        raise HTTPException(status_code=404, detail="Resume not found")
    
    resume_id = resume.id
    
    # Get nested data using text SQL
    skills = db.execute(text("SELECT * FROM resume_skills WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    education = db.execute(text("SELECT * FROM resume_education WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    experience = db.execute(text("SELECT * FROM resume_experience WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    
    # Construct response dictionary
    resume_dict = dict(resume._mapping)
    resume_dict["skills"] = [dict(row._mapping) for row in skills]
    resume_dict["education"] = [dict(row._mapping) for row in education]
    resume_dict["experience"] = [dict(row._mapping) for row in experience]
    
    return resume_dict

@resume_router.get("/candidate/{user_id}", response_model=ResumeResponse, tags=["resume"])
def get_candidate_resume(user_id: int, db: Session = Depends(get_db)):
    sql_get_resume = text("SELECT * FROM resumes WHERE user_id = :user_id")
    resume = db.execute(sql_get_resume, {"user_id": user_id}).first()
    
    if not resume:
        raise HTTPException(status_code=404, detail="Resume not found")
    
    resume_id = resume.id
    
    skills = db.execute(text("SELECT * FROM resume_skills WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    education = db.execute(text("SELECT * FROM resume_education WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    experience = db.execute(text("SELECT * FROM resume_experience WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    
    resume_dict = dict(resume._mapping)
    resume_dict["skills"] = [dict(row._mapping) for row in skills]
    resume_dict["education"] = [dict(row._mapping) for row in education]
    resume_dict["experience"] = [dict(row._mapping) for row in experience]
    
    return resume_dict


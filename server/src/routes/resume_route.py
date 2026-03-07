from fastapi import APIRouter, HTTPException, status, Depends , UploadFile, File
from pathlib import Path
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List
import uuid
import shutil
import asyncio

from src.databases.db_connect import get_db
from src.schemas.resume_schema import ResumeCreate, ResumeResponse , ResumeResult
from src.utils.auth_utils import get_current_user_id
from src.utils.llm_utils import extract_text_from_pdf, model_to_prompt_string , extract_to_json

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
        
        # Clear projects
        db.execute(text("DELETE FROM resume_projects WHERE resume_id = :resume_id"), {"resume_id": resume_id})
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
            
    if resume_data.projects:
        sql_insert_project = text("INSERT INTO resume_projects (resume_id, title, description) VALUES (:resume_id, :title, :description) RETURNING id")
        for project in resume_data.projects:
            db.execute(sql_insert_project, {
                "resume_id": resume_id,
                "title": project.title,
                "description": project.description
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
    
    projects = db.execute(text("SELECT * FROM resume_projects WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    projects_list = [dict(p._mapping) for p in projects]
    
    # Construct response dictionary
    resume_dict = dict(resume._mapping)
    resume_dict["skills"] = [dict(row._mapping) for row in skills]
    resume_dict["education"] = [dict(row._mapping) for row in education]
    resume_dict["experience"] = [dict(row._mapping) for row in experience]
    resume_dict["projects"] = projects_list
    
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
    
    projects = db.execute(text("SELECT * FROM resume_projects WHERE resume_id = :resume_id"), {"resume_id": resume_id}).fetchall()
    projects_list = [dict(p._mapping) for p in projects]
    
    resume_dict = dict(resume._mapping)
    resume_dict["skills"] = [dict(row._mapping) for row in skills]
    resume_dict["education"] = [dict(row._mapping) for row in education]
    resume_dict["experience"] = [dict(row._mapping) for row in experience]
    resume_dict["projects"] = projects_list
    
    return resume_dict



#Extract Resume by LLM

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)


def _process_resume_sync(safe_name: str) -> dict:
    resume_text = extract_text_from_pdf(safe_name.split('.pdf')[0])

    schema_str = model_to_prompt_string(ResumeResult)

    resume_text = resume_text[:25000]

    prompt_template = f"""
Extract precise candidate data from the resume text and return ONLY raw JSON.

# REQUIRED JSON STRUCTURE:
# {schema_str}

# IMPORTANT RULES:
# 1. Output ONLY valid raw JSON.
# 2. Use EXACT field names from the structure.
# 3. `analysis` MUST be written in Thai language only.
# 4. `skills` must be a flat array of strings only.
# 5. Each item in `projects` must contain ONLY:
#    - `title`
#    - `description`

# STRICT CLASSIFICATION RULES:
# 6. `experience` = only formal employment, official internship, assistantship, cooperative education, or long-term role in a real company / institution / organization.
# 7. `projects` = personal projects, freelance-style projects, academic projects, thesis/capstone, experiments, competition systems, side projects, startup ideas, self-initiated builds.
# 8. If an item is a built system/product and NOT clearly a formal paid company job or official internship, put it in `projects`, NOT in `experience`.
# 9. Do NOT duplicate the same item in both `experience` and `projects`.

# MISSING VALUE RULES:
# 10. If age is not explicitly stated, use 0.
# 11. If address is not explicitly stated, use "".
# 12. If any month/year is unknown, use 0.

# ANALYSIS RULE:
# 13. `analysis` should be concise Thai text summarizing the candidate's profile, strengths, and suitability.

# RESUME TEXT:
# {resume_text}
# """

    return extract_to_json(prompt_template)


@resume_router.post("/upload")
async def upload_resume(file: UploadFile = File(...)):
    if file.content_type != "application/pdf":
        raise HTTPException(status_code=400, detail="กรุณาอัปโหลดไฟล์ PDF เท่านั้น")

    safe_name = f"{uuid.uuid4()}_{file.filename}"
    file_path = UPLOAD_DIR / safe_name

    try:
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception:
        raise HTTPException(status_code=500, detail="บันทึกไฟล์ไม่สำเร็จ")
    finally:
        file.file.close()

    result = await asyncio.to_thread(_process_resume_sync, safe_name)

    if not result:
        raise HTTPException(status_code=500, detail="ไม่สามารถสกัดข้อมูลจาก resume ได้")

    return result
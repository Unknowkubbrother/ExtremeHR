from sqlalchemy.orm import Session
from sqlalchemy import text
import json

def get_full_interview_context(db: Session, interview_id: int) -> str:
    """
    Fetches job core details, required skills, and candidate's resume (skills, experience, projects)
    in a single deterministic call instead of multiple individual agent tool invocations.
    Returns a JSON string of the consolidated context.
    """
    try:
        # Job Details
        job_query = text("""
            SELECT j.title, j.description, j.responsibilities, j.qualifications, j.job_fields, j.skills
            FROM interviews i
            JOIN jobs j ON i.job_id = j.id
            WHERE i.id = :id
        """)
        job_row = db.execute(job_query, {"id": interview_id}).first()
        job_data = {
            "title": job_row.title if job_row else "",
            "description": job_row.description if job_row else "",
            "responsibilities": job_row.responsibilities if job_row else [],
            "qualifications": job_row.qualifications if job_row else [],
            "job_fields": job_row.job_fields if job_row else [],
            "skills": job_row.skills if job_row else []
        }

        # Candidate Skills
        skills_query = text("""
            SELECT s.name 
            FROM interviews i
            JOIN users u ON i.user_id = u.id
            JOIN resumes r ON u.id = r.user_id
            JOIN resume_skills s ON r.id = s.resume_id
            WHERE i.id = :id
            ORDER BY s.id DESC
        """)
        skills_rows = db.execute(skills_query, {"id": interview_id}).fetchall()
        candidate_skills = [r.name for r in skills_rows] if skills_rows else []

        # Candidate Experience
        exp_query = text("""
            SELECT e.company, e.role, e.start_year, e.start_month, e.end_year, e.end_month, e.description 
            FROM interviews i
            JOIN users u ON i.user_id = u.id
            JOIN resumes r ON u.id = r.user_id
            JOIN resume_experience e ON r.id = e.resume_id
            WHERE i.id = :id
            ORDER BY e.start_year DESC NULLS LAST, e.start_month DESC NULLS LAST
        """)
        exp_rows = db.execute(exp_query, {"id": interview_id}).fetchall()
        candidate_exp = [{
            "company": r.company,
            "role": r.role,
            "start_year": r.start_year,
            "start_month": r.start_month,
            "end_year": r.end_year,
            "end_month": r.end_month,
            "description": r.description
        } for r in exp_rows] if exp_rows else []

        # Candidate Projects
        proj_query = text("""
            SELECT p.title, p.description 
            FROM interviews i
            JOIN users u ON i.user_id = u.id
            JOIN resumes r ON u.id = r.user_id
            JOIN resume_projects p ON r.id = p.resume_id
            WHERE i.id = :id
            ORDER BY p.id DESC
        """)
        proj_rows = db.execute(proj_query, {"id": interview_id}).fetchall()
        candidate_proj = [{
            "title": r.title,
            "description": r.description
        } for r in proj_rows] if proj_rows else []

        return json.dumps({
            "job": job_data,
            "candidate": {
                "skills": candidate_skills,
                "experience": candidate_exp,
                "projects": candidate_proj
            }
        }, ensure_ascii=False)
        
    except Exception as e:
        db.rollback()
        return json.dumps({"error": f"Failed to get context: {str(e)}"}, ensure_ascii=False)

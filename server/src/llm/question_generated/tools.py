from sqlalchemy.orm import Session
from sqlalchemy import text
from langchain_classic.agents import Tool
import json

def build_tools(db: Session):
    def get_job_core(interview_id_str: str) -> str:
        try:
            interview_id = int(str(interview_id_str).strip())
            query = text("""
                SELECT j.title, j.description, j.responsibilities, j.qualifications, j.job_fields
                FROM interviews i
                JOIN jobs j ON i.job_id = j.id
                WHERE i.id = :id
            """)
            row = db.execute(query, {"id": interview_id}).first()
            if not row:
                return json.dumps({"error": "Interview or job not found"})
            
            return json.dumps({
                "title": row.title,
                "description": row.description,
                "responsibilities": row.responsibilities or [],
                "qualifications": row.qualifications or [],
                "job_fields": row.job_fields or [],
            }, ensure_ascii=False)
        except Exception as e:
            db.rollback()
            return json.dumps({"error": "could not retrieve job core"}, ensure_ascii=False)

    def get_job_skills(interview_id_str: str) -> str:
        try:
            interview_id = int(str(interview_id_str).strip())
            query = text("""
                SELECT j.skills 
                FROM interviews i
                JOIN jobs j ON i.job_id = j.id
                WHERE i.id = :id
            """)
            row = db.execute(query, {"id": interview_id}).first()
            if not row:
                return json.dumps({"error": "Interview or job not found"})

            return json.dumps({
                "skills": row.skills or [],
            }, ensure_ascii=False)
        except Exception as e:
            db.rollback()
            return json.dumps({"skills": []}, ensure_ascii=False)

    def get_resume_skills(interview_id_str: str) -> str:
        try:
            interview_id = int(str(interview_id_str).strip())
            query = text("""
                SELECT s.name 
                FROM interviews i
                JOIN users u ON i.user_id = u.id
                JOIN resumes r ON u.id = r.user_id
                JOIN resume_skills s ON r.id = s.resume_id
                WHERE i.id = :id
            """)
            rows = db.execute(query, {"id": interview_id}).fetchall()
            return json.dumps({
                "skills": [r.name for r in rows] if rows else []
            }, ensure_ascii=False)
        except Exception as e:
            db.rollback()
            return json.dumps({"skills": []}, ensure_ascii=False)

    def get_resume_experience(interview_id_str: str) -> str:
        try:
            interview_id = int(str(interview_id_str).strip())
            query = text("""
                SELECT e.company, e.role, e.start_year, e.start_month, e.end_year, e.end_month, e.description 
                FROM interviews i
                JOIN users u ON i.user_id = u.id
                JOIN resumes r ON u.id = r.user_id
                JOIN resume_experience e ON r.id = e.resume_id
                WHERE i.id = :id
            """)
            rows = db.execute(query, {"id": interview_id}).fetchall()
            
            return json.dumps({
                "experience": [
                    {
                        "company": row.company,
                        "role": row.role,
                        "start_year": row.start_year,
                        "start_month": row.start_month,
                        "end_year": row.end_year,
                        "end_month": row.end_month,
                        "description": row.description,
                    }
                    for row in rows
                ]
            }, ensure_ascii=False)
        except Exception as e:
            db.rollback()
            return json.dumps({"experience": []}, ensure_ascii=False)

    def get_resume_projects(interview_id_str: str) -> str:
        try:
            interview_id = int(str(interview_id_str).strip())
            query = text("""
                SELECT p.title, p.description 
                FROM interviews i
                JOIN users u ON i.user_id = u.id
                JOIN resumes r ON u.id = r.user_id
                JOIN resume_projects p ON r.id = p.resume_id
                WHERE i.id = :id
            """)
            rows = db.execute(query, {"id": interview_id}).fetchall()
            
            return json.dumps({
                "projects": [
                    {
                        "title": row.title,
                        "description": row.description,
                    }
                    for row in rows
                ]
            }, ensure_ascii=False)
        except Exception as e:
            db.rollback()
            return json.dumps({"projects": []}, ensure_ascii=False)

    def get_previous_questions(interview_id_str: str) -> str:
        try:
            interview_id = int(str(interview_id_str).strip())
            query = text("""
                SELECT question, expected_answer
                FROM interview_questions 
                WHERE interview_id = :id
            """)
            rows = db.execute(query, {"id": interview_id}).fetchall()
            
            questions = []
            for row in rows:
                questions.append({
                    "question": row.question,
                    "expected_answer": row.expected_answer,
                })

            return json.dumps({"questions": questions}, ensure_ascii=False)
        except Exception as e:
            db.rollback()
            return json.dumps({"questions": []}, ensure_ascii=False)


    tools = [
        Tool(
            name="GetJobCore",
            func=get_job_core,
            description="Use this tool to get the core job description and responsibilities. Input should be the interview_id as a string."
        ),
        Tool(
            name="GetJobSkills",
            func=get_job_skills,
            description="Use this tool to get the required job skills. Input should be the interview_id as a string."
        ),
        Tool(
            name="GetResumeSkills",
            func=get_resume_skills,
            description="Use this tool to get the candidate's resume skills. Input should be the interview_id as a string."
        ),
        Tool(
            name="GetResumeExperience",
            func=get_resume_experience,
            description="Use this tool to get the candidate's work experience. Input should be the interview_id as a string."
        ),
        Tool(
            name="GetResumeProjects",
            func=get_resume_projects,
            description="Use this tool to get the candidate's projects. Input should be the interview_id as a string."
        ),
        Tool(
            name="GetPreviousQuestions",
            func=get_previous_questions,
            description="Use this tool to get the previously generated or asked interview questions. Input should be the interview_id as a string."
        ),
    ]

    return tools

import json

from langchain_classic.agents import Tool
from sqlalchemy import text
from sqlalchemy.orm import Session


def build_tools(db: Session):
    def get_interview_core(interview_id_str: str) -> str:
        try:
            interview_id = int(str(interview_id_str).strip())
            query = text("""
                SELECT
                    i.context,
                    i.candidate_profile_summary,
                    i.job_profile_summary,
                    i.candidate_strengths,
                    i.candidate_gaps,
                    i.hr_interest,
                    i.difficulty
                FROM interviews i
                WHERE i.id = :id
            """)
            row = db.execute(query, {"id": interview_id}).first()
            if not row:
                return json.dumps({"error": "Interview not found"}, ensure_ascii=False)

            return json.dumps(
                {
                    "context": row.context,
                    "candidate_profile_summary": row.candidate_profile_summary,
                    "job_profile_summary": row.job_profile_summary,
                    "candidate_strengths": row.candidate_strengths,
                    "candidate_gaps": row.candidate_gaps,
                    "hr_interest": row.hr_interest,
                    "difficulty": row.difficulty,
                },
                ensure_ascii=False,
            )
        except Exception:
            db.rollback()
            return json.dumps(
                {"error": "could not retrieve interview core"},
                ensure_ascii=False,
            )

    def get_interview_questions(interview_id_str: str) -> str:
        try:
            interview_id = int(str(interview_id_str).strip())
            query = text("""
                SELECT
                    iq.question,
                    iq.expected_answer,
                    iq.user_answer,
                    iq.score,
                    iq.reason
                FROM interview_questions iq
                WHERE iq.interview_id = :id
                ORDER BY iq.id ASC
            """)
            rows = db.execute(query, {"id": interview_id}).fetchall()
            return json.dumps(
                {
                    "questions": [
                        {
                            "question": row.question,
                            "expected_answer": row.expected_answer,
                            "user_answer": row.user_answer,
                            "score": row.score,
                            "reason": row.reason,
                        }
                        for row in rows
                    ]
                },
                ensure_ascii=False,
            )
        except Exception:
            db.rollback()
            return json.dumps({"questions": []}, ensure_ascii=False)

    def get_chat_history(interview_id_str: str) -> str:
        try:
            interview_id = int(str(interview_id_str).strip())
            query = text("""
                SELECT
                    ch.user_id AS sender_id,
                    u.username AS sender_name,
                    CASE
                        WHEN ch.message LIKE '[AI] %' THEN 'ai'
                        ELSE u.role
                    END AS sender_role,
                    ch.message,
                    ch.created_at
                FROM chat_histories ch
                JOIN users u ON u.id = ch.user_id
                WHERE ch.interview_id = :id
                ORDER BY ch.created_at ASC, ch.id ASC
            """)
            rows = db.execute(query, {"id": interview_id}).fetchall()
            return json.dumps(
                {
                    "chat_history": [
                        {
                            "sender_id": row.sender_id,
                            "sender_name": row.sender_name,
                            "sender_role": row.sender_role,
                            "message": row.message,
                            "created_at": row.created_at.isoformat()
                            if row.created_at is not None
                            else None,
                        }
                        for row in rows
                    ]
                },
                ensure_ascii=False,
            )
        except Exception:
            db.rollback()
            return json.dumps({"chat_history": []}, ensure_ascii=False)

    return [
        Tool(
            name="GetInterviewCore",
            func=get_interview_core,
            description=(
                "Use this tool to get the core interview context. "
                "Input should be the interview_id as a string."
            ),
        ),
        Tool(
            name="GetInterviewQuestions",
            func=get_interview_questions,
            description=(
                "Use this tool to get the interview questions, candidate answers, "
                "and evaluation details. Input should be the interview_id as a string."
            ),
        ),
        Tool(
            name="GetChatHistory",
            func=get_chat_history,
            description=(
                "Use this tool to get the ordered chat transcript for the interview. "
                "Input should be the interview_id as a string."
            ),
        ),
    ]

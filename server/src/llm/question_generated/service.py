from sqlalchemy.orm import Session
from sqlalchemy import text
from src.llm.question_generated.agent import build_agent, extract_json_text, QuestionCandidates
from src.llm.question_generated.tools import build_tools
import json

def get_recent_messages(db: Session, interview_id: int, limit: int = 5) -> str:
    # Temporarily returning 'No recent messages' until a messages table is implemented.
    return "No recent messages."

def build_baseline_context(db: Session, interview_id: int) -> str:
    query = text("""
        SELECT i.context, i.candidate_profile_summary, i.job_profile_summary,
               i.candidate_strengths, i.candidate_gaps, i.hr_interest
        FROM interviews i
        WHERE i.id = :id
    """)
    row = db.execute(query, {"id": interview_id}).first()
    if not row:
        return "Interview not found."

    difficulty_text = "Not set"

    return f"""
ROOM CONTEXT:
{row.context or "No room context."}

HR INTERESTING (Use as weight for questions):
{row.hr_interest or "No specific HR interests noted."}

CANDIDATE PROFILE SUMMARY:
{row.candidate_profile_summary or "No candidate profile summary."}

JOB PROFILE SUMMARY:
{row.job_profile_summary or "No job profile summary."}

CANDIDATE STRENGTHS:
{row.candidate_strengths or "No strengths identified yet."}

CANDIDATE GAPS:
{row.candidate_gaps or "No gaps identified yet."}

RECENT MESSAGES:
{get_recent_messages(db, interview_id)}
""".strip()

def generate_interview_questions(
    db: Session,
    interview_id: int,
    hr_prompt: str,
):
    query = text("SELECT id FROM interviews WHERE id = :id")
    if not db.execute(query, {"id": interview_id}).first():
        raise ValueError("Interview not found")

    baseline_context = build_baseline_context(db, interview_id)
    tools = build_tools(db)
    agent = build_agent(tools)

    schema_json = {
        "questions": [
            {
                "interview_question": "String",
                "expected_answer": ["String", "String", "String"],
                "competency": "String",
                "difficulty": "easy | medium | hard",
                "why_this_question": "String"
            }
        ]
    }

    prompt = f"""
You are an interview question generator.

NON-NEGOTIABLE RULE:
The HR REQUEST overrides all other context.
If any candidate/job/context information conflicts with or distracts from the HR REQUEST, ignore it.

CONTEXT INFORMATION:
{baseline_context}

HR REQUEST:
{hr_prompt}

TASK:
Generate exactly 2-3 interview questions that satisfy the HR REQUEST.

RULES:
- Every question must clearly reflect the HR REQUEST.
- Do not generate unrelated questions.
- Use candidate/job information only as supporting evidence.
- Use the provided tools by passing the interview_id "{interview_id}" as a string to gather necessary background if needed.
- expected_answer must contain exactly 3 distinct points.
- Output language must match the HR REQUEST.
- Output ONLY valid JSON.

JSON STRUCTURE:
{json.dumps(schema_json, indent=2, ensure_ascii=False)}
"""

    result = agent.run(prompt)
    
    json_str = extract_json_text(result)
    parsed_data = json.loads(json_str)
    
    return QuestionCandidates.model_validate(parsed_data)

def save_generated_questions(
    db: Session,
    interview_id: int,
    question_candidates,
):

    sql_insert = text("""
        INSERT INTO interview_questions (
            interview_id,
            question,
            expected_answer,
            user_answer,
            score,
            reason
        )
        VALUES (
            :interview_id,
            :question,
            :expected_answer,
            :user_answer,
            :score,
            :reason
        )
    """)

    for q in question_candidates.questions:

        db.execute(
            sql_insert,
            {
                "interview_id": interview_id,
                "question": q.interview_question,
                "expected_answer": q.expected_answer,   # ต้องเป็น list ถ้า column เป็น ARRAY(String)
                "user_answer": None,
                "score": None,
                "reason": None,
            },
        )

    db.commit()

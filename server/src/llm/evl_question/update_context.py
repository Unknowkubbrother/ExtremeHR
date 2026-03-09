from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session
from langchain_core.prompts import ChatPromptTemplate
from src.llm.question_generated.agent import get_llm


class InterviewContextUpdateResult(BaseModel):
    candidate_strengths: str
    candidate_gaps: str
    context: str
    difficulty: float = Field(..., ge=0.0, le=1.0)

update_context_prompt = ChatPromptTemplate.from_template("""
You are an interview reflection updater.

Your task is to extract newly observed strengths and gaps from the latest evaluated answer, and update the running interview context while preserving important prior context.

RULES:
- Focus on the latest QUESTION, EXPECTED ANSWER, CANDIDATE ANSWER, SCORE, and REASON.
- CURRENT CONTEXT is important and must be treated as the existing running interview state.
- Do not discard important information already present in CURRENT CONTEXT.
- Update the context incrementally: preserve what is still valid, refine what is newly clarified, and add only what is supported by the latest evaluated answer.
- If the latest answer adds little or no meaningful new information, keep the context close to the previous version.
- candidate_strengths must be a single string containing only newly observed strengths clearly demonstrated in this answer.
- candidate_gaps must be a single string containing only newly observed gaps clearly supported by this answer or its evaluation.
- If no clear new strength is supported by the answer, return candidate_strengths as an empty string.
- If no clear new gap is supported by the answer, return candidate_gaps as an empty string.
- Do not invent strengths that are not clearly demonstrated.
- Do not invent gaps that are not clearly supported.
- Do not guess.
- Keep candidate_strengths and candidate_gaps short, specific, and directly usable for appending into a database field.
- context must be a revised running interview summary based on the previous context plus the latest evaluated answer.
- Keep context short, practical, and useful for future question generation.
- difficulty must be a float between 0.0 and 1.0.
- Use CURRENT DIFFICULTY as the baseline and adjust only slightly based on the latest answer.
- If performance is strong, difficulty may increase slightly.
- If performance is weak, difficulty may decrease slightly.
- Do not make large difficulty jumps from a single answer.
- The language of all text fields must follow the language of QUESTION.
- Return JSON only. Do not include markdown or extra text.

CURRENT CONTEXT:
{context}

CURRENT DIFFICULTY:
{difficulty}

LATEST EVALUATED QUESTION:
QUESTION:
{question}

EXPECTED ANSWER:
{expected_answer}

CANDIDATE ANSWER:
{user_answer}

SCORE:
{score}

REASON:
{reason}

TASK:
Return exactly one JSON object following this schema:
{{
  "candidate_strengths": "string",
  "candidate_gaps": "string",
  "context": "string",
  "difficulty": 0.5
}}
""")


def build_update_context_chain():
    llm = get_llm(temperature=0.2).with_structured_output(InterviewContextUpdateResult, method="json_mode")
    return update_context_prompt | llm


def get_question_and_interview_context(db: Session, question_id: int):
    query = text("""
        SELECT
            iq.id AS question_id,
            iq.interview_id,
            iq.question,
            iq.expected_answer,
            iq.user_answer,
            iq.score,
            iq.reason,
            i.candidate_strengths,
            i.candidate_gaps,
            i.hr_interest,
            i.context,
            i.difficulty
        FROM interview_questions iq
        JOIN interviews i ON iq.interview_id = i.id
        WHERE iq.id = :question_id
    """)
    return db.execute(query, {"question_id": question_id}).mappings().first()


def save_interview_context_update(
    db: Session,
    interview_id: int,
    candidate_strengths: str,
    candidate_gaps: str,
    context: str,
    difficulty: float,
):
    query = text("""
        UPDATE interviews
        SET candidate_strengths = 
                CASE 
                    WHEN candidate_strengths IS NULL OR candidate_strengths = '' 
                    THEN :candidate_strengths
                    ELSE candidate_strengths || ', ' || :candidate_strengths
                END,
            candidate_gaps = 
                CASE 
                    WHEN candidate_gaps IS NULL OR candidate_gaps = '' 
                    THEN :candidate_gaps
                    ELSE candidate_gaps || ', ' || :candidate_gaps
                END,
            context = :context,
            difficulty = :difficulty,
            updated_at = now()
        WHERE id = :interview_id
    """)

    db.execute(query, {
        "interview_id": interview_id,
        "candidate_strengths": candidate_strengths.strip(),
        "candidate_gaps": candidate_gaps.strip(),
        "context": context.strip(),
        "difficulty": difficulty,
    })
    db.commit()


def update_question_context(db: Session, question_id: int):
    row = get_question_and_interview_context(db, question_id)
    if not row:
        raise ValueError("Question or interview not found")

    chain = build_update_context_chain()

    result = chain.invoke({
        "context": row["context"] or "No context yet.",
        "difficulty": row["difficulty"] if row["difficulty"] is not None else 0.5,
        "question": row["question"],
        "expected_answer": row["expected_answer"] or [],
        "user_answer": row["user_answer"] or "",
        "score": float(row["score"]) if row["score"] is not None else 0.0,
        "reason": row["reason"] or "",
    })

    difficulty = max(0.0, min(1.0, float(result.difficulty)))

    save_interview_context_update(
        db=db,
        interview_id=row["interview_id"],
        candidate_strengths=result.candidate_strengths,
        candidate_gaps=result.candidate_gaps,
        context=result.context,
        difficulty=difficulty,
    )

    print(result)

    return {
        "interview_id": row["interview_id"],
        "candidate_strengths": result.candidate_strengths,
        "candidate_gaps": result.candidate_gaps,
        "context": result.context,
        "difficulty": difficulty,
    }
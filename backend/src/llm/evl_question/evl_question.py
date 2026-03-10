from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session
from langchain_core.prompts import ChatPromptTemplate
from src.llm.question_generated.agent import get_llm
from src.llm.evl_question.update_context import update_question_context


class QuestionEvaluationResult(BaseModel):
    score: float = Field(..., ge=0.0, le=1.0)
    reason: str

evaluation_prompt = ChatPromptTemplate.from_template("""
You are an interview answer evaluator.

Evaluate the candidate's answer for ONE interview question.

SCORING RULES:
- score must be between 0.0 and 1.0
- 1.0 = complete, accurate, specific, and clearly aligned with what a strong answer should contain
- 0.7 = mostly correct but missing some depth, specificity, or important supporting detail
- 0.4 = partially correct but vague, incomplete, generic, or weakly supported
- 0.0 = incorrect, irrelevant, evasive, or empty

IMPORTANT:
- Use EXPECTED ANSWER as the main rubric.
- EXPECTED ANSWER may contain one or more example good answers, not a strict checklist.
- The candidate does NOT need to match the exact examples, exact wording, or exact project names in EXPECTED ANSWER.
- Evaluate whether the candidate answer demonstrates the same quality, depth, specificity, and reasoning as a strong answer would.
- Reward specificity, correctness, concrete evidence, clear reasoning, and relevance to the question.
- Penalize vague, generic, unsupported, or off-topic answers.
- Keep reason short and concrete.
- The language of reason must follow the language of QUESTION.
- Focus mainly on the QUESTION and the underlying qualities shown in EXPECTED ANSWER, not exact textual overlap.

QUESTION:
{question}

EXPECTED ANSWER:
{expected_answer}

CANDIDATE ANSWER:
{user_answer}

TASK:
Return exactly one JSON object following this schema:
{{
  "score": 0.0,
  "reason": "String in the language of the question"
}}
""")


def build_evaluation_chain():
    llm = get_llm(temperature=0.1).with_structured_output(QuestionEvaluationResult, method="json_mode")
    chain = evaluation_prompt | llm
    return chain


def get_question_for_evaluation(db: Session, question_id: int):
    query = text("""
        SELECT
            id,
            question,
            expected_answer
        FROM interview_questions
        WHERE id = :question_id
    """)
    return db.execute(query, {"question_id": question_id}).mappings().first()


def save_question_evaluation(
    db: Session,
    question_id: int,
    user_answer: str,
    score: float,
    reason: str,
):
    query = text("""
        UPDATE interview_questions
        SET user_answer = :user_answer,
            score = :score,
            reason = :reason
        WHERE id = :question_id
    """)
    db.execute(query, {
        "question_id": question_id,
        "user_answer": user_answer.strip(),
        "score": score,
        "reason": reason.strip(),
    })
    db.commit()


def evaluate_llm_answer(db: Session, question_id: int, user_answer: str):
    if not user_answer or not user_answer.strip():
        raise ValueError("user_answer is empty")

    row = get_question_for_evaluation(db, question_id)
    if not row:
        raise ValueError("Question not found")

    chain = build_evaluation_chain()

    result = chain.invoke({
        "question": row["question"],
        "expected_answer": row["expected_answer"] or [],
        "user_answer": user_answer.strip(),
    })

    score = float(result.score)
    reason = result.reason.strip()

    save_question_evaluation(
        db=db,
        question_id=question_id,
        user_answer=user_answer,
        score=score,
        reason=reason,
    )

    update_question_context(db, question_id)

    return {
        "question_id": question_id,
        "score": score,
        "reason": reason,
    }
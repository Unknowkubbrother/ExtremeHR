from sqlalchemy.orm import Session
from sqlalchemy import text
from src.llm.question_generated.agent import QuestionCandidates, get_llm
from src.llm.question_generated.tools import get_full_interview_context
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_community.callbacks.manager import get_openai_callback
import json

def get_recent_messages(db: Session, interview_id: int, limit: int = 5) -> str:
    query = text("""
        SELECT message 
        FROM chat_histories 
        WHERE interview_id = :id 
        ORDER BY created_at DESC 
        LIMIT :limit
    """)
    rows = db.execute(query, {"id": interview_id, "limit": limit}).fetchall()
    if not rows:
        return "No recent messages."
    
    # Reverse to show in chronological order
    messages = [r.message for r in reversed(rows) if not r.message.startswith("[AI]")]
    return "\n".join(messages)

def summarize_hr_style(db: Session, interview_id: int, new_prompt: str) -> str:

    query = text("SELECT hr_interest FROM interviews WHERE id = :id")
    row = db.execute(query, {"id": interview_id}).first()
    old_profile = row.hr_interest if row else ""

    llm = get_llm(temperature=0.2)

    prompt = ChatPromptTemplate.from_messages([
        ("system", """
You are an HR profile updater.

Strict rules:
- Never invent information
- Follow the rules exactly
- Return only the updated HR profile text
"""),

        ("human", """
New HR Request (PRIMARY SOURCE OF TRUTH):
{new_prompt}

Current HR Profile (Context Only – may be outdated):
{old_profile}

TASK:
Update the HR Profile using the New HR Request as the primary source.

RULES:
1. The New HR Request has higher priority than the Current HR Profile.
2. Remove any topic explicitly excluded in the New HR Request.
3. Only keep information from the Current HR Profile if it does NOT conflict.
4. If the New Request changes the focus, discard outdated instructions.
5. If the New Request says "clear", "reset", or "start over", ignore the old profile.
6. Keep the profile concise (MAX 3 sentences).
7. Each sentence must be under 25 words.
8. Do NOT invent roles, industries, technologies, or skills not mentioned.
9. NEVER introduce new concepts not present in the New HR Request.
10. Prefer the NEW request over preserving old details.
""")
    ])

    chain = prompt | llm | StrOutputParser()

    response = chain.invoke({
        "new_prompt": new_prompt,
        "old_profile": old_profile or "None"
    })

    summary = response.strip()

    update_query = text("UPDATE interviews SET hr_interest = :summary WHERE id = :id")
    db.execute(update_query, {"summary": summary, "id": interview_id})
    db.commit()

    return summary

def map_difficulty(score: float) -> str:
    if score < 0.3:
        return "easy"
    elif score < 0.7:
        return "medium"
    return "hard"

def build_baseline_context(db: Session, interview_id: int) -> dict:
    query = text("""
        SELECT i.context, i.candidate_profile_summary, i.job_profile_summary,
               i.candidate_strengths, i.candidate_gaps, i.hr_interest, i.difficulty
        FROM interviews i
        WHERE i.id = :id
    """)
    row = db.execute(query, {"id": interview_id}).first()
    if not row:
        return {}

    diff_score = float(row.difficulty) if row.difficulty is not None else 0.5

    return {
        "context": row.context or "No room context.",
        "difficulty_score": diff_score,
        "difficulty_label": map_difficulty(diff_score),
        "hr_interest": row.hr_interest or "No specific HR interests noted.",
        "strengths": row.candidate_strengths or "No strengths identified yet.",
        "gaps": row.candidate_gaps or "No gaps identified yet.",
    }

def generate_interview_questions(
    db: Session,
    interview_id: int,
    hr_prompt: str,
):
    query = text("SELECT id FROM interviews WHERE id = :id")
    if not db.execute(query, {"id": interview_id}).first():
        raise ValueError("Interview not found")

    # 1) Build baseline memory context
    baseline = build_baseline_context(db, interview_id)
    recent_messages = get_recent_messages(db, interview_id)
    
    # 2) Update HR interest profile (Memory)
    hr_profile = summarize_hr_style(db, interview_id, hr_prompt)
    print("HR PROFILE:", hr_profile)
    
    # 3) Setup Deterministic Context (TOOL FETCH) BEFORE LLM calls
    deterministic_context = get_full_interview_context(db, interview_id)
    
    # 4) Fetch previous questions specifically to prevent repetition
    prev_q_query = text("""
        SELECT question FROM interview_questions 
        WHERE interview_id = :id 
        ORDER BY id DESC LIMIT 5
    """)
    prev_q_rows = db.execute(prev_q_query, {"id": interview_id}).fetchall()
    prev_questions_str = "\n".join([f"- {r.question}" for r in prev_q_rows]) if prev_q_rows else "No previous questions."

    # 5) Setup the LLM with Robust JSON Parsing
    from langchain_core.output_parsers import JsonOutputParser
    parser = JsonOutputParser(pydantic_object=QuestionCandidates)
    
    llm = get_llm(temperature=0.2)
    # Note: Explicitly avoid with_structured_output if the backend is unstable
    # Using JsonOutputParser is generally more robust for varied LLM providers
    
    # 6) Generate Questions directly
    current_prompt = f"""
You are an expert technical and HR interview question generator.

### PRIMARY INSTRUCTION
You MUST generate EXACTLY 2-3 interview questions strictly following this HR PROMPT:
"{hr_prompt}"

If any context, candidate information, or historical profile conflicts with the HR PROMPT, the HR PROMPT takes absolute precedence.

### CONTEXT DATA (DO NOT HALLUCINATE, USE THIS REAL DATA)
{deterministic_context}

### INTERVIEW STATUS
Room Context: {baseline.get('context')}
Interview Difficulty Requirement: {baseline.get('difficulty_score')} ({baseline.get('difficulty_label')})
Target Difficulty: {baseline.get('difficulty_label')}.

### HR PROFILE (Historical Style)
{hr_profile}

### PREVIOUSLY ASKED QUESTIONS (DO NOT REPEAT)
{prev_questions_str}

### RECENT MESSAGES
{recent_messages}

### OUTPUT FORMAT INSTRUCTIONS
{parser.get_format_instructions()}

### RULES
- Output must be valid JSON following the schema above.
- The language of your output MUST MATCH the EXACT language of the HR PROMPT.
- difficulty MUST match '{baseline.get('difficulty_label')}'.
"""

    print(f"\n========== LLM PROMPT ==========\n{current_prompt}\n======================================================\n")
    try:
        chain = llm | parser
        with get_openai_callback() as cb:
            result_dict = chain.invoke(current_prompt)
        print(f"\n+++ TOKEN USAGE +++\n{cb}\n+++++++++++++++++++\n")
        
        # result_dict is already a dict, convert to Pydantic if needed
        return QuestionCandidates(**result_dict)
    except Exception as e:
        print(f"--- FAILURE generating questions via structured output ---")
        print(f"EXCEPTION TYPE: {type(e).__name__}")
        print(f"EXCEPTION DETAIL: {str(e)}")
        raise e

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
        RETURNING id
    """)

    for q in question_candidates.questions:
        inserted_row = db.execute(
            sql_insert,
            {
                "interview_id": interview_id,
                "question": q.interview_question,
                "expected_answer": q.expected_answer,
                "user_answer": None,
                "score": None,
                "reason": None,
            },
        ).first()
        q.id = inserted_row.id if inserted_row else None

    db.commit()
    return question_candidates

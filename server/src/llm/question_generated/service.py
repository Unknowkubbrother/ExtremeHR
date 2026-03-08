from sqlalchemy.orm import Session
from sqlalchemy import text
from src.llm.question_generated.agent import build_agent, extract_json_text, QuestionCandidates, get_llm
from src.llm.question_generated.tools import build_tools
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
    messages = [r.message for r in reversed(rows)]
    return "\n".join(messages)

def summarize_hr_style(db: Session, interview_id: int, new_prompt: str) -> str:
    # 1) Get existing interest (This acts as the persistent memory)
    query = text("SELECT hr_interest FROM interviews WHERE id = :id")
    row = db.execute(query, {"id": interview_id}).first()
    old_profile = row.hr_interest if row else ""

    # 2) Use LLM to merge instructions efficiently (Direct call, no agent)
    llm = get_llm(temperature=0.2)
    
    # We provide a structured merging prompt
    summary_prompt = f"""
Current HR Profile (Existing Instructions):
{old_profile or "No existing instructions."}

New HR Request:
{new_prompt}

TASK:
You are an expert HR Profiler. Merge the 'New HR Request' into the 'Current HR Profile'.
RULES:
1. Keep the profile concise (MAX 4-5 sentences).
2. The New HR Request overrides or adds to existing instructions.
3. If the New Request asks to 'clear', 'reset', or 'start over', discard the old profile and start fresh.
4. The profile should specify:
   - What skills/topics to focus on.
   - Any specific evaluation criteria or tone.
   - Any constraints (e.g., 'don't ask about X').
5. Output ONLY the updated technical/stylistic profile text.
"""
    # Direct call to LLM
    response = llm.invoke(summary_prompt)
    summary = response.content.strip()

    # 3) Save back to DB (Persistent Memory)
    update_query = text("UPDATE interviews SET hr_interest = :summary WHERE id = :id")
    db.execute(update_query, {"summary": summary, "id": interview_id})
    db.commit()
    
    return summary

def build_baseline_context(db: Session, interview_id: int) -> str:
    query = text("""
        SELECT i.context, i.candidate_profile_summary, i.job_profile_summary,
               i.candidate_strengths, i.candidate_gaps, i.hr_interest, i.difficulty
        FROM interviews i
        WHERE i.id = :id
    """)
    row = db.execute(query, {"id": interview_id}).first()
    if not row:
        return "Interview not found."

    return f"""
ROOM CONTEXT:
{row.context or "No room context."}

INTERVIEW DIFFICULTY (0.0=Entry, 0.5=Mid, 1.0=Expert):
{row.difficulty if row.difficulty is not None else 0.5}

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

    # 1) Build baseline context
    baseline_context = build_baseline_context(db, interview_id)
    
    # 2) Update HR interest profile (Memory)
    hr_profile = summarize_hr_style(db, interview_id, hr_prompt)
    
    # 3) Fetch previous questions specifically to prevent repetition in Agent Memory
    prev_q_query = text("""
        SELECT question FROM interview_questions 
        WHERE interview_id = :id 
        ORDER BY id DESC LIMIT 3
    """)
    prev_q_rows = db.execute(prev_q_query, {"id": interview_id}).fetchall()
    
    formatted_history = []
    # We add them as 'assistant' messages because these were the LLM's previous outputs
    for r in reversed(prev_q_rows):
        formatted_history.append({"role": "assistant", "content": f"Previously generated question: {r.question}"})

    tools = build_tools(db)
    
    # 4) Generate Questions
    current_prompt = f"""
You are an interview question generator.

NON-NEGOTIABLE RULE:
The HR REQUEST overrides all other context.
If any candidate/job/context information conflicts with or distracts from the HR REQUEST, ignore it.

CONTEXT INFORMATION:
{baseline_context}

HR PROFILE (Historical Style / Instructions):
{hr_profile}

CURRENT HR REQUEST:
{hr_prompt}

TASK:
Generate exactly 2-3 interview questions that satisfy the HR REQUEST while following the global HR PROFILE.
Check your chat history to avoid repeating questions you have already asked.

RULES:
- Every question must clearly reflect the HR REQUEST.
- Do not generate unrelated questions.
- Use candidate/job information only as supporting evidence.
- Use the provided tools by passing the interview_id "{interview_id}" as a string to gather necessary background if needed.
- expected_answer must contain exactly 3 distinct points.
- Output language must match the HR REQUEST.
- Output ONLY valid JSON.

JSON STRUCTURE:
{{
  "questions": [
    {{
      "interview_question": "String",
      "expected_answer": ["Point 1", "Point 2", "Point 3"],
      "competency": "String",
      "difficulty": "easy | medium | hard",
      "why_this_question": "String"
    }}
  ]
}}
"""

    # We pass the history of previous questions so the memory is "active"
    agent = build_agent(tools, chat_history=formatted_history)
    
    result = agent.run(current_prompt)
    
    json_str = extract_json_text(result)
    parsed_data = json.loads(json_str)

    if isinstance(parsed_data, list):
        parsed_data = {"questions": parsed_data}

    # This will raise ValidationError if JSON is incomplete
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

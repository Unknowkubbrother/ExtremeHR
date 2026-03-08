from sqlalchemy.orm import Session
from sqlalchemy import text
from src.llm.question_generated.agent import build_agent, extract_json_text, QuestionCandidates, get_llm
from src.llm.question_generated.tools import build_tools
import json

def get_recent_questions_text(history: list) -> str:
    if not history:
        return "No previous questions in this session."
    return "\n".join([msg["content"] for msg in history if msg["role"] == "assistant"])

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
Current HR Profile (Context Only):
{old_profile or "None"}

New HR Request (Highest Priority):
{new_prompt}

TASK:
Update the HR Profile using the New HR Request as the PRIMARY source of truth.

RULES:
1. The New HR Request has higher priority than the Current HR Profile.
2. Only keep information from the Current HR Profile if it does NOT conflict with the New HR Request.
3. If the New Request changes the focus, discard outdated instructions from the old profile.
4. If the New Request asks to 'clear', 'reset', or 'start over', ignore the old profile completely.
5. Keep the profile concise (MAX 3 sentences).
6. Do NOT invent roles, industries, or skills that are not mentioned.
7. If the New HR Request is vague, keep the profile generic.
8. Prefer the NEW request over preserving old details.

OUTPUT:
Return ONLY the updated HR Profile text.
Each sentence must be under 15 words.
"""
    # Direct call to LLM
    response = llm.invoke(summary_prompt)
    summary = response.content.strip()

    print(summary)

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

PRIMARY INSTRUCTION (HIGHEST PRIORITY):
The CURRENT HR REQUEST is the main objective.
All generated questions MUST directly satisfy the HR REQUEST.

If any context, candidate information, or historical profile conflicts with the HR REQUEST, IGNORE it.

CONTEXT INFORMATION (LOW PRIORITY):
{baseline_context}

HR PROFILE (Historical Style – OPTIONAL):
{hr_profile}

CURRENT HR REQUEST (PRIMARY TASK):
{hr_prompt}

TASK:
Generate exactly 2–3 interview questions that directly satisfy the CURRENT HR REQUEST.

REASONING PROCESS:
1. Understand the HR REQUEST.
2. Ignore unrelated context.
3. Generate questions aligned ONLY with the HR REQUEST.

RULES:
- Questions must clearly reflect the HR REQUEST.
- Do not introduce unrelated roles, skills, or industries.
- Avoid repeating previous questions.
- expected_answer must contain exactly 3 distinct points.
- Output language must match the HR REQUEST.
- Use the provided tools by passing the interview_id "{interview_id}" as a string when additional context is required.

OUTPUT FORMAT:
Return ONLY a valid JSON object.

{{
  "questions": [
    {{
      "interview_question": "String",
      "expected_answer": ["Point 1", "Point 2", "Point 3"],
      "competency": "String",
      "difficulty": "easy | medium | hard",
      "why_this_question": "Explain how it matches the HR REQUEST"
    }}
  ]
}}
"""

    # We pass the history of previous questions so the memory is "active"
    agent = build_agent(tools) # No longer passing chat_history here
    
    try:
        result = agent.run(current_prompt)
        
        json_str = extract_json_text(result)
        parsed_data = json.loads(json_str)

        if isinstance(parsed_data, list):
            parsed_data = {"questions": parsed_data}

        # This will raise ValidationError if JSON is incomplete
        return QuestionCandidates.model_validate(parsed_data)
    except Exception as e:
        print("--- RAW LLM OUTPUT START ---")
        try:
            print(result) # Show what we got if result was assigned
        except NameError:
            print("No result obtained from agent.")
        print("--- RAW LLM OUTPUT END ---")
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

from sqlalchemy.orm import Session
from sqlalchemy import text
from src.llm.question_generated.agent import build_agent, extract_json_text, QuestionCandidates, get_llm
from src.llm.question_generated.tools import build_tools
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
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

    print("HR PROFILE:", hr_profile)
    
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

DEFAULT LANGUAGE:
All questions and explanations MUST be written in Thai unless the HR REQUEST is explicitly English.

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

    # 4) Generate Questions (with Retry Logic)
    agent = build_agent(tools)
    max_retries = 2
    attempt = 0
    feedback_msg = ""
    
    while attempt <= max_retries:
        combined_prompt = current_prompt
        if attempt > 0:
            combined_prompt += f"\n\nERROR FROM PREVIOUS ATTEMPT:\n{feedback_msg}\n\nPlease fix the JSON and return the corrected version."

        try:
            result = agent.invoke({
                "input": combined_prompt,
                "chat_history": []
            })
            json_str = extract_json_text(result["output"])
            parsed_data = json.loads(json_str, strict=False)

            if isinstance(parsed_data, list):
                parsed_data = {"questions": parsed_data}

            # This will raise ValidationError if JSON is incomplete
            return QuestionCandidates.model_validate(parsed_data)
            
        except Exception as e:
            attempt += 1
            feedback_msg = f"Error parsing JSON: {str(e)}\nRaw Output: {result if 'result' in locals() else 'No result'}"
            print(f"--- Attempt {attempt} failed ---")
            print(feedback_msg)
            if attempt > max_retries:
                print("--- FINAL FAILURE ---")
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
                "expected_answer": q.expected_answer,   # ต้องเป็น list ถ้า column เป็น ARRAY(String)
                "user_answer": None,
                "score": None,
                "reason": None,
            },
        ).first()
        q.id = inserted_row.id if inserted_row else None

    db.commit()
    return question_candidates

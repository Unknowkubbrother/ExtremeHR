import json
from sqlalchemy.orm import Session
from sqlalchemy import text
from src.llm.question_generated.agent import get_llm
from langchain_core.output_parsers import JsonOutputParser
from pydantic import BaseModel, Field
from typing import List
import traceback

class HRExtractedQuestion(BaseModel):
    question: str = Field(description="The question asked by the HR")
    expected_answer: str = Field(description="A brief expected answer to the question")
    candidate_answer: str = Field(description="The answer given by the candidate")
    score: float = Field(description="Score from 0.0 to 1.0 evaluating the candidate's answer")
    reason: str = Field(description="Thai reason explaining the score")

class HRExtractedQuestionList(BaseModel):
    questions: List[HRExtractedQuestion] = Field(description="List of extracted questions")

def process_unscored_hr_questions(db: Session, interview_id: int):
    # 1) Fetch chat history
    query_chat = text("""
        SELECT u.role, ch.message 
        FROM chat_histories ch
        JOIN users u ON ch.user_id = u.id
        WHERE ch.interview_id = :id
        ORDER BY ch.id ASC
    """)
    rows = db.execute(query_chat, {"id": interview_id}).fetchall()
    
    if not rows:
        return
        
    chat_lines = []
    for r in rows:
        role = str(r.role).strip().upper()
        msg = str(r.message).strip()
        if "[HR_LOCAL_EVAL" in msg or msg.startswith("[AI]"):
            role = "AI"
            
        chat_lines.append(f"[{role}] {msg}")
        
    chat_context = "\n".join(chat_lines)
    
    # 2) Fetch existing questions to avoid re-evaluating them
    query_q = text("""
        SELECT question FROM interview_questions 
        WHERE interview_id = :id
    """)
    q_rows = db.execute(query_q, {"id": interview_id}).fetchall()
    existing_questions_text = "\n".join(f"- {r.question}" for r in q_rows)
    if not existing_questions_text:
        existing_questions_text = "None"
    
    # 3) LLM extraction
    parser = JsonOutputParser(pydantic_object=HRExtractedQuestionList)
    llm = get_llm(temperature=0.0)
    
    prompt = f"""
You are an expert HR evaluator.

### CONVERSATION TRANSCRIPT
{chat_context}

### ALREADY EVALUATED QUESTIONS (DO NOT DUPLICATE THESE)
{existing_questions_text}

### TASK
Identify any meaningful interview questions asked by the HR (role HR) that are NOT in the 'ALREADY EVALUATED QUESTIONS' list.
For each such question:
1. Extract the question text.
2. Determine a brief expected answer based on standard HR practices.
3. Extract the candidate's answer from the conversation (role CANDIDATE).
4. Evaluate the candidate's answer giving a score between 0.0 and 1.0.
5. Provide a brief reason for the score IN THAI ONLY.

If there are no new questions asked by HR, return an empty array for questions.

{parser.get_format_instructions()}
"""
    try:
        chain = llm | parser
        result = chain.invoke(prompt)
        extracted = HRExtractedQuestionList(**result)
        
        # 4) Save to DB
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
        for q in extracted.questions:
            if not q.question.strip() or not q.candidate_answer.strip():
                continue
                
            db.execute(sql_insert, {
                "interview_id": interview_id,
                "question": q.question,
                "expected_answer": [q.expected_answer],
                "user_answer": q.candidate_answer,
                "score": float(q.score),
                "reason": q.reason,
            })
        db.commit()
    except Exception as e:
        db.rollback()
        traceback.print_exc()
        print(f"Extraction failed: {str(e)}")

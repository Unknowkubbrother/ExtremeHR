import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.databases.db_connect import SessionLocal
from sqlalchemy import text
from datetime import datetime, timedelta

def insert_mock_data():
    db = SessionLocal()
    interview_id = 6
    
    interview = db.execute(text("SELECT user_id, job_id FROM interviews WHERE id = :id"), {"id": interview_id}).first()
    if not interview:
        print(f"Interview {interview_id} not found!")
        return
    candidate_id = interview.user_id
    job = db.execute(text("SELECT user_id FROM jobs WHERE id = :id"), {"id": interview.job_id}).first()
    hr_id = job.user_id if job else 1
    
    db.execute(text("DELETE FROM chat_histories WHERE interview_id = :id"), {"id": interview_id})
    db.execute(text("DELETE FROM interview_questions WHERE interview_id = :id"), {"id": interview_id})
    db.execute(text("DELETE FROM interview_summaries WHERE interview_id = :id"), {"id": interview_id})
    db.commit()
    
    db.execute(text("""
        INSERT INTO interview_questions (interview_id, question, expected_answer, user_answer, score, reason)
        VALUES 
        (:id, :q1, :ea1, :ua1, 0.85, :r1),
        (:id, :q2, :ea2, :ua2, 0.70, :r2)
    """), {
        "id": interview_id,
        "q1": "Can you explain your experience with Next.js and FastAPI?",
        "ea1": ["Candidate should explain building full stack apps with Next.js and FastAPI."],
        "ua1": "I have built a web-based AI system using Next.js for the frontend and FastAPI for backend services.",
        "r1": "ผู้สมัครมีประสบการณ์ตรงในการใช้ Next.js และ FastAPI ตอบได้ตรงประเด็น",
        "q2": "How do you handle imbalanced datasets in machine learning?",
        "ea2": ["Candidate should mention techniques like oversampling, undersampling, or adjusting class weights."],
        "ua2": "In my AKI Prediction project, I handled imbalanced data by evaluating F1-score and adjusting the dataset distribution.",
        "r2": "ผู้สมัครอธิบายวิธีจัดการข้อมูลได้ดี แต่ยังขาดรายละเอียดเชิงลึกเกี่ยวกับเทคนิคการจัดการ"
    })
    db.commit()

    time_counter = datetime.now() - timedelta(minutes=30)
    
    def add_chat(u_id, msg):
        nonlocal time_counter
        db.execute(text("INSERT INTO chat_histories (interview_id, user_id, message, created_at) VALUES (:interview_id, :user_id, :message, :created_at)"), {
            "interview_id": interview_id,
            "user_id": u_id,
            "message": msg,
            "created_at": time_counter
        })
        time_counter += timedelta(minutes=1)

    add_chat(hr_id, "Welcome to the interview for the Senior Full Stack Developer role.")
    add_chat(candidate_id, "Thank you, I'm excited to be here.")
    add_chat(hr_id, "[AI] Can you explain your experience with Next.js and FastAPI?")
    add_chat(candidate_id, "I have built a web-based AI system using Next.js for the frontend and FastAPI for backend services.")
    add_chat(hr_id, "[AI][HR_LOCAL_EVAL:101] Evaluation Score: 0.85\nReason: ผู้สมัครมีประสบการณ์ตรงในการใช้ Next.js และ FastAPI ตอบได้ตรงประเด็น")
    
    add_chat(hr_id, "[AI] How do you handle imbalanced datasets in machine learning?")
    add_chat(candidate_id, "In my AKI Prediction project, I handled imbalanced data by evaluating F1-score and adjusting the dataset distribution.")
    add_chat(hr_id, "[AI][HR_LOCAL_EVAL:102] Evaluation Score: 0.70\nReason: ผู้สมัครอธิบายวิธีจัดการข้อมูลได้ดี แต่ยังขาดรายละเอียดเชิงลึกเกี่ยวกับเทคนิคการจัดการ")
    
    # Extracted HR questions
    add_chat(hr_id, "I see you worked on a project called Hirenz. What role did graph databases like Neo4j play in this system?")
    add_chat(candidate_id, "We used Neo4j to build a relationship graph between candidate skills and job requirements. This helped us find high-fit candidates efficiently compared to a standard SQL approach.")
    
    add_chat(hr_id, "That's interesting. You also have Flutter and Dart skills. Have you ever built a production application with them, or was it just for the internship demo?")
    add_chat(candidate_id, "It was primarily for the visitor management system demo during my internship. We built the core logic and UI, but it wasn't deployed to a large production user base.")
    
    db.commit()
    print("Mock data successfully inserted!")

if __name__ == "__main__":
    insert_mock_data()

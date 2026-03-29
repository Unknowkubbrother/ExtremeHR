import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.databases.db_connect import SessionLocal
from sqlalchemy import text
from datetime import datetime, timedelta

def insert_mock_data():
    db = SessionLocal()
    interview_id = 10
    
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
        (:id, :q1, :ea1, :ua1, 0.70, :r1),
        (:id, :q2, :ea2, :ua2, 0.65, :r2)
    """), {
        "id": interview_id,
        "q1": "คุณเรียนจบคณะบริหารธุรกิจมา แต่ทำไมถึงสนใจมาสมัครตำแหน่ง Developer และเริ่มเรียนรู้การเขียนโปรแกรมด้วยตัวเองอย่างไร?",
        "ea1": ["Candidate should show willingness to learn new technologies and explain their motivation for switching careers or exploring dev roles."],
        "ua1": "ผมเห็นว่าเทคโนโลยีเข้ามามีบทบาทในทุกธุรกิจครับ ผมเลยเริ่มสนใจและศึกษาการใช้ AI มาช่วยในการทำงานพื้นฐาน และอยากจะพัฒนาทักษะในการสร้างเครื่องมือด้วยตัวเองครับ ผมเป็นคนที่ไม่กลัวปัญหาและมองว่ามันคือความท้าทายในการเรียนรู้สิ่งใหม่ๆ ครับ",
        "r1": "มีทัศนคติที่ดีและมีความมุ่งมั่น แม้จะไม่มีพื้นฐานทางเทคนิคโดยตรง แต่แสดงให้เห็นถึงความพร้อมในการเรียนรู้",
        "q2": "คุณเคยผ่านการอบรมเรื่องการใช้ AI มาก่อน คุณคิดว่า AI จะเข้ามาช่วยในการทำงาน Developer ของคุณได้อย่างไรบ้าง?",
        "ea2": ["Candidate should mention using AI for coding assistance, debugging, or productivity improvement."],
        "ua2": "ผมน่าจะใช้ AI มาช่วยในการร่างโครงสร้าง Code หรือช่วยตรวจสอบข้อผิดพลาดเบื้องต้นได้ครับ รวมถึงการใช้ AI มาสรุปข้อมูลต่างๆ เพื่อให้ทำงานได้รวดเร็วและละเอียดรอบคอบมากขึ้น เหมือนที่ผมฝึกฝนมาครับ",
        "r2": "เข้าใจการนำเครื่องมือ (AI) มาใช้ประโยชน์เบื้องต้น แต่ยังขาดทักษะทางเทคนิคที่เจาะลึก"
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

    add_chat(hr_id, "ยินดีตอนรับเข้าสู่การสัมภาษณ์ตำแหน่ง Developer ครับ แนะนำตัวสั้นๆ หน่อยครับ")
    add_chat(candidate_id, "สวัสดีครับ ผมชื่อ ชวิศ มีสมโภชน์ หรือชื่อเล่นว่า นินจา ครับ กำลังเรียนอยู่ปี 3 คณะบริหารธุรกิจ มหาวิทยาลัยศรีปทุมครับ ผมเป็นคนที่พร้อมจะพัฒนาและเรียนรู้อะไรใหม่ๆ อยู่เสมอ ไม่กลัวปัญหา และมองว่ามันเป็นความท้าทายครับ")
    
    add_chat(hr_id, "[AI] คุณเรียนจบคณะบริหารธุรกิจมา แต่ทำไมถึงสนใจมาสมัครตำแหน่ง Developer และเริ่มเรียนรู้การเขียนโปรแกรมด้วยตัวเองอย่างไร?")
    add_chat(candidate_id, "ผมเห็นว่าเทคโนโลยีเข้ามามีบทบาทในทุกธุรกิจครับ ผมเลยเริ่มสนใจและศึกษาการใช้ AI มาช่วยในการทำงานพื้นฐาน และอยากจะพัฒนาทักษะในการสร้างเครื่องมือด้วยตัวเองครับ ผมเป็นคนที่ไม่กลัวปัญหาและมองว่ามันคือความท้าทายในการเรียนรู้สิ่งใหม่ๆ ครับ")
    add_chat(hr_id, "[AI][HR_LOCAL_EVAL:201] Evaluation Score: 0.70\nReason: มีทัศนคติที่ดีและมีความมุ่งมั่น แม้จะไม่มีพื้นฐานทางเทคนิคโดยตรง แต่แสดงให้เห็นถึงความพร้อมในการเรียนรู้")
    
    add_chat(hr_id, "[AI] คุณเคยผ่านการอบรมเรื่องการใช้ AI มาก่อน คุณคิดว่า AI จะเข้ามาช่วยในการทำงาน Developer ของคุณได้อย่างไรบ้าง?")
    add_chat(candidate_id, "ผมน่าจะใช้ AI มาช่วยในการร่างโครงสร้าง Code หรือช่วยตรวจสอบข้อผิดพลาดเบื้องต้นได้ครับ รวมถึงการใช้ AI มาสรุปข้อมูลต่างๆ เพื่อให้ทำงานได้รวดเร็วและละเอียดรอบคอบมากขึ้น เหมือนที่ผมฝึกฝนมาครับ")
    add_chat(hr_id, "[AI][HR_LOCAL_EVAL:202] Evaluation Score: 0.65\nReason: เข้าใจการนำเครื่องมือ (AI) มาใช้ประโยชน์เบื้องต้น แต่ยังขาดทักษะทางเทคนิคที่เจาะลึก")
    
    # Extracted HR questions
    add_chat(hr_id, "เล่าประสบการณ์ตอนจัดบูธขายของในงานเทศกาลให้ฟังหน่อยครับ เช่น งานสะพานข้ามแม่น้ำแคว งานพวกนี้ให้อะไรกับคุณบ้าง?")
    add_chat(candidate_id, "ผมได้ฝึกการทำงานร่วมกับผู้อื่นและการปรับตัวให้เข้ากับสถานการณ์ต่างๆ ครับ เพราะในงานเทศกาลมีปัญหาเฉพาะหน้าเยอะมาก แต่ผมก็นิ่งและแก้ปัญหาไปได้ครับ ทำให้ผมมีความละเอียดรอบคอบในการทำงานมากขึ้นด้วยครับ")
    
    add_chat(hr_id, "คุณรุ้สึกว่าทักษะการตลาดหรือการใช้ Canva จะมาช่วยอะไรในทีม Dev ได้บ้างครับ?")
    add_chat(candidate_id, "ผมสามารถช่วยทีมในการจัดเตรียมเอกสารข้อมูล หรือการออกแบบ UI เบื้องต้นใน Canva เพื่อสื่อสารไอเดียให้เพื่อนในทีมเข้าใจได้ง่ายขึ้นครับ รวมถึงการมองในมุมมองของผู้ใช้งานเพื่อให้โปรแกรมที่เราพัฒนาตอบโจทย์ผู้ใช้มากที่สุดครับ")
    
    db.commit()
    print("Mock data for Interview ID 10 (Chawis Meesomphot - Ninja) successfully inserted!")

if __name__ == "__main__":
    insert_mock_data()

if __name__ == "__main__":
    insert_mock_data()
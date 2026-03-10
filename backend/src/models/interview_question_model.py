from sqlalchemy import Column, String, Integer, BigInteger, ForeignKey, Float
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import relationship
from src.databases.db_connect import Base

class InterviewQuestion(Base):
    __tablename__ = "interview_questions"

    id = Column(Integer, primary_key=True, index=True)
    interview_id = Column(Integer, ForeignKey("interviews.id"), nullable=False)
    
    question = Column(String, nullable=False)
    expected_answer = Column(ARRAY(String), nullable=True)
    user_answer = Column(String, nullable=True)
    score = Column(Float, nullable=True)
    reason = Column(String, nullable=True)

    interview = relationship("Interview", back_populates="questions")

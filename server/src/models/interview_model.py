from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, BigInteger, Float
from src.databases.db_connect import Base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from src.enums.apply_status_enum import ApplyStatusEnum

class Interview(Base):
    __tablename__ = "interviews"
    id = Column(Integer, primary_key=True, index=True)
    status = Column(String, nullable=False, server_default=ApplyStatusEnum.WAITING.value)
    is_active = Column(Boolean, server_default="true", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    job_id = Column(BigInteger, ForeignKey("jobs.id"), nullable=False)

    context = Column(String, nullable=True)
    candidate_profile_summary = Column(String, nullable=True)
    job_profile_summary = Column(String, nullable=True)
    candidate_strengths = Column(String, nullable=True)
    candidate_gaps = Column(String, nullable=True)
    hr_interest = Column(String, nullable=True)
    difficulty = Column(Float, nullable=True, server_default="0.5")
    
    user = relationship("User", back_populates="interviews")
    job = relationship("Job", back_populates="interviews")
    questions = relationship("InterviewQuestion", back_populates="interview")
    chat_histories = relationship("ChatHistory", back_populates="interview")
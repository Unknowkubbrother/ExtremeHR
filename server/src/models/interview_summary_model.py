from sqlalchemy import JSON, Column, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import relationship

from src.databases.db_connect import Base


class InterviewSummary(Base):
    __tablename__ = "interview_summaries"

    id = Column(Integer, primary_key=True, index=True)
    interview_id = Column(Integer, ForeignKey("interviews.id"), nullable=False)

    total_score = Column(Float, nullable=True)
    experience_score = Column(Float, nullable=True)
    communication_score = Column(Float, nullable=True)
    technical_score = Column(Float, nullable=True)
    recommendation = Column(String, nullable=True)
    confidence = Column(Float, nullable=True)
    strengths = Column(JSON, nullable=True)
    weaknesses = Column(JSON, nullable=True)
    red_flags = Column(ARRAY(Text), nullable=True)
    evidence = Column(JSON, nullable=True)
    suggestion_summary = Column(Text, nullable=True)
    next_step = Column(Text, nullable=True)

    interview = relationship("Interview", back_populates="summary")

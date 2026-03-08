from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from src.databases.db_connect import Base
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

class ChatHistory(Base):
    __tablename__ = "chat_histories"
    id = Column(Integer, primary_key=True, index=True)
    interview_id = Column(Integer, ForeignKey("interviews.id"), nullable=False)
    message = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    interview = relationship("Interview", back_populates="chat_histories")
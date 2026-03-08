from sqlalchemy import Column, Integer, DateTime, ForeignKey, Text, BigInteger
from src.databases.db_connect import Base
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

# Import models to ensure they are registered with SQLAlchemy's metadata before relationships are fully built
from src.models.interview_model import Interview
from src.models.auth_model import User

class ChatHistory(Base):
    __tablename__ = "chat_histories"
    id = Column(Integer, primary_key=True, index=True)
    interview_id = Column(Integer, ForeignKey("interviews.id"), nullable=False)
    message = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)

    interview = relationship("Interview", back_populates="chat_histories")
    user = relationship("User", back_populates="chat_histories")
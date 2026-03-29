from sqlalchemy import (
    Column,
    String,
    BigInteger,
    Boolean,
    DateTime,
    func,
    text,
    ForeignKey
)
from sqlalchemy.orm import relationship
from src.databases.db_connect import Base

class User(Base):
    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    password = Column(String(255), nullable=False)

    is_active = Column(Boolean, server_default=text("true"), default=True)
    role = Column(String(50), server_default=text("'candidate'"), nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    jobs = relationship("Job", back_populates="user")
    resume = relationship("Resume", back_populates="user", uselist=False)
    company = relationship("Company", back_populates="user", uselist=False)
    interviews = relationship("Interview", back_populates="user")
    chat_histories = relationship("ChatHistory", back_populates="user")

class Company(Base):
    __tablename__ = "companies"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    location = Column(String(255), nullable=False)

    user_id = Column(BigInteger, ForeignKey("users.id"), unique=True, nullable=False)
    user = relationship("User", back_populates="company")

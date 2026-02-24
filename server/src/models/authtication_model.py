from sqlalchemy import (
    Column,
    String,
    BigInteger,
    Boolean,
    DateTime,
    func,
    text
)
from sqlalchemy.orm import relationship
from src.databases.db_connect import Base

class User(Base):
    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    password = Column(String(255), nullable=False)

    is_active = Column(Boolean, default=True)
    role = Column(String(50), server_default=text("'candidate'"), nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

from sqlalchemy import (
    Column,
    String,
    BigInteger,
    Boolean,
    DateTime,
    ForeignKey,
    Enum,
    func,
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

    created_at = Column(DateTime)
    updated_at = Column(DateTime)

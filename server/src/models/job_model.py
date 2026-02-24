from sqlalchemy import (
    Column,
    String,
    BigInteger,
    Integer,
    DateTime,
    Text,
    func
)
from sqlalchemy.dialects.postgresql import ARRAY
from src.databases.db_connect import Base

class Job(Base):
    __tablename__ = "jobs"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    title = Column(String(255), nullable=False)
    company = Column(String(255), nullable=False)
    location = Column(String(255), nullable=False)
    
    description = Column(Text, nullable=False)
    responsibilities = Column(ARRAY(String), nullable=False, server_default='{}')
    qualifications = Column(ARRAY(String), nullable=False, server_default='{}')
    skills = Column(ARRAY(String), nullable=False, server_default='{}')

    headcount = Column(Integer, nullable=False, default=1)
    minAge = Column(Integer, nullable=False, default=18)
    maxAge = Column(Integer, nullable=False, default=99)
    minSalary = Column(Integer, nullable=False, default=0)
    maxSalary = Column(Integer, nullable=False, default=0)

    postedAt = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

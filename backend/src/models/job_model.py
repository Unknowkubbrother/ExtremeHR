from sqlalchemy import (
    Column,
    String,
    BigInteger,
    Integer,
    Boolean,
    DateTime,
    Text,
    func,
    ForeignKey
)
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import relationship
from src.databases.db_connect import Base

class Job(Base):
    __tablename__ = "jobs"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    title = Column(String(255), nullable=False)

    job_fields = Column(ARRAY(String), nullable=False, server_default='{}')
    
    description = Column(Text, nullable=False)
    responsibilities = Column(ARRAY(String), nullable=False, server_default='{}')
    qualifications = Column(ARRAY(String), nullable=False, server_default='{}')
    skills = Column(ARRAY(String), nullable=False, server_default='{}')

    headcount = Column(Integer, nullable=False, default=1)
    minAge = Column(Integer, nullable=False, default=18)
    maxAge = Column(Integer, nullable=False, default=99)
    minSalary = Column(Integer, nullable=False, default=0)
    maxSalary = Column(Integer, nullable=False, default=0)

    is_active = Column(Boolean, nullable=False, server_default='true', default=True)

    postedAt = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    user = relationship("User", back_populates="jobs")
    interviews = relationship("Interview", back_populates="job")

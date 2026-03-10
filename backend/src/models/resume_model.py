from sqlalchemy import (
    Column,
    String,
    BigInteger,
    Integer,
    Float,
    DateTime,
    Text,
    func,
    ForeignKey
)
from sqlalchemy.orm import relationship
from src.databases.db_connect import Base

class Resume(Base):
    __tablename__ = "resumes"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(BigInteger, ForeignKey("users.id"), unique=True, nullable=False)
    
    full_name = Column(String(255), nullable=False)
    age = Column(Integer, nullable=True)
    phone = Column(String(20), nullable=True)
    email = Column(String(255), nullable=True)
    pdf_path = Column(String(255), nullable=True)
    address = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="resume")
    skills = relationship("Skill", back_populates="resume", cascade="all, delete-orphan")
    education = relationship("Education", back_populates="resume", cascade="all, delete-orphan")
    experience = relationship("Experience", back_populates="resume", cascade="all, delete-orphan")
    projects = relationship("Project", back_populates="resume", cascade="all, delete-orphan")

class Skill(Base):
    __tablename__ = "resume_skills"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    resume_id = Column(BigInteger, ForeignKey("resumes.id"), nullable=False)
    name = Column(String(255), nullable=False)

    resume = relationship("Resume", back_populates="skills")

class Education(Base):
    __tablename__ = "resume_education"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    resume_id = Column(BigInteger, ForeignKey("resumes.id"), nullable=False)
    
    institution = Column(String(255), nullable=False)
    degree = Column(String(255), nullable=True)
    faculty = Column(String(255), nullable=True)
    major = Column(String(255), nullable=True)
    gpax = Column(Float, nullable=True)
    
    start_year = Column(Integer, nullable=True)
    start_month = Column(Integer, nullable=True)
    end_year = Column(Integer, nullable=True)
    end_month = Column(Integer, nullable=True)

    resume = relationship("Resume", back_populates="education")

class Experience(Base):
    __tablename__ = "resume_experience"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    resume_id = Column(BigInteger, ForeignKey("resumes.id"), nullable=False)
    
    company = Column(String(255), nullable=False)
    role = Column(String(255), nullable=True)
    
    start_year = Column(Integer, nullable=True)
    start_month = Column(Integer, nullable=True)
    end_year = Column(Integer, nullable=True)
    end_month = Column(Integer, nullable=True)
    
    description = Column(Text, nullable=True)

    resume = relationship("Resume", back_populates="experience")

class Project(Base):
    __tablename__ = "resume_projects"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    resume_id = Column(BigInteger, ForeignKey("resumes.id"), nullable=False)
    
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)

    resume = relationship("Resume", back_populates="projects")


from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime


class JobListItemResponse(BaseModel):
    id: int
    title: str
    company: str
    location: str
    salary: int

    model_config = ConfigDict(from_attributes=True)

class JobCreate(BaseModel):
    title: str
    job_fields: List[str]
    description: str
    responsibilities: List[str]
    qualifications: List[str]
    skills: List[str]
    headcount: int
    minAge: int
    maxAge: int
    minSalary: int
    maxSalary: int

class JobUpdate(BaseModel):
    id: int
    title: Optional[str] = None
    job_fields: Optional[List[str]] = None
    description: Optional[str] = None
    responsibilities: Optional[List[str]] = None
    qualifications: Optional[List[str]] = None
    skills: Optional[List[str]] = None
    headcount: Optional[int] = None
    minAge: Optional[int] = None
    maxAge: Optional[int] = None
    minSalary: Optional[int] = None
    maxSalary: Optional[int] = None

class JobDetailResponse(JobCreate):
    id: int
    postedAt: datetime
    
    model_config = ConfigDict(from_attributes=True)

class JobHRResponse(BaseModel):
    id: int
    title: str
    company: str
    candidate_count: int

    model_config = ConfigDict(from_attributes=True)
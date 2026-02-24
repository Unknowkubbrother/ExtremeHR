from pydantic import BaseModel, ConfigDict
from typing import List
from datetime import datetime


class JobListItemResponse(BaseModel):
    id: str
    title: str
    company: str
    location: str
    salary: int

    model_config = ConfigDict(from_attributes=True)

class JobCreate(BaseModel):
    title: str
    company: str
    location: str
    description: str
    responsibilities: List[str]
    qualifications: List[str]
    skills: List[str]
    headcount: int
    minAge: int
    maxAge: int
    minSalary: int
    maxSalary: int


class JobDetailResponse(JobCreate):
    id: int
    postedAt: datetime
    
    model_config = ConfigDict(from_attributes=True)

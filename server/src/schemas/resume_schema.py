from pydantic import BaseModel, ConfigDict, field_validator
from typing import List, Optional
import re

class SkillBase(BaseModel):
    name: str

class SkillCreate(SkillBase):
    pass


class SkillResponse(SkillBase):
    id: int
    model_config = ConfigDict(from_attributes=True)

class EducationBase(BaseModel):
    institution: str
    degree: Optional[str] = None
    faculty: Optional[str] = None
    major: Optional[str] = None
    gpax: Optional[float] = None
    start_year: Optional[int] = None
    start_month: Optional[int] = None
    end_year: Optional[int] = None
    end_month: Optional[int] = None

class EducationCreate(EducationBase):
    pass

class EducationResponse(EducationBase):
    id: int
    model_config = ConfigDict(from_attributes=True)

class ExperienceBase(BaseModel):
    company: str
    role: Optional[str] = None
    start_year: Optional[int] = None
    start_month: Optional[int] = None
    end_year: Optional[int] = None
    end_month: Optional[int] = None
    description: Optional[str] = None

class ExperienceCreate(ExperienceBase):
    pass

class ExperienceResponse(ExperienceBase):
    id: int
    model_config = ConfigDict(from_attributes=True)

class ResumeBase(BaseModel):
    full_name: str
    age: Optional[int] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and not v.isdigit():
            raise ValueError("Phone must contain only numbers")
        return v

class ResumeCreate(ResumeBase):
    skills: List[SkillCreate] = []
    education: List[EducationCreate] = []
    experience: List[ExperienceCreate] = []

class ResumeResponse(ResumeBase):
    id: int
    user_id: int
    skills: List[SkillResponse] = []
    education: List[EducationResponse] = []
    experience: List[ExperienceResponse] = []
    
    model_config = ConfigDict(from_attributes=True)

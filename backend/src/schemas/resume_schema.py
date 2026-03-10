from pydantic import BaseModel, ConfigDict, field_validator, Field, AliasChoices
from typing import List, Optional
import re
from src.schemas.llm_schema import AppBaseModel

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

class ProjectBase(BaseModel):
    title: str
    description: Optional[str] = None

class ProjectCreate(ProjectBase):
    pass

class ProjectResponse(ProjectBase):
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
            # บาง Resume อาจจะมีเครื่องหมาย + หรือ - ติดมา 
            # แต่ถ้าต้องการให้เป็นตัวเลขล้วนตาม Schema เดิม:
            v_clean = re.sub(r'[^0-9]', '', v)
            return v_clean
        return v

class ResumeCreate(ResumeBase):
    skills: List[SkillCreate] = []
    education: List[EducationCreate] = []
    experience: List[ExperienceCreate] = []
    projects: List[ProjectCreate] = []

class ResumeResponse(ResumeBase):
    id: int
    user_id: int
    skills: List[SkillResponse] = []
    education: List[EducationResponse] = []
    experience: List[ExperienceResponse] = []
    projects: List[ProjectResponse] = []
    
    model_config = ConfigDict(from_attributes=True)


#TEST LLM EXTRACT RESUME

class EducationItem(AppBaseModel):
    institution: str = Field(..., description="University / School name")
    degree: str = Field(..., description="Degree or Certificate")
    faculty: str = Field("", description="Faculty")
    major: str = Field("", description="Major")
    gpax: float = Field(0.0, description="GPAX as float")
    start_month: int = Field(0, description="Start month")
    start_year: int = Field(0, description="Start year")
    end_month: int = Field(0, description="End month")
    end_year: int = Field(0, description="End year")


class ExperienceItem(AppBaseModel):
    company: str = Field(..., description="Company or Organization")
    role: str = Field(..., description="Job role")
    start_month: int = Field(0, description="Start month")
    start_year: int = Field(0, description="Start year")
    end_month: int = Field(0, description="End month")
    end_year: int = Field(0, description="End year")
    description: str = Field("", description="Work description")


class ProjectItem(AppBaseModel):
    title: str = Field(..., description="Project name")
    description: str = Field("", description="Brief project description")


class ResumeResult(AppBaseModel):
    analysis: str = Field(..., description="Thai evaluation of the candidate's core strengths.")
    full_name: str = Field(
        ...,
        description="Full Name",
        validation_alias=AliasChoices("full_name", "name")
    )
    age: int = Field(0, description="Age")
    phone: str = Field("", description="Phone number")
    email: str = Field("", description="Email")
    address: str = Field("", description="Address")
    skills: List[str] = Field(default_factory=list, description="A flat list of technology names.")
    education: List[EducationItem] = Field(default_factory=list)
    experience: List[ExperienceItem] = Field(default_factory=list)
    projects: List[ProjectItem] = Field(default_factory=list)



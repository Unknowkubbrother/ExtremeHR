from pydantic import BaseModel
from src.enums.apply_status_enum import ApplyStatusEnum
from datetime import datetime

class UpdateStatusRequest(BaseModel):
    status: ApplyStatusEnum

class ApplyJobResponse(BaseModel):
    isSuccess: bool

class InterviewsResponse(BaseModel):
    id: int
    status: str
    created_at: datetime
    job_id: int
    jobtitle: str
    companyname: str

class HRCandidateResponse(BaseModel):
    id: int
    status: str
    created_at: datetime
    job_id: int
    candidate_name: str
    candidate_id: int



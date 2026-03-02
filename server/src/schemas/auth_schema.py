from pydantic import BaseModel, EmailStr
from typing import Optional
import uuid

class UserRegister(BaseModel):
    username: str
    email: EmailStr
    password: str
    role: str = "candidate"

class UserLogin(BaseModel):
    username: str
    password: str
    role: str = "candidate"

class TokenResponse(BaseModel):
    access_token: str
    token_type: str

class UserResponse(BaseModel):
    id: int
    username: str
    email: EmailStr
    role: str

    class Config:
        from_attributes = True

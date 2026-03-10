from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from pydantic import BaseModel
from src.databases.db_connect import get_db
from src.utils.auth_utils import get_current_user_id

class CompanyUpdate(BaseModel):
    name: str
    location: str

company_router = APIRouter()

@company_router.get("/me", tags=["company"])
def get_my_company(user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    sql = text("SELECT * FROM companies WHERE user_id = :user_id")
    company = db.execute(sql, {"user_id": user_id}).first()
    if not company:
        return None
    return dict(company._mapping)

@company_router.post("/me", tags=["company"])
def update_my_company(data: CompanyUpdate, user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    # Check if user is HR
    sql_role = text("SELECT role FROM users WHERE id = :id")
    user = db.execute(sql_role, {"id": user_id}).first()
    if not user or user.role != "hr":
        raise HTTPException(status_code=403, detail="Only HR users can manage company profiles")

    # Check if exists
    sql_check = text("SELECT id FROM companies WHERE user_id = :user_id")
    exists = db.execute(sql_check, {"user_id": user_id}).first()

    if exists:
        sql_update = text("""
            UPDATE companies 
            SET name = :name, location = :location 
            WHERE user_id = :user_id 
            RETURNING *
        """)
        result = db.execute(sql_update, {**data.model_dump(), "user_id": user_id})
    else:
        sql_insert = text("""
            INSERT INTO companies (name, location, user_id) 
            VALUES (:name, :location, :user_id) 
            RETURNING *
        """)
        result = db.execute(sql_insert, {**data.model_dump(), "user_id": user_id})
    
    db.commit()
    updated = result.first()
    return dict(updated._mapping)

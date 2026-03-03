from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from src.databases.db_connect import get_db
from src.schemas.auth_schema import UserRegister, UserLogin, TokenResponse, UserResponse, UserUpdate
from src.utils.auth_utils import get_password_hash, verify_password, create_access_token, get_current_user_id

auth_router = APIRouter()

@auth_router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED, tags=["auth"])
def register(user_data: UserRegister, db: Session = Depends(get_db)):
    
    sql_check_username = text("SELECT id FROM users WHERE username = :username")
    existing_user_by_username = db.execute(sql_check_username, {"username": user_data.username}).first()
    if existing_user_by_username:
        raise HTTPException(status_code=400, detail="Username already registered")

    sql_check_email = text("SELECT id FROM users WHERE email = :email")
    existing_user_by_email = db.execute(sql_check_email, {"email": user_data.email}).first()
    if existing_user_by_email:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_pwd = get_password_hash(user_data.password)

    sql_insert = text("""
        INSERT INTO users (username, email, password, role) 
        VALUES (:username, :email, :password, :role) 
        RETURNING id, username, email, role
    """)
    
    result = db.execute(sql_insert, {
        "username": user_data.username, 
        "email": user_data.email, 
        "password": hashed_pwd,
        "role": user_data.role
    })
    
    db.commit()
    new_user = result.first()

    return {"id": new_user.id, "username": new_user.username, "email": new_user.email, "role": new_user.role}

@auth_router.post("/login", response_model=TokenResponse, tags=["auth"])
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    sql_find_user = text("""
        SELECT id, password 
        FROM users 
        WHERE (username = :identifier OR email = :identifier) AND role = :role
    """)
    
    user = db.execute(sql_find_user, {"identifier": user_data.username, "role": user_data.role}).first()

    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Credentials")

    if not verify_password(user_data.password, user.password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Credentials")

    access_token = create_access_token(data={"sub": str(user.id)})

    return {"access_token": access_token, "token_type": "bearer"}

@auth_router.get("/me", response_model=UserResponse, tags=["auth"])
def get_current_user_info(user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    sql_find_user = text("SELECT id, username, email, role FROM users WHERE id = :id")
    user = db.execute(sql_find_user, {"id": user_id}).first()
    
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    return {"id": user.id, "username": user.username, "email": user.email, "role": user.role}

@auth_router.post("/me", response_model=UserResponse, tags=["auth"])
def update_current_user_info(data: UserUpdate, user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    # Check if username or email already exists for other users
    sql_check = text("""
        SELECT id FROM users 
        WHERE (username = :username OR email = :email) AND id != :id
    """)
    existing = db.execute(sql_check, {"username": data.username, "email": data.email, "id": user_id}).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username or email already taken")

    sql_update_query = "UPDATE users SET username = :username, email = :email"
    params = {"username": data.username, "email": data.email, "id": user_id}

    if data.password:
        sql_update_query += ", password = :password"
        params["password"] = get_password_hash(data.password)

    sql_update_query += " WHERE id = :id RETURNING id, username, email, role"
    
    result = db.execute(text(sql_update_query), params)
    db.commit()
    
    updated_user = result.first()
    return {"id": updated_user.id, "username": updated_user.username, "email": updated_user.email, "role": updated_user.role}
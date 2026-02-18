from fastapi import APIRouter, HTTPException, status, Response

auth_router = APIRouter()

@auth_router.post("/login", tags=["auth"])
async def login():
    return {
        "status": 200,
        "message": "success!!",
    }

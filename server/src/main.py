from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from .routes import authentication

app = FastAPI()

# Mount static files
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"Hello": "World"}

app.include_router(authentication.auth_router, prefix="/auth")
# uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from .routes import auth_route, job_route

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

app.include_router(auth_route.auth_router, prefix="/auth")
app.include_router(job_route.job_router, prefix="/jobs")
# uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload

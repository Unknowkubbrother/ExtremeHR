from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from .routes import auth_route, job_route, resume_route, company_route, job_hr_route, search_route, interview_route, interview_ws_route, interview_question_route

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
app.include_router(resume_route.resume_router, prefix="/resume")
app.include_router(company_route.company_router, prefix="/company")
app.include_router(job_hr_route.job_hr_router, prefix="/jobs_hr")
app.include_router(search_route.search_router, prefix="/search")
app.include_router(interview_route.interview_router, prefix="/interview")
app.include_router(interview_ws_route.interview_ws_router, prefix="/ws/interview")
app.include_router(interview_question_route.interview_question_router, prefix="/interview_question")
# uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
# alembic revision --autogenerate -m "init"
# alembic upgrade head


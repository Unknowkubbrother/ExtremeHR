import os
import json
from sqlalchemy import text
from sqlalchemy.orm import Session
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document
from src.models.resume_model import Resume, Skill, Experience, Project
from src.models.interview_model import Interview
from src.models.interview_question_model import InterviewQuestion
from src.models.interview_summary_model import InterviewSummary
from src.models.chat_history_model import ChatHistory

class CandidateEmbeddingService:
    def __init__(self):
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=500,
            chunk_overlap=50,
            separators=["\n\n", "\n", ".", " ", ""],
        )

    def extract_candidate_data(self, db: Session, interview_id: int):
        """Extracts all relevant text data for a candidate's interview."""
        
        # 1. Get Interview Core
        interview = db.query(Interview).filter(Interview.id == interview_id).first()
        if not interview:
            return []

        job_id = interview.job_id
        candidate_id = interview.user_id
        documents = []

        # 2. Get Resume Data
        resume = db.query(Resume).filter(Resume.user_id == candidate_id).first()
        if resume:
            resume_id = resume.id
            
            # Skills
            skills = db.query(Skill).filter(Skill.resume_id == resume_id).all()
            if skills:
                content = "Skills: " + ", ".join([s.name for s in skills])
                documents.extend(self._create_docs(content, "skill", interview_id, job_id, candidate_id))

            # Experience
            exps = db.query(Experience).filter(Experience.resume_id == resume_id).all()
            for exp in exps:
                content = f"Experience at {exp.company} as {exp.role}: {exp.description}"
                documents.extend(self._create_docs(content, "experience", interview_id, job_id, candidate_id))

            # Projects
            projs = db.query(Project).filter(Project.resume_id == resume_id).all()
            for proj in projs:
                content = f"Project: {proj.title}. Description: {proj.description}"
                documents.extend(self._create_docs(content, "project", interview_id, job_id, candidate_id))

        # 3. Get Interview Summary
        summary = db.query(InterviewSummary).filter(InterviewSummary.interview_id == interview_id).first()
        if summary:
            summary_text = f"Interview Summary: {summary.suggestion_summary}\n"
            summary_text += f"Strengths: {json.dumps(summary.strengths, ensure_ascii=False)}\n"
            summary_text += f"Weaknesses: {json.dumps(summary.weaknesses, ensure_ascii=False)}\n"
            documents.extend(self._create_docs(summary_text, "interview_summary", interview_id, job_id, candidate_id))

        # 4. Get Questions & Answers
        questions = db.query(InterviewQuestion).filter(InterviewQuestion.interview_id == interview_id).all()
        for q in questions:
            if q.user_answer:
                content = f"Q: {q.question}\nA: {q.user_answer}\nScore: {q.score}\nReason: {q.reason}"
                documents.extend(self._create_docs(content, "question_answer", interview_id, job_id, candidate_id))

        # 5. Get Chat History
        chats = db.query(ChatHistory).filter(ChatHistory.interview_id == interview_id).order_by(ChatHistory.id.asc()).all()
        if chats:
            # Group chat by blocks of 5 messages to keep context
            chat_blocks = []
            current_block = []
            for i, chat in enumerate(chats):
                current_block.append(f"[{chat.user_id}]: {chat.message}")
                if (i + 1) % 5 == 0:
                    chat_blocks.append("\n".join(current_block))
                    current_block = []
            if current_block:
                chat_blocks.append("\n".join(current_block))
            
            for block in chat_blocks:
                documents.extend(self._create_docs(block, "chat_history", interview_id, job_id, candidate_id))

        return documents

    def _create_docs(self, content: str, type: str, interview_id: int, job_id: int, candidate_id: int):
        chunks = self.text_splitter.split_text(content)
        return [
            Document(
                page_content=chunk,
                metadata={
                    "interview_id": str(interview_id),
                    "job_id": str(job_id),
                    "candidate_id": str(candidate_id),
                    "type": type
                }
            ) for chunk in chunks
        ]

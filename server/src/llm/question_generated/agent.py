import os
import json
import re
from typing import List, Literal
from pydantic import BaseModel, Field
from langchain_openai import ChatOpenAI
from langchain_classic.agents import initialize_agent, Tool
from langchain_classic.agents.agent_types import AgentType
from langchain_classic.memory import ConversationBufferMemory

# =========================================================
# 1) Structured output schema
# =========================================================

class QuestionCandidate(BaseModel):
    interview_question: str = Field(..., description="The interview question")
    expected_answer: List[str] = Field(..., description="Array of 3 specific answer points we expect from the user")
    competency: str = Field(..., description="The competency being evaluated")
    difficulty: Literal["easy", "medium", "hard"] = Field(..., description="Difficulty level")
    why_this_question: str = Field(..., description="Reason for asking this question")

class QuestionCandidates(BaseModel):
    questions: List[QuestionCandidate]

# =========================================================
# 2) JSON parser and build agent
# =========================================================

def extract_json_text(raw_text: str) -> str:
    text = raw_text.strip()
    try:
        json.loads(text)
        return text
    except Exception:
        pass
    fenced = re.search(r"```(?:json)?\s*(\{.*\}|\[.*\])\s*```", text, re.DOTALL)
    if fenced:
        return fenced.group(1).strip()
    match = re.search(r"(\{.*\}|\[.*\])", text, re.DOTALL)
    if match:
        return match.group(1).strip()
    raise ValueError("No JSON object found in LLM output")

def build_agent(tools):
    llm = ChatOpenAI(
        base_url="https://api.opentyphoon.ai/v1",
        model="typhoon-v2.5-30b-a3b-instruct",
        api_key=os.getenv("TYPHOON_API_KEY") or os.getenv("TYPHOON_KEY"),
        temperature=0.2,
        max_tokens=4096,
    )

    memory = ConversationBufferMemory(
        memory_key="chat_history",
        return_messages=True
    )

    agent_executor = initialize_agent(
        tools=tools,
        llm=llm,
        agent=AgentType.CHAT_CONVERSATIONAL_REACT_DESCRIPTION,
        memory=memory,
        verbose=True
    )
    return agent_executor

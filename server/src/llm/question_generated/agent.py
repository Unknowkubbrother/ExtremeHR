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
# 2) LLM Utils
# =========================================================

def get_llm(temperature=0.2):
    return ChatOpenAI(
        base_url="https://api.opentyphoon.ai/v1",
        model="typhoon-v2.5-30b-a3b-instruct",
        api_key=os.getenv("TYPHOON_API_KEY") or os.getenv("TYPHOON_KEY"),
        temperature=temperature,
        max_tokens=4096,
    )

def extract_json_text(raw_text: str) -> str:
    text = raw_text.strip()
    
    # 1) Try parsing the entire text first
    try:
        json.loads(text)
        return text
    except Exception:
        pass

    # 2) Try to find content within backticks
    fenced = re.search(r"```(?:json)?\s*(.*?)\s*```", text, re.DOTALL)
    if fenced:
        inner_text = fenced.group(1).strip()
        try:
            json.loads(inner_text)
            return inner_text
        except Exception:
            text = inner_text # Fallback to searching within inner_text

    # 3) Robustly find the first JSON object or array
    # Find the first occurrence of '{' or '['
    first_dict = text.find('{')
    first_list = text.find('[')
    
    start_index = -1
    if first_dict != -1 and (first_list == -1 or first_dict < first_list):
        start_index = first_dict
    elif first_list != -1:
        start_index = first_list

    if start_index == -1:
        raise ValueError("No '{' or '[' found in LLM output")

    # Use JSONDecoder to find where the JSON structure ends
    trimmed_text = text[start_index:]
    decoder = json.JSONDecoder()
    try:
        obj, end_index = decoder.raw_decode(trimmed_text)
        return trimmed_text[:end_index].strip()
    except Exception as e:
        # Final fallback: generic greedy regex if raw_decode fails
        match = re.search(r"(\{.*\}|\[.*\])", text, re.DOTALL)
        if match:
            return match.group(1).strip()
        raise ValueError(f"Failed to extract valid JSON: {str(e)}")

def build_agent(tools, chat_history: List = None):
    llm = get_llm(temperature=0.2)

    memory = ConversationBufferMemory(
        memory_key="chat_history",
        return_messages=True
    )

    if chat_history:
        for msg in chat_history:
            role = msg.get("role")
            content = msg.get("content")
            if role == "user":
                memory.chat_memory.add_user_message(content)
            elif role == "assistant":
                memory.chat_memory.add_ai_message(content)

    print("----------------------------")
    print(memory.chat_memory)
    agent_executor = initialize_agent(
        tools=tools,
        llm=llm,
        agent=AgentType.CHAT_CONVERSATIONAL_REACT_DESCRIPTION,
        handle_parsing_errors=True,
        memory=None,
        verbose=True
    )
    return agent_executor

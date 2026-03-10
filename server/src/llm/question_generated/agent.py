import os
import json
import re
from typing import List, Literal
from pydantic import BaseModel, Field
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_classic.agents import initialize_agent
from langchain_classic.agents.agent_types import AgentType
from langchain_classic.memory import ConversationBufferMemory

load_dotenv()

class QuestionCandidate(BaseModel):
    id: int | None = Field(default=None, description="Database id after saving")
    interview_question: str = Field(..., description="The interview question")
    expected_answer: List[str] = Field(..., description="Array of 3 specific answer points we expect from the user")
    competency: str = Field(..., description="The competency being evaluated")
    difficulty: Literal["easy", "medium", "hard"] = Field(..., description="Difficulty level")
    why_this_question: str = Field(..., description="Reason for asking this question")

class QuestionCandidates(BaseModel):
    questions: List[QuestionCandidate]

class LLMConfigurationError(RuntimeError):
    pass


def _get_llm_config() -> dict:
    typhoon_api_key = os.getenv("TYPHOON_API_KEY") or os.getenv("TYPHOON_KEY")
    if typhoon_api_key:
        return {
            "api_key": typhoon_api_key,
            "base_url": os.getenv("TYPHOON_BASE_URL") or "https://api.opentyphoon.ai/v1",
            "model": os.getenv("TYPHOON_MODEL") or "typhoon-v2.5-30b-a3b-instruct",
        }

    llm_api_key = os.getenv("LLM_API_KEY")
    llm_base_url = os.getenv("LLM_BASE_URL")
    llm_model = os.getenv("LLM_MODEL")

    if llm_api_key and llm_base_url and llm_model:
        return {
            "api_key": llm_api_key,
            "base_url": llm_base_url,
            "model": llm_model,
        }

    raise LLMConfigurationError(
        "LLM is not configured. Set TYPHOON_API_KEY/TYPHOON_KEY or configure LLM_API_KEY, LLM_BASE_URL, and LLM_MODEL."
    )


def get_llm(temperature=0.2):
    config = _get_llm_config()

    return ChatOpenAI(
        base_url=config["base_url"],
        model=config["model"],
        api_key=config["api_key"],
        temperature=temperature,
        max_tokens=8192,
    )

def extract_json_text(raw_text: str) -> str:
    text = raw_text.strip()

    try:
        json.loads(text, strict=False)
        return text
    except Exception:
        pass

    fenced = re.search(r"```(?:json)?\s*(.*?)\s*```", text, re.DOTALL)
    if fenced:
        inner_text = fenced.group(1).strip()
        try:
            json.loads(inner_text, strict=False)
            return inner_text
        except Exception:
            text = inner_text

    first_dict = text.find('{')
    first_list = text.find('[')

    start_index = -1
    if first_dict != -1 and (first_list == -1 or first_dict < first_list):
        start_index = first_dict
    elif first_list != -1:
        start_index = first_list

    if start_index == -1:
        raise ValueError("No '{' or '[' found in LLM output")

    trimmed_text = text[start_index:]
    # Note: JSONDecoder doesn't take 'strict' in constructor, but raw_decode handles it if we pass a custom decoder or just allow it in the loads final check.
    # Actually, standard JSONDecoder.raw_decode doesn't easily support strict=False for the internal string parsing.
    # But we can use json.loads(trimmed_text[:end_index], strict=False) later.
    
    decoder = json.JSONDecoder()
    try:
        obj, end_index = decoder.raw_decode(trimmed_text)
        json_candidate = trimmed_text[:end_index].strip()
        # Verify with strict=False
        json.loads(json_candidate, strict=False)
        return json_candidate
    except Exception as e:
        match = re.search(r"(\{.*\}|\[.*\])", text, re.DOTALL)
        if match:
            candidate = match.group(1).strip()
            try:
                json.loads(candidate, strict=False)
                return candidate
            except Exception:
                pass
        raise ValueError(f"Failed to extract valid JSON: {str(e)}")

def build_agent(tools):
    llm = get_llm(temperature=0.2)

    agent_executor = initialize_agent(
        tools=tools,
        llm=llm,
        agent=AgentType.CHAT_CONVERSATIONAL_REACT_DESCRIPTION,
        handle_parsing_errors=True,
        verbose=True
    )
    return agent_executor

import json
import os
import re
from typing import List, Literal

from dotenv import load_dotenv
from langchain_classic.agents import initialize_agent
from langchain_classic.agents.agent_types import AgentType
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field

load_dotenv()


class SummaryPoint(BaseModel):
    title: str = Field(..., description="Short Thai summary title")
    evidence: str = Field(..., description="Specific supporting evidence in Thai")


class SummaryEvidence(BaseModel):
    experience: str = Field(..., description="Thai evidence for experience score")
    communication: str = Field(..., description="Thai evidence for communication score")
    technical: str = Field(..., description="Thai evidence for technical score")


class InterviewSummaryModel(BaseModel):
    total_score: float = Field(
        ...,
        description="Overall score from 0 to 1, averaged from the category scores",
    )
    experience_score: float = Field(..., description="Experience score from 0 to 1")
    communication_score: float = Field(..., description="Communication score from 0 to 1")
    technical_score: float = Field(..., description="Technical score from 0 to 1")
    recommendation: Literal["hire", "hold", "no_hire"] = Field(
        ...,
        description="Final recommendation",
    )
    confidence: float = Field(..., description="Confidence in the summary from 0 to 1")
    strengths: List[SummaryPoint] = Field(..., description="Key candidate strengths")
    weaknesses: List[SummaryPoint] = Field(..., description="Key candidate weaknesses")
    red_flags: List[str] = Field(..., description="Critical risk items")
    evidence: SummaryEvidence = Field(..., description="Per-skill evidence summary")
    suggestion_summary: str = Field(..., description="Thai final summary for HR")
    next_step: str = Field(..., description="Thai recommended next step")


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
        "LLM is not configured. Set TYPHOON_API_KEY/TYPHOON_KEY or configure "
        "LLM_API_KEY, LLM_BASE_URL, and LLM_MODEL."
    )


def get_llm(temperature: float = 0.2):
    config = _get_llm_config()
    return ChatOpenAI(
        base_url=config["base_url"],
        model=config["model"],
        api_key=config["api_key"],
        temperature=temperature,
        max_tokens=8192,
    )


def extract_json_text(raw_text: str) -> str:
    text = (raw_text or "").strip()

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

    first_dict = text.find("{")
    if first_dict == -1:
        raise ValueError("No '{' found in LLM output")

    decoder = json.JSONDecoder()
    trimmed_text = text[first_dict:]
    try:
        _, end_index = decoder.raw_decode(trimmed_text)
        json_candidate = trimmed_text[:end_index].strip()
        json.loads(json_candidate, strict=False)
        return json_candidate
    except Exception as exc:
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if match:
            candidate = match.group(0).strip()
            json.loads(candidate, strict=False)
            return candidate
        raise ValueError(f"Failed to extract valid JSON: {exc}") from exc


def build_agent(tools):
    llm = get_llm(temperature=0.2)
    return initialize_agent(
        tools=tools,
        llm=llm,
        agent=AgentType.CHAT_CONVERSATIONAL_REACT_DESCRIPTION,
        handle_parsing_errors=True,
        verbose=False,
    )

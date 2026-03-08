import os
import sys
import json
import re
from typing import Type, TypeVar, get_args, get_origin
from langchain_core.output_parsers import StrOutputParser , JsonOutputParser

# Add the 'src' directory to the Python path to allow imports when running directly
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from langchain_openai import ChatOpenAI
from langchain_community.document_loaders import PyPDFLoader
from pydantic import BaseModel
from schemas.resume_schema import ResumeResult

def build_schema_from_model(model_cls: type[BaseModel]) -> dict:
    result = {}

    for field_name, field_info in model_cls.model_fields.items():
        annotation = field_info.annotation
        origin = get_origin(annotation)
        args = get_args(annotation)

        if origin is list:
            inner = args[0] if args else str

            if isinstance(inner, type) and issubclass(inner, BaseModel):
                result[field_name] = [build_schema_from_model(inner)]
            elif inner is str:
                result[field_name] = ["String"]
            elif inner is int:
                result[field_name] = [0]
            elif inner is float:
                result[field_name] = [0.0]
            elif inner is bool:
                result[field_name] = [False]
            else:
                result[field_name] = ["Any"]

        elif isinstance(annotation, type) and issubclass(annotation, BaseModel):
            result[field_name] = build_schema_from_model(annotation)
            
        elif annotation is str:
            result[field_name] = "String"
        elif annotation is int:
            result[field_name] = 0
        elif annotation is float:
            result[field_name] = 0.0
        elif annotation is bool:
            result[field_name] = False
        else:
            result[field_name] = "Any"

    return result


def model_to_prompt_string(model_cls: type[BaseModel]) -> str:
    schema = build_schema_from_model(model_cls)
    return json.dumps(schema, ensure_ascii=False, indent=2)


def extract_text_from_pdf(pdf_name: str) -> str:
    current_dir = os.path.dirname(os.path.abspath(__file__))
    pdf_path = os.path.abspath(os.path.join(current_dir, "..", "..", "uploads", f"{pdf_name}.pdf"))

    loader = PyPDFLoader(pdf_path)
    docs = loader.load()

    texts = []
    for doc in docs:
        page_text = (doc.page_content or "").strip()
        if page_text:
            texts.append(page_text)

    return "\n\n".join(texts).strip()



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


T = TypeVar("T", bound=BaseModel)
def clean_and_parse_json(raw_text: str, model_cls: Type[T]) -> dict:
    try:
        json_text = extract_json_text(raw_text)
        raw_data = json.loads(json_text)

        validated = model_cls.model_validate(raw_data)
        return validated.model_dump()

    except ValidationError as e:
        print("Validation Error:")
        print(e)
        return {}

    except Exception as e:
        print(f"Extraction Error: {e}")
        return {}


def llm_generate_to_json(prompt_template: str) -> dict:
    from dotenv import load_dotenv
    load_dotenv()

    llm_api_key = os.getenv("LLM_API_KEY")
    llm_base_url = os.getenv("LLM_BASE_URL")
    llm_model = os.getenv("LLM_MODEL")

    if not llm_api_key or not llm_base_url or not llm_model:
        print("NOT SET ENV LLM")
        return {}

    llm = ChatOpenAI(
        base_url=llm_base_url,
        model=llm_model,
        api_key=llm_api_key,
        temperature=0.0,
        max_tokens=8192
    )

    try:
        response = llm.invoke(prompt_template)
        raw_output = response.content

        parsed_data = clean_and_parse_json(raw_output, ResumeResult)

        return parsed_data

    except Exception as e:
        print(f"LLM Error: {e}")
        return {}

def llm_generate_to_string(prompt_template: str) -> dict:
    from dotenv import load_dotenv
    load_dotenv()

    llm_api_key = os.getenv("LLM_API_KEY")
    llm_base_url = os.getenv("LLM_BASE_URL")
    llm_model = os.getenv("LLM_MODEL")

    if not llm_api_key or not llm_base_url or not llm_model:
        print("NOT SET ENV LLM")
        return {}

    llm = ChatOpenAI(
        base_url=llm_base_url,
        model=llm_model,
        api_key=llm_api_key,
        temperature=0.0,
        max_tokens=8192
    )

    parser = StrOutputParser()

    try:
        response = llm.invoke(prompt_template)
        result = parser .invoke(response)

        return result

    except Exception as e:
        print(f"LLM Error: {e}")
        return {}
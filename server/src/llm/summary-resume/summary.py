# pip install -U langchain langchain-openai langchain-community pypdf python-dotenv

import os
import json
import re
from typing import List, Type, TypeVar, get_args, get_origin

from dotenv import load_dotenv
from pydantic import BaseModel, Field, ConfigDict, AliasChoices, ValidationError
from langchain_openai import ChatOpenAI
from langchain_community.document_loaders import PyPDFLoader

load_dotenv()

# =========================================================
# 1) Base Model
# =========================================================

class AppBaseModel(BaseModel):
    # extra="ignore" = ถ้า LLM ตอบ field เกินมา จะตัดทิ้งอัตโนมัติ
    model_config = ConfigDict(
        extra="ignore",
        populate_by_name=True
    )


# =========================================================
# 2) Pydantic Models
# =========================================================

class EducationItem(AppBaseModel):
    institution: str = Field(..., description="University / School name")
    degree: str = Field(..., description="Degree or Certificate")
    faculty: str = Field("", description="Faculty")
    major: str = Field("", description="Major")
    gpax: float = Field(0.0, description="GPAX as float")
    start_month: int = Field(0, description="Start month")
    start_year: int = Field(0, description="Start year")
    end_month: int = Field(0, description="End month")
    end_year: int = Field(0, description="End year")


class ExperienceItem(AppBaseModel):
    company: str = Field(..., description="Company or Organization")
    role: str = Field(..., description="Job role")
    start_month: int = Field(0, description="Start month")
    start_year: int = Field(0, description="Start year")
    end_month: int = Field(0, description="End month")
    end_year: int = Field(0, description="End year")
    description: str = Field("", description="Work description")


class ProjectItem(AppBaseModel):
    title: str = Field(..., description="Project name")
    description: str = Field("", description="Brief project description")


class ResumeResult(AppBaseModel):
    analysis: str = Field(..., description="Thai evaluation of the candidate's core strengths.")
    full_name: str = Field(
        ...,
        description="Full Name",
        validation_alias=AliasChoices("full_name", "name")
    )
    age: int = Field(0, description="Age")
    phone: str = Field("", description="Phone number")
    email: str = Field("", description="Email")
    address: str = Field("", description="Address")
    skills: List[str] = Field(default_factory=list, description="A flat list of technology names.")
    education: List[EducationItem] = Field(default_factory=list)
    experience: List[ExperienceItem] = Field(default_factory=list)
    projects: List[ProjectItem] = Field(default_factory=list)


# =========================================================
# 3) Model -> Prompt Schema
# =========================================================

def build_schema_from_model(model_cls: type[BaseModel]) -> dict:
    """
    แปลง Pydantic model เป็น JSON template สำหรับใส่ใน prompt
    รองรับ nested model และ list ของ model
    """
    result = {}

    for field_name, field_info in model_cls.model_fields.items():
        annotation = field_info.annotation
        origin = get_origin(annotation)
        args = get_args(annotation)

        # List[T]
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

        # Nested BaseModel
        elif isinstance(annotation, type) and issubclass(annotation, BaseModel):
            result[field_name] = build_schema_from_model(annotation)

        # Primitive
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
    """
    คืนค่า schema เป็น string JSON สำหรับใส่ลง prompt ได้ทันที
    """
    schema = build_schema_from_model(model_cls)
    return json.dumps(schema, ensure_ascii=False, indent=2)


# =========================================================
# 4) PDF Text Loader
# =========================================================

def extract_text_from_pdf(pdf_path: str) -> str:
    """
    อ่าน text จาก PDF โดยตรงด้วย PyPDFLoader
    """
    loader = PyPDFLoader(pdf_path)
    docs = loader.load()

    texts = []
    for doc in docs:
        page_text = (doc.page_content or "").strip()
        if page_text:
            texts.append(page_text)

    return "\n\n".join(texts).strip()


# =========================================================
# 5) Generic JSON Extraction + Model Validation
# =========================================================

T = TypeVar("T", bound=BaseModel)


def extract_json_text(raw_text: str) -> str:
    """
    ดึง JSON string ออกจาก LLM output
    รองรับทั้ง:
    - JSON ตรง ๆ
    - ```json ... ```
    - ข้อความที่มี JSON ปนอยู่
    """
    text = raw_text.strip()

    # 1) ลอง parse ตรง ๆ ก่อน
    try:
        json.loads(text)
        return text
    except Exception:
        pass

    # 2) ถ้าอยู่ใน markdown fence
    fenced = re.search(r"```(?:json)?\s*(\{.*\}|\[.*\])\s*```", text, re.DOTALL)
    if fenced:
        return fenced.group(1).strip()

    # 3) fallback: ดึงก้อน JSON ก้อนแรก
    match = re.search(r"(\{.*\}|\[.*\])", text, re.DOTALL)
    if match:
        return match.group(1).strip()

    raise ValueError("No JSON object found in LLM output")


def clean_and_parse_json(raw_text: str, model_cls: Type[T]) -> dict:
    """
    parser แบบ model-driven:
    - ไม่ hardcode field เฉพาะทาง
    - ทุกอย่างอิงจาก model ที่ส่งเข้ามา
    """
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


# =========================================================
# 6) Main Resume Extraction Logic
# =========================================================

def summarize_pdf_to_json(pdf_path: str) -> dict:
    print(f"Processing PDF: {pdf_path}")

    api_key = os.getenv("TYPHOON_KEY")
    if not api_key:
        print("Error: TYPHOON_KEY not found in environment variables.")
        return ResumeResult(
            analysis="ไม่สามารถประมวลผลได้ เนื่องจากไม่พบ TYPHOON_KEY",
            full_name="Error during processing"
        ).model_dump()

    # อ่าน text จาก PDF
    resume_text = extract_text_from_pdf(pdf_path)
    if not resume_text:
        print("Error: Failed to extract text from PDF.")
        return ResumeResult(
            analysis="ไม่สามารถอ่านข้อความจาก PDF ได้",
            full_name="Error during processing"
        ).model_dump()

    # กันข้อความยาวเกิน
    resume_text = resume_text[:25000]

    print("\n=== Extracted Resume Text ===")
    print(resume_text)

    llm = ChatOpenAI(
        base_url="https://api.opentyphoon.ai/v1",
        model="typhoon-v2.5-30b-a3b-instruct",
        api_key=api_key,
        temperature=0.0,
        max_tokens=8192
    )

    schema_str = model_to_prompt_string(ResumeResult)

    prompt = f"""
Extract precise candidate data from the resume text and return ONLY raw JSON.

REQUIRED JSON STRUCTURE:
{schema_str}

IMPORTANT RULES:
1. Output ONLY valid raw JSON.
2. Use EXACT field names from the structure.
3. `analysis` MUST be written in Thai language only.
4. `skills` must be a flat array of strings only.
5. Each item in `projects` must contain ONLY:
   - `title`
   - `description`

STRICT CLASSIFICATION RULES:
6. `experience` = only formal employment, official internship, assistantship, cooperative education, or long-term role in a real company / institution / organization.
7. `projects` = personal projects, freelance-style projects, academic projects, thesis/capstone, experiments, competition systems, side projects, startup ideas, self-initiated builds.
8. If an item is a built system/product and NOT clearly a formal paid company job or official internship, put it in `projects`, NOT in `experience`.
9. Do NOT duplicate the same item in both `experience` and `projects`.

MISSING VALUE RULES:
10. If age is not explicitly stated, use 0.
11. If address is not explicitly stated, use "".
12. If any month/year is unknown, use 0.

ANALYSIS RULE:
13. `analysis` should be concise Thai text summarizing the candidate's profile, strengths, and suitability.

RESUME TEXT:
{resume_text}
"""

    try:
        response = llm.invoke(prompt)
        raw_output = response.content

        print("\n=== Raw LLM Output ===")
        print(raw_output)

        parsed_data = clean_and_parse_json(raw_output, ResumeResult)

        if not parsed_data:
            return ResumeResult(
                analysis="ไม่สามารถแปลงผลลัพธ์จากโมเดลให้อยู่ในรูปแบบที่ถูกต้องได้",
                full_name="Error during processing"
            ).model_dump()

        return parsed_data

    except Exception as e:
        print(f"LLM Error: {e}")
        return ResumeResult(
            analysis=f"เกิดข้อผิดพลาดระหว่างประมวลผล: {str(e)}",
            full_name="Error during processing"
        ).model_dump()


# =========================================================
# 7) Run
# =========================================================

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))

    # เปลี่ยนชื่อไฟล์ตรงนี้ตามไฟล์จริงของคุณ
    pdf_path = os.path.join(current_dir, "CV_NUTCHANON.pdf")

    if os.path.exists(pdf_path):
        result = summarize_pdf_to_json(pdf_path)

        print("\n--- Final Structured Result ---")
        print(json.dumps(result, ensure_ascii=False, indent=2))

        output_path = os.path.join(current_dir, "summary.json")
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(result, f, ensure_ascii=False, indent=2)

        print(f"\nSaved results to {output_path}")
    else:
        print(f"File not found: {pdf_path}")
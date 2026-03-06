# pip install -U langchain langchain-openai langchain-community pypdf python-dotenv
import os
import json
import re
from typing import List, Optional, Dict
from pydantic import BaseModel, Field
from dotenv import load_dotenv

from langchain_community.document_loaders import PyPDFLoader
from langchain_openai import ChatOpenAI

load_dotenv()

# -----------------------------
# 1) Define Schema
# -----------------------------

class EducationItem(BaseModel):
    institution: str = Field(..., description="University / School name")
    degree: str = Field(..., description="Degree or Certificate")
    faculty: str = Field("", description="Faculty")
    major: str = Field("", description="Major")
    gpax: float = Field(0.0, description="GPAX as float")
    start_month: int = Field(0, description="Start month")
    start_year: int = Field(0, description="Start year")
    end_month: int = Field(0, description="End month")
    end_year: int = Field(0, description="End year")

class ExperienceItem(BaseModel):
    company: str = Field(..., description="Company or Organization")
    role: str = Field(..., description="Job role")
    start_month: int = Field(0, description="Start month")
    start_year: int = Field(0, description="Start year")
    end_month: int = Field(0, description="End month")
    end_year: int = Field(0, description="End year")
    description: str = Field("", description="Work description")

class ProjectItem(BaseModel):
    title: str = Field(..., description="Project name")
    description: str = Field("", description="Brief project description")

class ResumeResult(BaseModel):
    analysis: str = Field(..., description="Thai evaluation of the candidate's core strengths.")
    full_name: str = Field(..., description="Full Name")
    age: int = Field(0, description="Age")
    phone: str = Field("", description="Phone number")
    email: str = Field("", description="Email")
    address: str = Field("", description="Address")
    skills: List[str] = Field(default_factory=list, description="A flat list of technology names.")
    education: List[EducationItem] = Field(default_factory=list)
    experience: List[ExperienceItem] = Field(default_factory=list)
    projects: List[ProjectItem] = Field(default_factory=list)

# -----------------------------
# 2) Robust Parser
# -----------------------------

def clean_and_parse_json(raw_text: str) -> dict:
    """Robustly extracts JSON from LLM output across various formats."""
    try:
        text = raw_text.strip()
        
        # 1. Try to find JSON block using regex
        match = re.search(r'(\{.*\})', text, re.DOTALL)
        if match:
            text = match.group(1)
        
        # 2. Basic cleaning
        text = text.replace('```json', '').replace('```', '').strip()
        
        data = json.loads(text)
        
        # 3. Handle common field name drift (e.g. 'name' vs 'full_name')
        if "name" in data and "full_name" not in data:
            data["full_name"] = data["name"]
            
        # 4. Handle nested dicts in skills
        if isinstance(data.get("skills"), dict):
            flat_skills = []
            for val in data.get("skills").values():
                if isinstance(val, list):
                    flat_skills.extend([str(item) for item in val])
                else:
                    flat_skills.append(str(val))
            data["skills"] = list(set(flat_skills))
        
        # 5. Fix projects skills if LLM mistakenly included them
        if "projects" in data and isinstance(data["projects"], list):
            for p in data["projects"]:
                if "skills" in p:
                    # Just remove it to follow the current ProjectItem schema
                    del p["skills"]
        
        return data
    except Exception as e:
        print(f"Extraction Error: {e}")
        return {}

# -----------------------------
# 3) Extraction Logic
# -----------------------------

def summarize_pdf_to_json(pdf_path: str) -> Dict:
    print(f"Processing PDF: {pdf_path}")
    
    loader = PyPDFLoader(pdf_path)
    docs = loader.load()
    resume_text = "\n\n".join(doc.page_content for doc in docs)
    resume_text = resume_text[:20000]
    
    llm = ChatOpenAI(
        base_url='https://api.opentyphoon.ai/v1',
        model="typhoon-v2.5-30b-a3b-instruct",
        api_key=os.getenv('TYPHOON_KEY'),
        temperature=0.0,
        max_tokens=8192
    )

    prompt = f"""Extract precise candidate data from the resume text into a raw JSON format.

### REQUIRED SCHEMA:
(Use these EXACT field names)
{{
  "analysis": "Thai text analysis of candidate's strengths",
  "full_name": "Full Name",
  "age": 0,
  "phone": "String",
  "email": "String",
  "address": "String",
  "skills": ["List of strings"],
  "education": [{{ "institution": "...", "degree": "...", "gpax": 0.0, "start_month": 0, "start_year": 0, "end_month": 0, "end_year": 0 }}],
  "experience": [{{ "company": "...", "role": "...", "start_month": 0, "start_year": 0, "end_month": 0, "end_year": 0, "description": "..." }}],
  "projects": [{{ "title": "...", "description": "..." }}]
}}

### IMPORTANT RULES:
1. **NO CATEGORIZATION**: Return 'skills' as a flat array of strings ONLY.
2. **NO PROJECT SKILLS**: Each project in 'projects' MUST have ONLY 'title' and 'description'.
3. **EXPERIENCE VS PROJECTS**:
    - `experience`: Professional employment, formal internships, or long-term roles at established companies/organizations.
    - `projects`: Personal projects, university/academic projects, open-source work, or side projects.
    - **NO DUPLICATION**: Do not list the same item in both categories. If an entry is primarily a development project (e.g., "Smart Q" or "Forex Robot"), place it ONLY in `projects`.
4. **ONLY RAW JSON**: Do not include any other text or markdown blocks.

### RESUME TEXT:
{resume_text}
"""

    try:
        response = llm.invoke(prompt)
        parsed_data = clean_and_parse_json(response.content)
        
        try:
            validated_result = ResumeResult.model_validate(parsed_data)
            return validated_result.model_dump()
        except Exception as e:
            print(f"Validation Error: {e}")
            # Return what we have parsed if validation fails, filling with defaults from ResumeResult()
            return ResumeResult(**parsed_data).model_dump()
            
    except Exception as e:
        print(f"LLM/Parsing Error: {e}")
        return ResumeResult(
            analysis=f"Critical Failure: {str(e)}",
            full_name="Error during processing"
        ).model_dump()

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    pdf_path = os.path.join(current_dir, "CV-Nutchanon_Sapmeechai (1).pdf")
    
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

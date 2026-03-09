from sqlalchemy.orm import Session
from sqlalchemy import text
from src.llm.question_generated.agent import build_agent, extract_json_text, QuestionCandidates, get_llm
from src.llm.question_generated.tools import build_tools
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
import json
import re

VALID_DIFFICULTIES = {"easy", "medium", "hard"}

INTERVIEW_QUESTION_LABEL = re.compile(
    r"^(?:interview question|question|คำถามสัมภาษณ์)\s*:?\s*(.*)$",
    re.IGNORECASE,
)
EXPECTED_ANSWER_LABEL = re.compile(
    r"^(?:expected answer(?:s)?|คำตอบที่คาดหวัง)\s*:?\s*(.*)$",
    re.IGNORECASE,
)
COMPETENCY_LABEL = re.compile(
    r"^(?:competency|สมรรถนะ|ทักษะที่ประเมิน)\s*:?\s*(.*)$",
    re.IGNORECASE,
)
DIFFICULTY_LABEL = re.compile(
    r"^(?:difficulty|ระดับความยาก)\s*:?\s*(.*)$",
    re.IGNORECASE,
)
WHY_THIS_QUESTION_LABEL = re.compile(
    r"^(?:why this question|เหตุผล(?:ที่ถาม)?|เหตุผลของคำถาม)\s*:?\s*(.*)$",
    re.IGNORECASE,
)
PLAIN_TEXT_PREAMBLE = (
    "based on",
    "here are",
    "below are",
    "the following",
    "following are",
    "these are",
    "ต่อไปนี้",
    "คำถามต่อไปนี้",
    "ด้านล่างนี้",
    "จากรายละเอียด",
    "จากข้อมูล",
    "นี่คือ",
)


def _contains_thai(text: str) -> bool:
    return any("\u0E00" <= char <= "\u0E7F" for char in text or "")


def _default_expected_answers(use_thai: bool) -> list[str]:
    if use_thai:
        return [
            "อธิบายบริบทงานจริงหรือปัญหาที่ต้องแก้",
            "อธิบายวิธีตัดสินใจหรือแนวทางที่นำไปใช้จริง",
            "อธิบายผลลัพธ์ ข้อจำกัด หรือสิ่งที่ได้เรียนรู้",
        ]

    return [
        "Explain the real project context or problem being solved.",
        "Explain the practical approach or decision-making used.",
        "Explain the outcome, tradeoffs, or lessons learned.",
    ]


def _normalize_expected_answers(value, use_thai: bool) -> list[str]:
    cleaned = []

    if isinstance(value, list):
        cleaned = [str(item).strip() for item in value if str(item).strip()]
    elif isinstance(value, str) and value.strip():
        cleaned = [value.strip()]

    defaults = _default_expected_answers(use_thai)
    if len(cleaned) >= 3:
        return cleaned[:3]

    return cleaned + defaults[len(cleaned):3]


def _normalize_difficulty(value, fallback: str = "medium") -> str:
    aliases = {
        "easy": "easy",
        "ง่าย": "easy",
        "ปานกลาง": "medium",
        "medium": "medium",
        "hard": "hard",
        "ยาก": "hard",
    }

    fallback_value = aliases.get(str(fallback).strip().lower(), "medium")
    normalized = aliases.get(str(value).strip().lower())
    if normalized in VALID_DIFFICULTIES:
        return normalized

    return fallback_value


def _truncate_text(text: str, limit: int = 140) -> str:
    compact = " ".join((text or "").split())
    if len(compact) <= limit:
        return compact
    return compact[: limit - 3].rstrip() + "..."


def _default_competency(use_thai: bool) -> str:
    return "ประสบการณ์ที่เกี่ยวข้อง" if use_thai else "Relevant Experience"


def _default_reason(hr_prompt: str, use_thai: bool) -> str:
    prompt = _truncate_text(hr_prompt)
    if use_thai:
        if prompt:
            return f"สอดคล้องกับคำขอของ HR ที่ต้องการประเมินเรื่อง {prompt}"
        return "สอดคล้องกับคำขอของ HR และบริบทการสัมภาษณ์"

    if prompt:
        return f"Matches the HR request focused on {prompt}"
    return "Matches the HR request and interview context"


def _append_text(existing: str | None, addition: str) -> str:
    addition = (addition or "").strip()
    if not addition:
        return existing or ""
    if not existing:
        return addition
    return f"{existing} {addition}".strip()


def _strip_markdown(text: str) -> str:
    return (
        (text or "")
        .replace("**", "")
        .replace("__", "")
        .replace("`", "")
        .strip()
    )


def _strip_list_prefix(text: str) -> str:
    return re.sub(r"^(?:[-*•]\s+|\d+[.)]\s+)", "", text or "").strip()


def _normalize_inline_whitespace(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").strip()).strip()


def _matches_field_label(text: str) -> bool:
    line = _strip_markdown(text or "")
    return any(
        pattern.match(line)
        for pattern in (
            INTERVIEW_QUESTION_LABEL,
            EXPECTED_ANSWER_LABEL,
            COMPETENCY_LABEL,
            DIFFICULTY_LABEL,
            WHY_THIS_QUESTION_LABEL,
        )
    )


def _is_plain_text_preamble(text: str) -> bool:
    normalized = _normalize_inline_whitespace(_strip_list_prefix(text)).lower()
    return any(normalized.startswith(prefix) for prefix in PLAIN_TEXT_PREAMBLE)


def _is_candidate_question_text(text: str) -> bool:
    cleaned = _normalize_inline_whitespace(_strip_list_prefix(_strip_markdown(text)))
    if len(cleaned) < 20:
        return False
    if _matches_field_label(cleaned):
        return False
    if _is_plain_text_preamble(cleaned):
        return False
    return True


def _split_structured_question_blocks(raw_text: str) -> list[str]:
    pattern = re.compile(
        r"(?m)^\s*(?:\d+\.\s*)?(?:\*\*)?(?:interview question|question|คำถามสัมภาษณ์)\b",
        re.IGNORECASE,
    )
    matches = list(pattern.finditer(raw_text or ""))
    if not matches:
        return []

    blocks = []
    for index, match in enumerate(matches):
        start = match.start()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(raw_text)
        block = raw_text[start:end].strip()
        if block:
            blocks.append(block)
    return blocks


def _parse_structured_question_output(raw_text: str) -> dict:
    blocks = _split_structured_question_blocks(raw_text)
    if not blocks:
        raise ValueError("LLM returned an unsupported response format.")

    questions = []
    for block in blocks[:3]:
        item = {"expected_answer": []}
        current_field = None

        for raw_line in block.splitlines():
            line = _strip_markdown(raw_line.strip())
            line = re.sub(r"^\s*(?:\d+\.\s+|question\s+\d+\s*:)", "", line, flags=re.IGNORECASE)
            line = line.strip()
            if not line:
                continue

            field_matchers = [
                ("interview_question", INTERVIEW_QUESTION_LABEL),
                ("expected_answer", EXPECTED_ANSWER_LABEL),
                ("competency", COMPETENCY_LABEL),
                ("difficulty", DIFFICULTY_LABEL),
                ("why_this_question", WHY_THIS_QUESTION_LABEL),
            ]

            matched_field = False
            for field_name, pattern in field_matchers:
                matched = pattern.match(line)
                if not matched:
                    continue

                value = matched.group(1).strip()
                current_field = field_name

                if field_name == "expected_answer":
                    cleaned_value = _strip_list_prefix(value)
                    if cleaned_value:
                        item["expected_answer"].append(cleaned_value)
                elif field_name == "difficulty":
                    item[field_name] = value
                else:
                    item[field_name] = _append_text(item.get(field_name), value)

                matched_field = True
                break

            if matched_field:
                continue

            if current_field == "expected_answer":
                cleaned_value = _strip_list_prefix(line)
                if cleaned_value:
                    item["expected_answer"].append(cleaned_value)
            elif current_field in {"interview_question", "competency", "why_this_question"}:
                item[current_field] = _append_text(item.get(current_field), line)
            elif not item.get("interview_question"):
                item["interview_question"] = line
                current_field = "interview_question"

        if item.get("interview_question"):
            questions.append(item)

    if not questions:
        raise ValueError("LLM returned no usable interview questions.")

    return {"questions": questions}


def _parse_plain_question_output(raw_text: str) -> dict:
    paragraphs = [
        _normalize_inline_whitespace(_strip_list_prefix(_strip_markdown(block)))
        for block in re.split(r"\n\s*\n+", raw_text or "")
    ]
    paragraphs = [block for block in paragraphs if _is_candidate_question_text(block)]

    if len(paragraphs) >= 2:
        return {
            "questions": [
                {"interview_question": question_text}
                for question_text in paragraphs[:3]
            ]
        }

    lines = [
        _normalize_inline_whitespace(_strip_list_prefix(_strip_markdown(line)))
        for line in (raw_text or "").splitlines()
    ]
    lines = [line for line in lines if _is_candidate_question_text(line)]

    if len(lines) >= 2:
        return {
            "questions": [
                {"interview_question": question_text}
                for question_text in lines[:3]
            ]
        }

    raise ValueError("LLM returned an unsupported response format.")


def _parse_llm_question_response(raw_text: str, hr_prompt: str) -> dict:
    try:
        json_str = extract_json_text(raw_text)
        parsed_data = json.loads(json_str)
    except Exception:
        try:
            parsed_data = _parse_structured_question_output(raw_text)
        except ValueError:
            parsed_data = _parse_plain_question_output(raw_text)

    return _normalize_question_payload(parsed_data, hr_prompt)


def _normalize_question_payload(parsed_data, hr_prompt: str) -> dict:
    if isinstance(parsed_data, list):
        parsed_data = {"questions": parsed_data}

    if not isinstance(parsed_data, dict):
        raise ValueError("LLM returned an invalid question payload.")

    raw_questions = parsed_data.get("questions")
    if not isinstance(raw_questions, list):
        raise ValueError("LLM returned no valid questions list.")

    use_thai = _contains_thai(hr_prompt)
    fallback_difficulty = _normalize_difficulty(parsed_data.get("difficulty"))
    fallback_competency = str(
        parsed_data.get("competency") or _default_competency(use_thai)
    ).strip() or _default_competency(use_thai)
    fallback_reason = _default_reason(hr_prompt, use_thai)

    normalized_questions = []
    for item in raw_questions[:3]:
        if not isinstance(item, dict):
            continue

        interview_question = str(
            item.get("interview_question") or item.get("question") or ""
        ).strip()
        if not interview_question:
            continue

        normalized_questions.append(
            {
                "interview_question": interview_question,
                "expected_answer": _normalize_expected_answers(
                    item.get("expected_answer"), use_thai
                ),
                "competency": str(
                    item.get("competency") or fallback_competency
                ).strip() or fallback_competency,
                "difficulty": _normalize_difficulty(
                    item.get("difficulty"), fallback_difficulty
                ),
                "why_this_question": str(
                    item.get("why_this_question") or fallback_reason
                ).strip() or fallback_reason,
            }
        )

    if not normalized_questions:
        raise ValueError("LLM returned no usable interview questions.")

    return {"questions": normalized_questions}


def _needs_language_alignment(question_payload: dict, use_thai: bool) -> bool:
    questions = question_payload.get("questions", [])
    if not questions:
        return False

    text_fields = []
    for item in questions:
        text_fields.append(str(item.get("interview_question", "")).strip())
        text_fields.append(str(item.get("competency", "")).strip())
        text_fields.append(str(item.get("why_this_question", "")).strip())
        text_fields.extend(
            str(answer).strip() for answer in item.get("expected_answer", [])
        )

    if use_thai:
        return any(text and not _contains_thai(text) for text in text_fields)

    return any(_contains_thai(text) for text in text_fields)


def _align_question_payload_language(question_payload: dict, hr_prompt: str) -> dict:
    use_thai = _contains_thai(hr_prompt)
    if not _needs_language_alignment(question_payload, use_thai):
        return question_payload

    llm = get_llm(temperature=0.0)
    target_language = "Thai" if use_thai else "English"
    strict_language_rule = (
        "Every textual field must be Thai. Do not leave any question text in English."
        if use_thai
        else "Every textual field must be English. Do not leave any question text in Thai."
    )

    translation_prompt = f"""
You are a translation and formatting assistant for interview questions.

TARGET LANGUAGE:
{target_language}

HR REQUEST:
{hr_prompt}

TASK:
Rewrite the JSON payload below into the target language while preserving meaning.

RULES:
- {strict_language_rule}
- Keep the same number of questions.
- Keep each "expected_answer" as exactly 3 distinct points.
- Keep "difficulty" as only one of: easy, medium, hard.
- Preserve the practical intent of each question.
- Return ONLY valid JSON.

JSON PAYLOAD:
{json.dumps(question_payload, ensure_ascii=False)}
"""

    try:
        response = llm.invoke(translation_prompt)
        translated_text = response.content if hasattr(response, "content") else str(response)
        return _parse_llm_question_response(translated_text, hr_prompt)
    except Exception:
        return question_payload

def get_recent_messages(db: Session, interview_id: int, limit: int = 5) -> str:
    query = text("""
        SELECT message 
        FROM chat_histories 
        WHERE interview_id = :id 
        ORDER BY created_at DESC 
        LIMIT :limit
    """)
    rows = db.execute(query, {"id": interview_id, "limit": limit}).fetchall()
    if not rows:
        return "No recent messages."

    messages = [r.message for r in reversed(rows)]
    return "\n".join(messages)

def summarize_hr_style(db: Session, interview_id: int, new_prompt: str) -> str:
    query = text("SELECT hr_interest FROM interviews WHERE id = :id")
    row = db.execute(query, {"id": interview_id}).first()
    old_profile = row.hr_interest if row else ""

    llm = get_llm(temperature=0.2)

    prompt = ChatPromptTemplate.from_messages([
        ("system", """
You are an HR profile updater.

Strict rules:
- Never invent information
- Follow the rules exactly
- Return only the updated HR profile text
"""),

        ("human", """
New HR Request (PRIMARY SOURCE OF TRUTH):
{new_prompt}

Current HR Profile (Context Only – may be outdated):
{old_profile}

TASK:
Update the HR Profile using the New HR Request as the primary source.

RULES:
1. The New HR Request has higher priority than the Current HR Profile.
2. Remove any topic explicitly excluded in the New HR Request.
3. Only keep information from the Current HR Profile if it does NOT conflict.
4. If the New Request changes the focus, discard outdated instructions.
5. If the New Request says "clear", "reset", or "start over", ignore the old profile.
6. Keep the profile concise (MAX 3 sentences).
7. Each sentence must be under 25 words.
8. Do NOT invent roles, industries, technologies, or skills not mentioned.
9. NEVER introduce new concepts not present in the New HR Request.
10. Prefer the NEW request over preserving old details.
""")
    ])

    chain = prompt | llm | StrOutputParser()

    response = chain.invoke({
        "new_prompt": new_prompt,
        "old_profile": old_profile or "None"
    })

    summary = response.strip()

    update_query = text("UPDATE interviews SET hr_interest = :summary WHERE id = :id")
    db.execute(update_query, {"summary": summary, "id": interview_id})
    db.commit()

    return summary

def build_baseline_context(db: Session, interview_id: int) -> str:
    query = text("""
        SELECT i.context, i.candidate_profile_summary, i.job_profile_summary,
               i.candidate_strengths, i.candidate_gaps, i.hr_interest, i.difficulty
        FROM interviews i
        WHERE i.id = :id
    """)
    row = db.execute(query, {"id": interview_id}).first()
    if not row:
        return "Interview not found."

    return f"""
ROOM CONTEXT:
{row.context or "No room context."}

INTERVIEW DIFFICULTY (0.0=Entry, 0.5=Mid, 1.0=Expert):
{row.difficulty if row.difficulty is not None else 0.5}

HR INTERESTING (Use as weight for questions):
{row.hr_interest or "No specific HR interests noted."}

CANDIDATE STRENGTHS:
{row.candidate_strengths or "No strengths identified yet."}

CANDIDATE GAPS:
{row.candidate_gaps or "No gaps identified yet."}

RECENT MESSAGES:
{get_recent_messages(db, interview_id)}
""".strip()

def generate_interview_questions(
    db: Session,
    interview_id: int,
    hr_prompt: str,
):
    query = text("SELECT id FROM interviews WHERE id = :id")
    if not db.execute(query, {"id": interview_id}).first():
        raise LookupError("Interview not found")

    baseline_context = build_baseline_context(db, interview_id)
    hr_profile = summarize_hr_style(db, interview_id, hr_prompt)

    print("HR PROFILE:", hr_profile)
    
    # 3) Fetch previous questions specifically to prevent repetition in Agent Memory
    prev_q_query = text("""
        SELECT question FROM interview_questions 
        WHERE interview_id = :id 
        ORDER BY id DESC LIMIT 3
    """)
    prev_q_rows = db.execute(prev_q_query, {"id": interview_id}).fetchall()
    
    formatted_history = []
    # We add them as 'assistant' messages because these were the LLM's previous outputs
    for r in reversed(prev_q_rows):
        formatted_history.append({"role": "assistant", "content": f"Previously generated question: {r.question}"})

    tools = build_tools(db)
    current_prompt = f"""
You are an interview question generator.

PRIMARY INSTRUCTION (HIGHEST PRIORITY):
The CURRENT HR REQUEST is the main objective.
All generated questions MUST directly satisfy the HR REQUEST.

If any context, candidate information, or historical profile conflicts with the HR REQUEST, IGNORE it.

CONTEXT INFORMATION (LOW PRIORITY):
{baseline_context}

HR PROFILE (Historical Style – OPTIONAL):
{hr_profile}

CURRENT HR REQUEST (PRIMARY TASK):
{hr_prompt}

TASK:
Generate exactly 2–3 interview questions that directly satisfy the CURRENT HR REQUEST.

REASONING PROCESS:
1. Understand the HR REQUEST.
2. Ignore unrelated context.
3. Generate questions aligned ONLY with the HR REQUEST.

DEFAULT LANGUAGE:
All questions and explanations MUST be written in Thai unless the HR REQUEST is explicitly English.

RULES:
- Questions must clearly reflect the HR REQUEST.
- Do not introduce unrelated roles, skills, or industries.
- Avoid repeating previous questions.
- expected_answer must contain exactly 3 distinct points.
- Output language must match the HR REQUEST.
- If the HR REQUEST is in Thai, every text field must be Thai.
- If the HR REQUEST is in English, every text field must be English.
- "competency" and "why_this_question" must follow the same language as the HR REQUEST.
- Use the provided tools by passing the interview_id "{interview_id}" as a string when additional context is required.

OUTPUT FORMAT:
Return ONLY a valid JSON object.

{{
  "questions": [
    {{
      "interview_question": "String",
      "expected_answer": ["Point 1", "Point 2", "Point 3"],
      "competency": "String",
      "difficulty": "easy | medium | hard",
      "why_this_question": "Explain how it matches the HR REQUEST"
    }}
  ]
}}
"""

    agent = build_agent(tools)

    try:
        result = agent.run(current_prompt)
        parsed_data = _parse_llm_question_response(result, hr_prompt)
        parsed_data = _align_question_payload_language(parsed_data, hr_prompt)

        return QuestionCandidates.model_validate(parsed_data)
    except Exception as e:
        print("--- RAW LLM OUTPUT START ---")
        try:
            result = agent.invoke({
                "input": combined_prompt,
                "chat_history": []
            })
            json_str = extract_json_text(result["output"])
            parsed_data = json.loads(json_str, strict=False)

            if isinstance(parsed_data, list):
                parsed_data = {"questions": parsed_data}

            # This will raise ValidationError if JSON is incomplete
            return QuestionCandidates.model_validate(parsed_data)
            
        except Exception as e:
            attempt += 1
            feedback_msg = f"Error parsing JSON: {str(e)}\nRaw Output: {result if 'result' in locals() else 'No result'}"
            print(f"--- Attempt {attempt} failed ---")
            print(feedback_msg)
            if attempt > max_retries:
                print("--- FINAL FAILURE ---")
                raise e


def save_generated_questions(
    db: Session,
    interview_id: int,
    question_candidates,
):

    sql_insert = text("""
        INSERT INTO interview_questions (
            interview_id,
            question,
            expected_answer,
            user_answer,
            score,
            reason
        )
        VALUES (
            :interview_id,
            :question,
            :expected_answer,
            :user_answer,
            :score,
            :reason
        )
    """)

    for q in question_candidates.questions:

        db.execute(
            sql_insert,
            {
                "interview_id": interview_id,
                "question": q.interview_question,
                "expected_answer": q.expected_answer,
                "user_answer": None,
                "score": None,
                "reason": None,
            },
        )

    db.commit()

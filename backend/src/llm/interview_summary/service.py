import json

from sqlalchemy import text
from sqlalchemy.orm import Session

from src.llm.interview_summary.agent import (
    InterviewSummaryModel,
    extract_json_text,
    get_llm,
)
from src.llm.interview_summary.hr_extractor import process_unscored_hr_questions
from src.llm.interview_summary.tools import build_tools

PLACEHOLDER_SUMMARY_SIGNATURE = {
    "recommendation": "hold",
    "suggestion_summary": "ผู้สมัครมีศักยภาพและสื่อสารได้ดี แต่ควรมีการประเมินเชิงเทคนิคเพิ่มเติมก่อนตัดสินใจ",
    "next_step": "แนะนำให้มี technical interview รอบถัดไปโดยเน้น architecture และ debugging",
}


def _clamp_score(value, fallback: float = 0.0) -> float:
    try:
        score = float(value)
    except (TypeError, ValueError):
        score = fallback
    return max(0.0, min(1.0, round(score, 2)))


def _normalize_recommendation(value) -> str:
    normalized = str(value or "").strip().lower()
    aliases = {
        "hire": "hire",
        "strong_hire": "hire",
        "accept": "hire",
        "yes": "hire",
        "hold": "hold",
        "consider": "hold",
        "maybe": "hold",
        "no_hire": "no_hire",
        "reject": "no_hire",
        "no": "no_hire",
    }
    return aliases.get(normalized, "hold")


def _normalize_summary_points(value, fallback_prefix: str) -> list[dict]:
    points = []

    if isinstance(value, list):
        for index, item in enumerate(value, start=1):
            if isinstance(item, dict):
                title = str(item.get("title") or "").strip()
                raw_evidence = item.get("evidence")
                if isinstance(raw_evidence, dict):
                    evidence_parts = [
                        str(part).strip()
                        for part in raw_evidence.values()
                        if str(part).strip()
                    ]
                    evidence = " ".join(evidence_parts).strip()
                elif isinstance(raw_evidence, list):
                    evidence = " ".join(
                        str(part).strip() for part in raw_evidence if str(part).strip()
                    ).strip()
                else:
                    evidence = str(raw_evidence or "").strip()
            else:
                title = str(item).strip()
                evidence = ""

            if not title:
                continue

            points.append(
                {
                    "title": title,
                    "evidence": evidence or f"ไม่มีรายละเอียดเพิ่มเติมสำหรับ{title}",
                }
            )

    if points:
        return points

    return [
        {
            "title": f"{fallback_prefix} 1",
            "evidence": f"ยังไม่มีหลักฐานเพียงพอสำหรับการสรุป{fallback_prefix.lower()}อย่างชัดเจน",
        }
    ]


def _normalize_red_flags(value) -> list[str]:
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str) and value.strip():
        return [value.strip()]
    return []


def _normalize_evidence(value) -> dict:
    if isinstance(value, dict):
        return {
            "experience": str(value.get("experience") or "ยังมีข้อมูลไม่เพียงพอ").strip(),
            "communication": str(value.get("communication") or "ยังมีข้อมูลไม่เพียงพอ").strip(),
            "technical": str(value.get("technical") or "ยังมีข้อมูลไม่เพียงพอ").strip(),
        }

    return {
        "experience": "ยังมีข้อมูลไม่เพียงพอ",
        "communication": "ยังมีข้อมูลไม่เพียงพอ",
        "technical": "ยังมีข้อมูลไม่เพียงพอ",
    }


def _normalize_summary_payload(parsed_data) -> dict:
    if not isinstance(parsed_data, dict):
        raise ValueError("LLM returned an invalid interview summary payload.")

    experience_score = _clamp_score(parsed_data.get("experience_score"))
    communication_score = _clamp_score(parsed_data.get("communication_score"))
    technical_score = _clamp_score(parsed_data.get("technical_score"))
    average_total = round(
        (experience_score + communication_score + technical_score) / 3,
        2,
    )
    total_score = _clamp_score(
        parsed_data.get("total_score"),
        fallback=average_total,
    )

    if abs(total_score - average_total) > 0.05:
        total_score = average_total

    return {
        "total_score": total_score,
        "experience_score": experience_score,
        "communication_score": communication_score,
        "technical_score": technical_score,
        "recommendation": _normalize_recommendation(parsed_data.get("recommendation")),
        "confidence": _clamp_score(parsed_data.get("confidence"), fallback=0.7),
        "strengths": _normalize_summary_points(parsed_data.get("strengths"), "จุดแข็ง"),
        "weaknesses": _normalize_summary_points(parsed_data.get("weaknesses"), "จุดอ่อน"),
        "red_flags": _normalize_red_flags(parsed_data.get("red_flags")),
        "evidence": _normalize_evidence(parsed_data.get("evidence")),
        "suggestion_summary": str(
            parsed_data.get("suggestion_summary") or "ยังไม่สามารถสรุปผลการสัมภาษณ์ได้ชัดเจน"
        ).strip(),
        "next_step": str(
            parsed_data.get("next_step") or "แนะนำให้มีการประเมินเพิ่มเติมก่อนตัดสินใจ"
        ).strip(),
    }


def _parse_llm_summary_response(raw_text: str) -> InterviewSummaryModel:
    json_text = extract_json_text(raw_text)
    parsed_data = json.loads(json_text, strict=False)
    normalized_data = _normalize_summary_payload(parsed_data)
    return InterviewSummaryModel.model_validate(normalized_data)


def _looks_like_placeholder_summary(summary: InterviewSummaryModel) -> bool:
    data = summary.model_dump()
    if (
        data.get("recommendation") == PLACEHOLDER_SUMMARY_SIGNATURE["recommendation"]
        and data.get("suggestion_summary")
        == PLACEHOLDER_SUMMARY_SIGNATURE["suggestion_summary"]
        and data.get("next_step") == PLACEHOLDER_SUMMARY_SIGNATURE["next_step"]
    ):
        strengths = data.get("strengths") or []
        weaknesses = data.get("weaknesses") or []
        if strengths and weaknesses:
            first_strength = strengths[0]
            first_weakness = weaknesses[0]
            return (
                first_strength.get("title") == "สื่อสารชัดเจน"
                and first_weakness.get("title") == "ประสบการณ์ตรงยังน้อย"
            )
    return False


def _deserialize_json_field(value):
    if value is None or isinstance(value, (dict, list)):
        return value

    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value

    return value


def _summary_row_to_model(row) -> InterviewSummaryModel:
    return InterviewSummaryModel.model_validate(
        {
            "total_score": row.total_score,
            "experience_score": row.experience_score,
            "communication_score": row.communication_score,
            "technical_score": row.technical_score,
            "recommendation": row.recommendation,
            "confidence": row.confidence,
            "strengths": _deserialize_json_field(row.strengths),
            "weaknesses": _deserialize_json_field(row.weaknesses),
            "red_flags": row.red_flags or [],
            "evidence": _deserialize_json_field(row.evidence),
            "suggestion_summary": row.suggestion_summary,
            "next_step": row.next_step,
        }
    )


def _repair_summary_output(raw_text: str) -> InterviewSummaryModel:
    llm = get_llm(temperature=0.0)
    repair_prompt = f"""
You are a JSON repair assistant.

TASK:
Convert the following interview summary output into valid JSON only.

RULES:
- Keep the same meaning.
- Output only one JSON object.
- Use this exact schema:
{{
  "total_score": 0.0,
  "experience_score": 0.0,
  "communication_score": 0.0,
  "technical_score": 0.0,
  "recommendation": "hire | hold | no_hire",
  "confidence": 0.0,
  "strengths": [{{"title": "string", "evidence": "string"}}],
  "weaknesses": [{{"title": "string", "evidence": "string"}}],
  "red_flags": ["string"],
  "evidence": {{
    "experience": "string",
    "communication": "string",
    "technical": "string"
  }},
  "suggestion_summary": "string",
  "next_step": "string"
}}

RAW OUTPUT:
{raw_text}
"""
    response = llm.invoke(repair_prompt)
    repaired_text = response.content if hasattr(response, "content") else str(response)
    return _parse_llm_summary_response(repaired_text)


def _parse_tool_json(raw_value: str) -> dict:
    try:
        return json.loads(raw_value)
    except json.JSONDecodeError as exc:
        raise ValueError(f"Tool returned invalid JSON: {exc}") from exc


def _build_tool_map(db: Session) -> dict:
    return {tool.name: tool for tool in build_tools(db)}


def _limit_text(value: str, max_length: int = 280) -> str:
    text_value = str(value or "").strip()
    if len(text_value) <= max_length:
        return text_value
    return text_value[: max_length - 3].rstrip() + "..."


def _prepare_summary_inputs(db: Session, interview_id: int) -> dict:
    tools = _build_tool_map(db)
    interview_id_str = str(interview_id)

    core = _parse_tool_json(tools["GetInterviewCore"].func(interview_id_str))
    if core.get("error"):
        raise LookupError(core["error"])

    questions_payload = _parse_tool_json(
        tools["GetInterviewQuestions"].func(interview_id_str)
    )
    chat_payload = _parse_tool_json(tools["GetChatHistory"].func(interview_id_str))

    questions = questions_payload.get("questions", [])
    compact_questions = []
    for item in questions[:12]:
        compact_questions.append(
            {
                "question": _limit_text(item.get("question"), 220),
                "user_answer": _limit_text(item.get("user_answer"), 320),
                "score": item.get("score"),
                "reason": _limit_text(item.get("reason"), 220),
            }
        )

    chat_history = chat_payload.get("chat_history", [])
    recent_chat = chat_history[-18:]
    compact_chat = [
        {
            "sender_role": item.get("sender_role"),
            "sender_name": item.get("sender_name"),
            "message": _limit_text(item.get("message"), 220),
        }
        for item in recent_chat
    ]

    return {
        "core": core,
        "questions": compact_questions,
        "chat_history": compact_chat,
        "question_count": len(questions),
        "chat_count": len(chat_history),
    }


def generate_interview_summary(db: Session, interview_id: int) -> InterviewSummaryModel:
    query = text("SELECT id FROM interviews WHERE id = :id")
    if not db.execute(query, {"id": interview_id}).first():
        raise LookupError("Interview not found")

    try:
        process_unscored_hr_questions(db, interview_id)
    except Exception as e:
        print(f"Failed to process HR questions: {e}")

    summary_inputs = _prepare_summary_inputs(db, interview_id)
    llm = get_llm(temperature=0.1)

    print(summary_inputs["questions"])

    prompt = f"""
You are an HR interview evaluation assistant.

TASK:
Create a final interview summary for HR based only on the retrieved interview data.

RULES:
- Use Thai for every human-readable field value.
- Do not invent facts that are not supported by the tool outputs.
- If evidence is incomplete, be conservative.
- recommendation must be exactly one of: hire, hold, no_hire
- All scores must be between 0 and 1.
- total_score should be the average of experience_score, communication_score, and technical_score
- strengths and weaknesses must be arrays of objects with "title" and "evidence"
- evidence must be an object with keys: experience, communication, technical
- red_flags may be an empty array
- Every value must be derived from the tool outputs for interview_id {interview_id}
- Never copy generic placeholder text or canned sample values
- If the candidate performed weakly, the summary must reflect that honestly
- If the evidence is mixed, recommendation should usually be "hold"
- Return only valid JSON with no markdown and no explanation

OUTPUT SCHEMA:
{{
  "total_score": 0.0,
  "experience_score": 0.0,
  "communication_score": 0.0,
  "technical_score": 0.0,
  "recommendation": "hire | hold | no_hire",
  "confidence": 0.0,
  "strengths": [
    {{
      "title": "<thai title based on evidence>",
      "evidence": "<thai evidence based on interview data>"
    }}
  ],
  "weaknesses": [
    {{
      "title": "<thai title based on evidence>",
      "evidence": "<thai evidence based on interview data>"
    }}
  ],
  "red_flags": [
    "<thai risk item>"
  ],
  "evidence": {{
    "experience": "<thai evidence>",
    "communication": "<thai evidence>",
    "technical": "<thai evidence>"
  }},
  "suggestion_summary": "<thai hr summary>",
  "next_step": "<thai next step>"
}}

INTERVIEW CORE:
{json.dumps(summary_inputs["core"], ensure_ascii=False, indent=2)}

QUESTION SUMMARY:
- total_questions: {summary_inputs["question_count"]}
{json.dumps(summary_inputs["questions"], ensure_ascii=False, indent=2)}

RECENT CHAT SUMMARY:
- total_chat_messages: {summary_inputs["chat_count"]}
{json.dumps(summary_inputs["chat_history"], ensure_ascii=False, indent=2)}
"""

    try:
        response = llm.invoke(prompt)
        raw_output = response.content if hasattr(response, "content") else str(response)
        summary = _parse_llm_summary_response(raw_output)
        if _looks_like_placeholder_summary(summary):
            raise ValueError("LLM returned placeholder summary content.")
        return summary
    except Exception:
        try:
            repair_prompt = f"""
Rewrite the following interview summary into a valid JSON object that follows the required schema exactly.
Do not use sample values. Use only the evidence already present in the content.

CONTENT:
{raw_output if 'raw_output' in locals() else prompt}
"""
            repair_response = llm.invoke(repair_prompt)
            repaired_output = (
                repair_response.content
                if hasattr(repair_response, "content")
                else str(repair_response)
            )
            summary = _parse_llm_summary_response(repaired_output)
            if _looks_like_placeholder_summary(summary):
                raise ValueError("LLM returned placeholder summary content.")
            return summary
        except Exception:
            return _repair_summary_output(raw_output if 'raw_output' in locals() else prompt)


def save_interview_summary(
    db: Session,
    interview_id: int,
    summary: InterviewSummaryModel,
) -> InterviewSummaryModel:
    summary_data = summary.model_dump()
    select_query = text("""
        SELECT id
        FROM interview_summaries
        WHERE interview_id = :interview_id
        ORDER BY id DESC
        LIMIT 1
    """)
    existing = db.execute(select_query, {"interview_id": interview_id}).first()

    params = {
        "interview_id": interview_id,
        "total_score": summary_data["total_score"],
        "experience_score": summary_data["experience_score"],
        "communication_score": summary_data["communication_score"],
        "technical_score": summary_data["technical_score"],
        "recommendation": summary_data["recommendation"],
        "confidence": summary_data["confidence"],
        "strengths": json.dumps(summary_data["strengths"], ensure_ascii=False),
        "weaknesses": json.dumps(summary_data["weaknesses"], ensure_ascii=False),
        "red_flags": summary_data["red_flags"],
        "evidence": json.dumps(summary_data["evidence"], ensure_ascii=False),
        "suggestion_summary": summary_data["suggestion_summary"],
        "next_step": summary_data["next_step"],
    }

    if existing is None:
        write_query = text("""
            INSERT INTO interview_summaries (
                interview_id,
                total_score,
                experience_score,
                communication_score,
                technical_score,
                recommendation,
                confidence,
                strengths,
                weaknesses,
                red_flags,
                evidence,
                suggestion_summary,
                next_step
            )
            VALUES (
                :interview_id,
                :total_score,
                :experience_score,
                :communication_score,
                :technical_score,
                :recommendation,
                :confidence,
                CAST(:strengths AS JSON),
                CAST(:weaknesses AS JSON),
                :red_flags,
                CAST(:evidence AS JSON),
                :suggestion_summary,
                :next_step
            )
        """)
    else:
        params["id"] = existing.id
        write_query = text("""
            UPDATE interview_summaries
            SET total_score = :total_score,
                experience_score = :experience_score,
                communication_score = :communication_score,
                technical_score = :technical_score,
                recommendation = :recommendation,
                confidence = :confidence,
                strengths = CAST(:strengths AS JSON),
                weaknesses = CAST(:weaknesses AS JSON),
                red_flags = :red_flags,
                evidence = CAST(:evidence AS JSON),
                suggestion_summary = :suggestion_summary,
                next_step = :next_step
            WHERE id = :id
        """)

    db.execute(write_query, params)
    db.commit()

    saved_summary = get_saved_interview_summary(db, interview_id)
    if saved_summary is None:
        raise ValueError("Interview summary could not be saved")

    return saved_summary


def get_saved_interview_summary(
    db: Session,
    interview_id: int,
) -> InterviewSummaryModel | None:
    query = text("""
        SELECT
            id,
            interview_id,
            total_score,
            experience_score,
            communication_score,
            technical_score,
            recommendation,
            confidence,
            strengths,
            weaknesses,
            red_flags,
            evidence,
            suggestion_summary,
            next_step
        FROM interview_summaries
        WHERE interview_id = :interview_id
        ORDER BY id DESC
        LIMIT 1
    """)
    record = db.execute(query, {"interview_id": interview_id}).first()
    if record is None:
        return None

    return _summary_row_to_model(record)

import logging
import json
from datetime import datetime

from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from sqlalchemy import text

from src.databases.db_connect import get_db

interview_ws_router = APIRouter()
logger = logging.getLogger(__name__)


class ConnectionManager:
    def __init__(self):
        self.active_rooms: dict[str, dict[str, WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room_id: str, user_id: str):
        await websocket.accept()
        if room_id not in self.active_rooms:
            self.active_rooms[room_id] = {}
        self.active_rooms[room_id][user_id] = websocket
        logger.info(f"User {user_id} connected to room {room_id}")

    def disconnect(self, room_id: str, user_id: str):
        if room_id in self.active_rooms and user_id in self.active_rooms[room_id]:
            del self.active_rooms[room_id][user_id]
            if not self.active_rooms[room_id]:
                del self.active_rooms[room_id]
            logger.info(f"User {user_id} disconnected from room {room_id}")

    async def broadcast_to_others(self, room_id: str, sender_id: str, message: dict):
        if room_id in self.active_rooms:
            for uid, ws in self.active_rooms[room_id].items():
                if uid != sender_id:
                    try:
                        await ws.send_json(message)
                    except Exception as e:
                        logger.error(f"Error sending message to {uid}: {e}")

    async def broadcast_to_room(self, room_id: str, message: dict):
        if room_id in self.active_rooms:
            for uid, ws in self.active_rooms[room_id].items():
                try:
                    await ws.send_json(message)
                except Exception as e:
                    logger.error(f"Error sending room message to {uid}: {e}")

manager = ConnectionManager()
room_roles: dict[str, dict[str, str]] = {}


def _format_chat_history_message(message_text: str, role: str | None) -> str:
    text = (message_text or "").strip()
    normalized_role = (role or "").strip().upper()

    if normalized_role == "AI" and text and not text.startswith("[AI]"):
        return f"[AI] {text}"

    return text


def _normalize_room_role(role: str | None) -> str | None:
    normalized_role = (role or "").strip().lower()
    if normalized_role in {"hr", "candidate"}:
        return normalized_role
    return None


def _room_is_ready(room_id: str) -> bool:
    roles = set(room_roles.get(room_id, {}).values())
    return "hr" in roles and "candidate" in roles


async def _broadcast_room_status(room_id: str):
    participants = room_roles.get(room_id, {})
    await manager.broadcast_to_room(
        room_id,
        {
            "type": "room_status",
            "room_id": room_id,
            "is_ready": _room_is_ready(room_id),
            "participant_count": len(participants),
            "roles": list(participants.values()),
        },
    )


def _parse_created_at(timestamp: str | None) -> datetime:
    if not timestamp:
        return datetime.utcnow()

    try:
        return datetime.fromisoformat(timestamp)
    except ValueError:
        return datetime.utcnow()


def _persist_chat_message(db: Session, room_id: str, message: dict):
    sql_insert = text("""
        INSERT INTO chat_histories (interview_id, user_id, message, created_at)
        VALUES (:interview_id, :user_id, :message, :created_at)
    """)
    db.execute(
        sql_insert,
        {
            "interview_id": int(room_id),
            "user_id": int(message.get("speaker_id")),
            "message": _format_chat_history_message(
                message.get("text"),
                message.get("role"),
            ),
            "created_at": _parse_created_at(message.get("timestamp")),
        },
    )
    db.commit()


@interview_ws_router.websocket("/{room_id}/{user_id}")
async def interview_endpoint(
    websocket: WebSocket,
    room_id: str,
    user_id: str,
    db: Session = Depends(get_db),
):
    await manager.connect(websocket, room_id, user_id)
    try:
        while True:
            data = await websocket.receive_text()

            try:
                message = json.loads(data)
                msg_type = message.get("type")

                if msg_type in ["webrtc_sdp", "webrtc_ice", "join", "interview_ended"]:
                    if msg_type == "join":
                        normalized_role = _normalize_room_role(message.get("role"))
                        if room_id not in room_roles:
                            room_roles[room_id] = {}
                        if normalized_role:
                            room_roles[room_id][user_id] = normalized_role
                        await _broadcast_room_status(room_id)
                    await manager.broadcast_to_others(room_id, user_id, message)

                elif msg_type == "transcript":
                    if not _room_is_ready(room_id):
                        await _broadcast_room_status(room_id)
                        continue

                    _persist_chat_message(db, room_id, message)
                    await manager.broadcast_to_others(room_id, user_id, message)

            except json.JSONDecodeError:
                logger.error("Invalid JSON received")

    except WebSocketDisconnect:
        manager.disconnect(room_id, user_id)

        if room_id in room_roles and user_id in room_roles[room_id]:
            del room_roles[room_id][user_id]
            if not room_roles[room_id]:
                del room_roles[room_id]

        await manager.broadcast_to_others(room_id, user_id, {
            "type": "user_left",
            "user_id": user_id,
        })
        await _broadcast_room_status(room_id)

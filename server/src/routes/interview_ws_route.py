from fastapi import APIRouter, WebSocket, WebSocketDisconnect
import json
import logging

interview_ws_router = APIRouter()
logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        # room_id -> user_id -> websocket
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

manager = ConnectionManager()

@interview_ws_router.websocket("/{room_id}/{user_id}")
async def interview_endpoint(websocket: WebSocket, room_id: str, user_id: str):
    await manager.connect(websocket, room_id, user_id)
    try:
        while True:
            data = await websocket.receive_text()

            try:
                message = json.loads(data)
                msg_type = message.get("type")

                if msg_type in ["webrtc_sdp", "webrtc_ice", "join"]:
                    await manager.broadcast_to_others(room_id, user_id, message)
                
                elif msg_type == "transcript":
                    await manager.broadcast_to_others(room_id, user_id, message)
                    
            except json.JSONDecodeError:
                logger.error("Invalid JSON received")
                
    except WebSocketDisconnect:
        manager.disconnect(room_id, user_id)
        await manager.broadcast_to_others(room_id, user_id, {
            "type": "user_left",
            "user_id": user_id
        })

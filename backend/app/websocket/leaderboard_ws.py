# backend/app/websocket/leaderboard_ws.py
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict, Set
import asyncio
import json
from datetime import datetime

router = APIRouter()

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, Set[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, hackathon_id: str):
        await websocket.accept()
        if hackathon_id not in self.active_connections:
            self.active_connections[hackathon_id] = set()
        self.active_connections[hackathon_id].add(websocket)
    
    def disconnect(self, websocket: WebSocket, hackathon_id: str):
        if hackathon_id in self.active_connections:
            self.active_connections[hackathon_id].discard(websocket)
            if not self.active_connections[hackathon_id]:
                del self.active_connections[hackathon_id]
    
    async def broadcast(self, hackathon_id: str, message: dict):
        if hackathon_id in self.active_connections:
            for connection in self.active_connections[hackathon_id]:
                try:
                    await connection.send_json(message)
                except:
                    pass
    
    async def broadcast_leaderboard_update(self, hackathon_id: str, leaderboard_data: dict):
        await self.broadcast(hackathon_id, {
            "event": "leaderboard_updated",
            "data": leaderboard_data,
            "timestamp": datetime.utcnow().isoformat()
        })

manager = ConnectionManager()

@router.websocket("/public/hackathons/{hackathon_id}/leaderboard")
async def websocket_leaderboard(websocket: WebSocket, hackathon_id: str):
    await manager.connect(websocket, hackathon_id)
    try:
        while True:
            # Keep connection alive and listen for client messages
            data = await websocket.receive_text()
            # Handle ping/pong or other client messages if needed
            if data == "ping":
                await websocket.send_json({"event": "pong"})
    except WebSocketDisconnect:
        manager.disconnect(websocket, hackathon_id)
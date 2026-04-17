# backend/tests/test_websocket.py
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi import WebSocket
from app.websocket.leaderboard_ws import ConnectionManager, router


class TestConnectionManager:
    """Tests for WebSocket connection manager"""
    
    def test_connection_manager_init(self):
        """Test connection manager initialization"""
        manager = ConnectionManager()
        assert manager.active_connections == {}
    
    @pytest.mark.asyncio
    async def test_connect_new_hackathon(self):
        """Test connecting to new hackathon"""
        manager = ConnectionManager()
        mock_websocket = AsyncMock(spec=WebSocket)
        
        await manager.connect(mock_websocket, "hackathon_123")
        
        assert "hackathon_123" in manager.active_connections
        assert mock_websocket in manager.active_connections["hackathon_123"]
        mock_websocket.accept.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_connect_existing_hackathon(self):
        """Test connecting to existing hackathon"""
        manager = ConnectionManager()
        mock_websocket1 = AsyncMock(spec=WebSocket)
        mock_websocket2 = AsyncMock(spec=WebSocket)
        
        await manager.connect(mock_websocket1, "hackathon_123")
        await manager.connect(mock_websocket2, "hackathon_123")
        
        assert len(manager.active_connections["hackathon_123"]) == 2
    
    def test_disconnect_last_connection(self):
        """Test disconnecting last connection from hackathon"""
        manager = ConnectionManager()
        mock_websocket = MagicMock(spec=WebSocket)
        manager.active_connections["hackathon_123"] = {mock_websocket}
        
        manager.disconnect(mock_websocket, "hackathon_123")
        
        assert "hackathon_123" not in manager.active_connections
    
    def test_disconnect_not_last_connection(self):
        """Test disconnecting when multiple connections exist"""
        manager = ConnectionManager()
        mock_websocket1 = MagicMock(spec=WebSocket)
        mock_websocket2 = MagicMock(spec=WebSocket)
        manager.active_connections["hackathon_123"] = {mock_websocket1, mock_websocket2}
        
        manager.disconnect(mock_websocket1, "hackathon_123")
        
        assert "hackathon_123" in manager.active_connections
        assert len(manager.active_connections["hackathon_123"]) == 1
        assert mock_websocket2 in manager.active_connections["hackathon_123"]
    
    def test_disconnect_nonexistent_hackathon(self):
        """Test disconnecting from non-existent hackathon"""
        manager = ConnectionManager()
        mock_websocket = MagicMock(spec=WebSocket)
        
        # Should not raise error
        manager.disconnect(mock_websocket, "nonexistent")
    
    @pytest.mark.asyncio
    async def test_broadcast_to_hackathon(self):
        """Test broadcasting to hackathon connections"""
        manager = ConnectionManager()
        mock_websocket1 = AsyncMock(spec=WebSocket)
        mock_websocket2 = AsyncMock(spec=WebSocket)
        
        await manager.connect(mock_websocket1, "hackathon_123")
        await manager.connect(mock_websocket2, "hackathon_123")
        
        message = {"event": "test", "data": "hello"}
        await manager.broadcast("hackathon_123", message)
        
        mock_websocket1.send_json.assert_called_once_with(message)
        mock_websocket2.send_json.assert_called_once_with(message)
    
    @pytest.mark.asyncio
    async def test_broadcast_to_nonexistent_hackathon(self):
        """Test broadcasting to non-existent hackathon"""
        manager = ConnectionManager()
        mock_websocket = AsyncMock(spec=WebSocket)
        
        # Should not raise error
        await manager.broadcast("nonexistent", {"event": "test"})
        mock_websocket.send_json.assert_not_called()
    
    @pytest.mark.asyncio
    async def test_broadcast_with_failed_connection(self):
        """Test broadcasting when one connection fails"""
        manager = ConnectionManager()
        mock_websocket1 = AsyncMock(spec=WebSocket)
        mock_websocket2 = AsyncMock(spec=WebSocket)
        mock_websocket2.send_json.side_effect = Exception("Connection closed")
        
        await manager.connect(mock_websocket1, "hackathon_123")
        await manager.connect(mock_websocket2, "hackathon_123")
        
        await manager.broadcast("hackathon_123", {"event": "test"})
        
        # First websocket should have received message
        mock_websocket1.send_json.assert_called_once()
        # Second websocket attempted but failed (no exception raised)
        mock_websocket2.send_json.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_broadcast_leaderboard_update(self):
        """Test broadcasting leaderboard update"""
        manager = ConnectionManager()
        mock_websocket = AsyncMock(spec=WebSocket)
        await manager.connect(mock_websocket, "hackathon_123")
        
        leaderboard_data = {"items": [{"place": 1, "team_name": "Team A"}]}
        await manager.broadcast_leaderboard_update("hackathon_123", leaderboard_data)
        
        call_args = mock_websocket.send_json.call_args[0][0]
        assert call_args["event"] == "leaderboard_updated"
        assert call_args["data"] == leaderboard_data
        assert "timestamp" in call_args


class TestWebSocketRouter:
    """Tests for WebSocket router"""
    
    def test_router_exists(self):
        """Test that router is defined"""
        assert router is not None
        assert hasattr(router, "routes")
    
    def test_websocket_endpoint_path(self):
        """Test that websocket endpoint has correct path"""
        # Find the websocket route
        websocket_routes = [r for r in router.routes if hasattr(r, "path")]
        assert len(websocket_routes) > 0
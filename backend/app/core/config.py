from pydantic_settings import BaseSettings
from typing import List
import json
import os

class Settings(BaseSettings):
    # Database
    POSTGRES_USER: str = "hackathon_admin"
    POSTGRES_PASSWORD: str = "SecurePass123!"
    POSTGRES_DB: str = "hackathon_db"
    POSTGRES_HOST: str = "postgres"
    POSTGRES_PORT: str = "5432"
    
    @property
    def DATABASE_URL(self) -> str:
        return f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
    
    @property
    def SYNC_DATABASE_URL(self) -> str:
        return f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
    
    # JWT
    SECRET_KEY: str = "your-super-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # CORS - stored as string in env, parsed in property
    CORS_ORIGINS_STR: str = '["http://localhost:3000", "http://localhost:8080", "http://localhost:8000", "http://192.168.5.46:3000", "http://192.168.5.46:8000", "*"]'
    
    # App
    DEBUG: bool = True
    
    @property
    def CORS_ORIGINS(self) -> List[str]:
        """Parse CORS origins from string or environment"""
        origins_str = os.getenv("CORS_ORIGINS", self.CORS_ORIGINS_STR)
        try:
            return json.loads(origins_str)
        except json.JSONDecodeError:
            # Fallback to default
            return ["http://localhost:3000", "http://localhost:8080", "http://localhost:8000", "*"]
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"  # Игнорировать лишние поля из .env

settings = Settings()
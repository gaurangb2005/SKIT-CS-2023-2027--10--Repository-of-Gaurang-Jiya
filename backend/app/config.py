import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./rural_edu.db"
    JWT_SECRET: str = "rural-edu-secret-key-2026"
    JWT_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    FIREBASE_CREDENTIALS_PATH: str = ""
    ADMIN_EMAIL: str = "admin@example.com"
    ADMIN_PASSWORD: str = "admin123"

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()

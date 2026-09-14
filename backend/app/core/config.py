from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings and environment variables."""

    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "info"
    PORT: int = 8000
    HOST: str = "0.0.0.0"
    DEV_ALLOW_ANONYMOUS: bool = False

    # Supabase
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    SUPABASE_SERVICE_ROLE_KEY: Optional[str] = None
    SUPABASE_JWT_SECRET: str = "test_supabase_jwt_secret_dev_key_32bytes_long"

    # Gemini AI
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-2.0-flash"

    # BHASHINI (Speech / Indian Language Layer)
    BHASHINI_API_KEY: Optional[str] = None
    BHASHINI_USER_ID: Optional[str] = None
    BHASHINI_PIPELINE_ID: Optional[str] = None

    # Mappls (Maps / Geocoding Layer)
    MAPPLS_CLIENT_ID: Optional[str] = None
    MAPPLS_CLIENT_SECRET: Optional[str] = None

    model_config = SettingsConfigDict(
        env_file=("../.env", ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()

from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

class Settings(BaseSettings):
    # Supabase Configuration
    supabase_url: str = Field(..., env="SUPABASE_URL")
    supabase_key: str = Field(..., env="SUPABASE_KEY")
    
    # GitHub Setup (UPDATED)
    github_webhook_secret: str = Field(..., env="GITHUB_WEBHOOK_SECRET")
    github_app_id: int = Field(..., env="GITHUB_APP_ID")
    github_private_key: str = Field(..., env="GITHUB_PRIVATE_KEY")
    
    # Gemini Setup
    google_api_key: str = Field(..., env="GOOGLE_API_KEY")

    # Redis Configuration
    redis_url: str = Field("redis://localhost:6379", env="REDIS_URL")

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()
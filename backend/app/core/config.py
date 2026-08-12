from pydantic_settings import BaseSettings
from pydantic import ConfigDict, field_validator

class Settings(BaseSettings):
    APP_NAME: str = "SmartCare API"
    APP_ENV: str = "development"
    DATABASE_URL: str = "postgresql://postgres:12345@localhost:5432/smartcare"
    SECRET_KEY: str = "smartcare_super_secret_jwt_key_for_development_purposes_only_12345678"
    JWT_SECRET: str = ""
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 11520
    CORS_ORIGINS: str = "*"

    model_config = ConfigDict(env_file=".env", case_sensitive=True, extra="ignore")

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def fix_database_url(cls, v: str) -> str:
        if isinstance(v, str) and v.startswith("postgres://"):
            return v.replace("postgres://", "postgresql://", 1)
        return v

    def model_post_init(self, __context):
        if self.JWT_SECRET and self.SECRET_KEY == "smartcare_super_secret_jwt_key_for_development_purposes_only_12345678":
            self.SECRET_KEY = self.JWT_SECRET
        else:
            self.JWT_SECRET = self.SECRET_KEY

settings = Settings()

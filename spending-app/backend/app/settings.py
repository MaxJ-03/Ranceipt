from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

ENV_FILE_PATH = Path(__file__).resolve().parents[1] / ".env"


class AppSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=str(ENV_FILE_PATH), env_file_encoding="utf-8", extra="ignore")

    # Database settings
    db_host: str = Field(default="localhost", alias="DB_HOST")
    db_port: int = Field(default=5432, alias="DB_PORT")
    db_user: str = Field(default="spending_user", alias="DB_USER")
    db_password: str = Field(default="spending_password", alias="DB_PASSWORD")
    db_name: str = Field(default="spending_app", alias="DB_NAME")
    db_echo: bool = Field(default=False, alias="DB_ECHO")

    # Anthropic API settings
    anthropic_api_key: str = Field(default="", alias="ANTHROPIC_API_KEY")
    anthropic_model: str = Field(default="claude-sonnet-4-6", alias="ANTHROPIC_MODEL")

    @property
    def sqlalchemy_url(self) -> str:
        return (
            f"postgresql+psycopg://{self.db_user}:{self.db_password}@"
            f"{self.db_host}:{self.db_port}/{self.db_name}"
        )


settings = AppSettings()

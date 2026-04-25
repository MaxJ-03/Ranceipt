from __future__ import annotations

from collections.abc import Generator
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker


ENV_FILE_PATH = Path(__file__).resolve().parents[1] / ".env"


class AppSettings(BaseSettings):
	model_config = SettingsConfigDict(
		env_file=str(ENV_FILE_PATH),
		env_file_encoding="utf-8",
		extra="ignore",
	)

	db_host: str = Field(default="localhost", alias="DB_HOST")
	db_port: int = Field(default=5432, alias="DB_PORT")
	db_user: str = Field(default="postgres", alias="DB_USER")
	db_password: str = Field(default="postgres", alias="DB_PASSWORD")
	db_name: str = Field(default="spending_app", alias="DB_NAME")
	db_echo: bool = Field(default=False, alias="DB_ECHO")

	app_secret_key: str = Field(default="change-this-secret", alias="APP_SECRET_KEY")
	token_encryption_key: str | None = Field(default=None, alias="TOKEN_ENCRYPTION_KEY")

	bunq_api_base_url: str = Field(
		default="https://public-api.sandbox.bunq.com/v1",
		alias="BUNQ_API_BASE_URL",
	)
	bunq_sandbox_api_key: str | None = Field(default=None, alias="BUNQ_SANDBOX_API_KEY")

	@property
	def sqlalchemy_url(self) -> str:
		return (
			f"postgresql+psycopg://{self.db_user}:{self.db_password}@"
			f"{self.db_host}:{self.db_port}/{self.db_name}"
		)


settings = AppSettings()

engine = create_engine(
	settings.sqlalchemy_url,
	echo=settings.db_echo,
	pool_pre_ping=True,
)

SessionLocal = sessionmaker(
	bind=engine,
	autoflush=False,
	autocommit=False,
	expire_on_commit=False,
	class_=Session,
)


def get_db() -> Generator[Session, None, None]:
	db = SessionLocal()
	try:
		yield db
	finally:
		db.close()
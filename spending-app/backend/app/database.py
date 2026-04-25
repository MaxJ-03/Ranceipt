from __future__ import annotations

from collections.abc import Generator
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker


ENV_FILE_PATH = Path(__file__).resolve().parents[1] / ".env"


class DatabaseSettings(BaseSettings):
	model_config = SettingsConfigDict(env_file=str(ENV_FILE_PATH), env_file_encoding="utf-8", extra="ignore")

	db_host: str = Field(default="localhost", alias="DB_HOST")
	db_port: int = Field(default=5432, alias="DB_PORT")
	db_user: str = Field(default="spending_user", alias="DB_USER")
	db_password: str = Field(default="spending_password", alias="DB_PASSWORD")
	db_name: str = Field(default="spending_app", alias="DB_NAME")
	db_echo: bool = Field(default=False, alias="DB_ECHO")

	@property
	def sqlalchemy_url(self) -> str:
		return (
			f"postgresql+psycopg://{self.db_user}:{self.db_password}@"
			f"{self.db_host}:{self.db_port}/{self.db_name}"
		)


settings = DatabaseSettings()

engine = create_engine(
	settings.sqlalchemy_url,
	echo=settings.db_echo,
	pool_pre_ping=True,
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False, class_=Session)


def get_db() -> Generator[Session, None, None]:
	db = SessionLocal()
	try:
		yield db
	finally:
		db.close()

import os
from pathlib import Path
from dotenv import load_dotenv

ENV_PATH = Path(__file__).resolve().parents[1] / ".env"
load_dotenv(ENV_PATH)

DATABASE_URL = os.getenv("DATABASE_URL")
BUNQ_API_BASE_URL = os.getenv("BUNQ_API_BASE_URL", "https://public-api.sandbox.bunq.com/v1")
BUNQ_SANDBOX_API_KEY = os.getenv("BUNQ_SANDBOX_API_KEY")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL is missing from backend/.env")

if not BUNQ_SANDBOX_API_KEY:
    raise RuntimeError("BUNQ_SANDBOX_API_KEY is missing from backend/.env")
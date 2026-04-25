"""Seed demo database for Ranceipt."""
import os
from pathlib import Path
from sqlalchemy import create_engine, text

# Use environment variable or default
db_url = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/spending_app"
)

engine = create_engine(db_url)

demo_seed_path = Path(__file__).parent / "spending-app" / "backend" / "demo_seed.sql"

with open(demo_seed_path, "r") as f:
    sql_script = f.read()

try:
    with engine.begin() as conn:
        conn.execute(text(sql_script))
    print("✓ Demo data seeded successfully")
except Exception as e:
    print(f"✗ Error seeding demo data: {e}")
    raise

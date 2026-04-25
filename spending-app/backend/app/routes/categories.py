from fastapi import APIRouter, Depends
from psycopg import Connection
from app.database import get_db

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("/custom")
def get_custom_categories(db: Connection = Depends(get_db)):
    with db.cursor() as cur:
        cur.execute("SELECT id, name FROM custom_categories ORDER BY name;")
        return cur.fetchall()


@router.get("/general")
def get_general_categories(db: Connection = Depends(get_db)):
    with db.cursor() as cur:
        cur.execute("SELECT id, name FROM general_categories ORDER BY name;")
        return cur.fetchall()
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.database import get_db

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("/custom")
def get_custom_categories(db: Session = Depends(get_db)):
    return db.execute(
        text("SELECT id, name FROM custom_categories ORDER BY name;")
    ).mappings().all()


@router.get("/general")
def get_general_categories(db: Session = Depends(get_db)):
    return db.execute(
        text("SELECT id, name FROM general_categories ORDER BY name;")
    ).mappings().all()
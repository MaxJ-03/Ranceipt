"""
Demo-only endpoints for sandbox testing.
Only available in development/demo mode.
"""

import os
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db

router = APIRouter(prefix="/demo", tags=["demo"])


@router.post("/seed")
def seed_demo_data(db: Session = Depends(get_db)):
    """
    Populates demo data from backend/demo_seed.sql.
    Idempotent: safe to run multiple times.
    Returns counts of seeded records.
    """
    try:
        # Read and execute demo seed SQL
        demo_seed_path = Path(__file__).parent.parent.parent / "demo_seed.sql"
        
        if not demo_seed_path.exists():
            raise HTTPException(
                status_code=404,
                detail=f"Demo seed file not found at {demo_seed_path}",
            )
        
        with open(demo_seed_path, "r") as f:
            seed_sql = f.read()
        
        # Execute the seed script
        db.execute(text(seed_sql))
        db.commit()
        
        # Get counts
        counts = {
            "users": db.execute(
                text("SELECT COUNT(*) as count FROM users WHERE id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user')")
            ).scalar() or 0,
            "transactions": db.execute(
                text("SELECT COUNT(*) as count FROM transactions WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user')")
            ).scalar() or 0,
            "receipts": db.execute(
                text("SELECT COUNT(*) as count FROM receipts WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user')")
            ).scalar() or 0,
            "receipt_items": db.execute(
                text("SELECT COUNT(*) as count FROM receipt_items WHERE receipt_id IN (SELECT id FROM receipts WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user'))")
            ).scalar() or 0,
            "personal_goals": db.execute(
                text("SELECT COUNT(*) as count FROM personal_goals WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user')")
            ).scalar() or 0,
            "bunq_connections": db.execute(
                text("SELECT COUNT(*) as count FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user'")
            ).scalar() or 0,
        }
        
        return {
            "message": "Demo data seeded successfully",
            "counts": counts,
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to seed demo data: {str(e)}",
        )


@router.get("/status")
def demo_status(db: Session = Depends(get_db)):
    """
    Returns whether demo data exists and current counts.
    """
    try:
        demo_user_exists = db.execute(
            text("SELECT COUNT(*) as count FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user'")
        ).scalar() or 0
        
        if demo_user_exists == 0:
            return {
                "demo_data_exists": False,
                "counts": {},
            }
        
        counts = {
            "users": db.execute(
                text("SELECT COUNT(*) as count FROM users WHERE id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user')")
            ).scalar() or 0,
            "transactions": db.execute(
                text("SELECT COUNT(*) as count FROM transactions WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user')")
            ).scalar() or 0,
            "receipts": db.execute(
                text("SELECT COUNT(*) as count FROM receipts WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user')")
            ).scalar() or 0,
            "receipt_items": db.execute(
                text("SELECT COUNT(*) as count FROM receipt_items WHERE receipt_id IN (SELECT id FROM receipts WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user'))")
            ).scalar() or 0,
            "personal_goals": db.execute(
                text("SELECT COUNT(*) as count FROM personal_goals WHERE user_id IN (SELECT user_id FROM bunq_connections WHERE bunq_user_api_key_id = 'sandbox-demo-user')")
            ).scalar() or 0,
        }
        
        return {
            "demo_data_exists": demo_user_exists > 0,
            "counts": counts,
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get demo status: {str(e)}",
        )

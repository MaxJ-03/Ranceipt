from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from datetime import datetime
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.database import get_db
from app.routes.auth import get_current_user

router = APIRouter(prefix="/goals", tags=["goals"])


class CreateGoalRequest(BaseModel):
    amount_to_save: float
    currency: str = "EUR"
    target_date: datetime


@router.post("/")
def create_goal(
    body: CreateGoalRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    goal = db.execute(
        text(
            """
            INSERT INTO personal_goals (
                user_id,
                amount_to_save,
                currency,
                target_date
            )
            VALUES (:user_id, :amount_to_save, :currency, :target_date)
            RETURNING id, user_id, amount_to_save, currency, target_date, created_at;
            """
        ),
        {
            "user_id": user["id"],
            "amount_to_save": body.amount_to_save,
            "currency": body.currency,
            "target_date": body.target_date,
        },
    ).mappings().first()

    db.commit()
    return goal


@router.get("/")
def get_my_goals(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return db.execute(
        text(
            """
            SELECT
                id,
                user_id,
                amount_to_save,
                currency,
                target_date,
                created_at
            FROM personal_goals
            WHERE user_id = :user_id
            ORDER BY target_date ASC;
            """
        ),
        {"user_id": user["id"]},
    ).mappings().all()


@router.delete("/{goal_id}")
def delete_goal(
    goal_id: int,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    deleted = db.execute(
        text(
            """
            DELETE FROM personal_goals
            WHERE id = :goal_id AND user_id = :user_id
            RETURNING id;
            """
        ),
        {
            "goal_id": goal_id,
            "user_id": user["id"],
        },
    ).mappings().first()

    db.commit()

    if not deleted:
        raise HTTPException(status_code=404, detail="Goal not found")

    return {"deleted_goal_id": deleted["id"]}
from fastapi import APIRouter, Depends, HTTPException
from psycopg import Connection
from pydantic import BaseModel
from datetime import datetime
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
    db: Connection = Depends(get_db),
    user=Depends(get_current_user),
):
    with db.cursor() as cur:
        cur.execute(
            """
            INSERT INTO personal_goals (
                user_id,
                amount_to_save,
                currency,
                target_date
            )
            VALUES (%s, %s, %s, %s)
            RETURNING id, user_id, amount_to_save, currency, target_date, created_at;
            """,
            (
                user["id"],
                body.amount_to_save,
                body.currency,
                body.target_date,
            ),
        )

        goal = cur.fetchone()

    db.commit()
    return goal


@router.get("/")
def get_my_goals(
    db: Connection = Depends(get_db),
    user=Depends(get_current_user),
):
    with db.cursor() as cur:
        cur.execute(
            """
            SELECT
                id,
                user_id,
                amount_to_save,
                currency,
                target_date,
                created_at
            FROM personal_goals
            WHERE user_id = %s
            ORDER BY target_date ASC;
            """,
            (user["id"],),
        )

        return cur.fetchall()


@router.delete("/{goal_id}")
def delete_goal(
    goal_id: int,
    db: Connection = Depends(get_db),
    user=Depends(get_current_user),
):
    with db.cursor() as cur:
        cur.execute(
            """
            DELETE FROM personal_goals
            WHERE id = %s AND user_id = %s
            RETURNING id;
            """,
            (goal_id, user["id"]),
        )

        deleted = cur.fetchone()

    db.commit()

    if not deleted:
        raise HTTPException(status_code=404, detail="Goal not found")

    return {"deleted_goal_id": deleted["id"]}
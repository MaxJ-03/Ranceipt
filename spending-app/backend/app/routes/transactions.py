from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.routes.auth import get_current_user

router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.get("/")
def get_my_transactions(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return db.execute(
        text(
            """
            SELECT
                t.id,
                t.bunq_payment_id,
                t.amount,
                t.currency,
                t.merchant,
                t.description,
                t.transaction_date,
                gc.name AS general_category,
                t.created_at
            FROM transactions t
            LEFT JOIN general_categories gc
                ON t.general_category_id = gc.id
            WHERE t.user_id = :user_id
            ORDER BY t.transaction_date DESC;
            """
        ),
        {"user_id": user["id"]},
    ).mappings().all()


@router.get("/summary")
def get_my_transaction_summary(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return db.execute(
        text(
            """
            SELECT
                COUNT(*) AS transaction_count,
                COALESCE(SUM(amount), 0) AS total_spent
            FROM transactions
            WHERE user_id = :user_id;
            """
        ),
        {"user_id": user["id"]},
    ).mappings().first()


@router.get("/by-category")
def get_my_transactions_by_category(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return db.execute(
        text(
            """
            SELECT
                COALESCE(gc.name, 'Uncategorized') AS general_category,
                COUNT(t.id) AS transaction_count,
                COALESCE(SUM(t.amount), 0) AS total_amount
            FROM transactions t
            LEFT JOIN general_categories gc
                ON t.general_category_id = gc.id
            WHERE t.user_id = :user_id
            GROUP BY gc.name
            ORDER BY total_amount DESC;
            """
        ),
        {"user_id": user["id"]},
    ).mappings().all()
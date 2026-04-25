from fastapi import APIRouter, Depends
from psycopg import Connection

from app.database import get_db
from app.routes.auth import get_current_user

router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.get("/")
def get_my_transactions(
    db: Connection = Depends(get_db),
    user=Depends(get_current_user),
):
    with db.cursor() as cur:
        cur.execute(
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
            WHERE t.user_id = %s
            ORDER BY t.transaction_date DESC;
            """,
            (user["id"],),
        )

        return cur.fetchall()


@router.get("/summary")
def get_my_transaction_summary(
    db: Connection = Depends(get_db),
    user=Depends(get_current_user),
):
    with db.cursor() as cur:
        cur.execute(
            """
            SELECT
                COUNT(*) AS transaction_count,
                COALESCE(SUM(amount), 0) AS total_spent
            FROM transactions
            WHERE user_id = %s;
            """,
            (user["id"],),
        )

        return cur.fetchone()


@router.get("/by-category")
def get_my_transactions_by_category(
    db: Connection = Depends(get_db),
    user=Depends(get_current_user),
):
    with db.cursor() as cur:
        cur.execute(
            """
            SELECT
                COALESCE(gc.name, 'Uncategorized') AS general_category,
                COUNT(t.id) AS transaction_count,
                COALESCE(SUM(t.amount), 0) AS total_amount
            FROM transactions t
            LEFT JOIN general_categories gc
                ON t.general_category_id = gc.id
            WHERE t.user_id = %s
            GROUP BY gc.name
            ORDER BY total_amount DESC;
            """,
            (user["id"],),
        )

        return cur.fetchall()
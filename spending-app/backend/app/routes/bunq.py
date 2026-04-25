from fastapi import APIRouter, Depends, HTTPException
from psycopg import Connection

from app.database import get_db
from app.routes.auth import get_current_user
from app.services.bunq_client import BunqClient

router = APIRouter(prefix="/bunq", tags=["bunq"])


def get_general_category_id(db: Connection, name: str) -> int | None:
    with db.cursor() as cur:
        cur.execute(
            """
            SELECT id
            FROM general_categories
            WHERE name = %s
            LIMIT 1;
            """,
            (name,),
        )

        row = cur.fetchone()

    if row:
        return row["id"]

    with db.cursor() as cur:
        cur.execute(
            """
            SELECT id
            FROM general_categories
            WHERE name = 'Uncategorized'
            LIMIT 1;
            """
        )

        fallback = cur.fetchone()

    return fallback["id"] if fallback else None


def get_payment_amount(payment: dict) -> tuple[float, str]:
    amount = payment.get("amount", {})
    value = float(amount.get("value", 0))
    currency = amount.get("currency", "EUR")
    return value, currency


def get_payment_merchant(payment: dict) -> str | None:
    counterparty = payment.get("counterparty_alias") or {}
    alias = payment.get("alias") or {}

    return (
        counterparty.get("display_name")
        or counterparty.get("name")
        or alias.get("display_name")
        or alias.get("name")
    )


def get_payment_date(payment: dict) -> str | None:
    return payment.get("created") or payment.get("updated")


def get_bunq_general_category(payment: dict) -> str:
    value = (
        payment.get("category")
        or payment.get("general_category")
        or payment.get("additional_transaction_information_category")
    )

    if value:
        return BunqClient._prettify_bunq_category(str(value))

    return "Uncategorized"


@router.get("/accounts")
def get_bunq_accounts():
    try:
        client = BunqClient()
        accounts = client.get_monetary_accounts()

        return [
            {
                "id": account.get("id"),
                "description": account.get("description"),
                "currency": account.get("currency"),
                "status": account.get("status"),
            }
            for account in accounts
        ]

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/sandbox/fund-max")
def fund_sandbox_user():
    """
    Temporary sandbox helper.
    Keep for hackathon/dev. Remove before production.
    """
    try:
        client = BunqClient()
        response = client.request_sandbox_money("500.00")

        return {
            "message": "Requested €500 sandbox money from Sugar Daddy",
            "response": response,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/sandbox/create-demo-spending")
def create_demo_spending():
    """
    Temporary sandbox helper.
    Keep for hackathon/dev. Remove before production.
    """
    try:
        client = BunqClient()
        payments = client.create_demo_spending()

        return {
            "message": "Created demo sandbox payments",
            "count": len(payments),
            "payments": payments,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/transactions/sync")
def sync_bunq_transactions(
    db: Connection = Depends(get_db),
    user=Depends(get_current_user),
):
    try:
        client = BunqClient()
        payments = client.get_all_payments()

        inserted_count = 0
        skipped_count = 0

        with db.cursor() as cur:
            for payment in payments:
                bunq_payment_id = str(payment.get("id"))
                amount, currency = get_payment_amount(payment)
                merchant = get_payment_merchant(payment)
                description = payment.get("description")
                transaction_date = get_payment_date(payment)

                if not transaction_date:
                    skipped_count += 1
                    continue

                general_category_name = get_bunq_general_category(payment)
                general_category_id = get_general_category_id(
                    db,
                    general_category_name,
                )

                cur.execute(
                    """
                    INSERT INTO transactions (
                        user_id,
                        bunq_payment_id,
                        amount,
                        currency,
                        merchant,
                        description,
                        transaction_date,
                        general_category_id
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (user_id, bunq_payment_id)
                    DO NOTHING
                    RETURNING id;
                    """,
                    (
                        user["id"],
                        bunq_payment_id,
                        amount,
                        currency,
                        merchant,
                        description,
                        transaction_date,
                        general_category_id,
                    ),
                )

                row = cur.fetchone()

                if row:
                    inserted_count += 1
                else:
                    skipped_count += 1

        db.commit()

        return {
            "message": "bunq transactions synced",
            "user_id": user["id"],
            "payments_seen": len(payments),
            "inserted": inserted_count,
            "skipped_or_existing": skipped_count,
        }

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
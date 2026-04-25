from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import CustomCategory, Receipt, ReceiptItem


class PersonalGoalsRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_last_30_days_spending(self, user_id: int) -> dict[str, Decimal]:
        """Get spending breakdown by category for the last 30 days."""
        thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)

        # Query receipt items with category names for receipts from the last 30 days
        stmt = (
            select(CustomCategory.name, func.sum(ReceiptItem.unit_price * ReceiptItem.quantity).label("total"))
            .join(ReceiptItem, ReceiptItem.category_id == CustomCategory.id)
            .join(Receipt, Receipt.id == ReceiptItem.receipt_id)
            .where(Receipt.user_id == user_id)
            .where(Receipt.created_at >= thirty_days_ago)
            .group_by(CustomCategory.name)
            .order_by(func.sum(ReceiptItem.unit_price * ReceiptItem.quantity).desc())
        )

        results = self.db.execute(stmt).all()
        return {category: total for category, total in results}

    def get_total_spending_last_30_days(self, user_id: int) -> Decimal:
        """Get total spending amount for the last 30 days."""
        thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)

        stmt = (
            select(func.sum(ReceiptItem.unit_price * ReceiptItem.quantity))
            .join(Receipt, Receipt.id == ReceiptItem.receipt_id)
            .where(Receipt.user_id == user_id)
            .where(Receipt.created_at >= thirty_days_ago)
        )

        result = self.db.execute(stmt).scalar()
        return result or Decimal("0")

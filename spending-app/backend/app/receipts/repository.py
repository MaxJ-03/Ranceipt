from __future__ import annotations

from decimal import Decimal

from sqlalchemy import Select, select
from sqlalchemy.orm import Session, selectinload

from app.models import CustomCategory, Receipt, ReceiptItem
from app.receipts.categories import PRIMARY_CATEGORIES
from app.receipts.schemas import ReceiptParseResponse


class ReceiptRepository:
    def save_parsed_receipt(
        self,
        db: Session,
        *,
        user_id: int,
        transaction_id: int | None,
        parsed_receipt: ReceiptParseResponse,
    ) -> Receipt:
        category_map = self._get_or_create_categories(db, list(parsed_receipt.category_totals.keys()))

        receipt = Receipt(
            user_id=user_id,
            transaction_id=transaction_id,
            merchant=parsed_receipt.merchant,
            total_amount=Decimal(str(parsed_receipt.receipt_total)),
            currency=parsed_receipt.currency,
            receipt_date=parsed_receipt.timestamp,
        )
        db.add(receipt)
        db.flush()

        for category_name, total in parsed_receipt.category_totals.items():
            if total <= 0:
                continue
            quantity = parsed_receipt.category_quantities.get(category_name, 0.0)
            safe_quantity = quantity if quantity and quantity > 0 else 1.0
            unit_price = Decimal(str(total)) / Decimal(str(safe_quantity))
            category_id = category_map.get(category_name)
            if category_id is None:
                continue
            db.add(
                ReceiptItem(
                    receipt_id=receipt.id,
                    category_id=category_id,
                    quantity=Decimal(str(safe_quantity)),
                    unit_price=unit_price,
                )
            )

        db.commit()
        db.refresh(receipt)
        return receipt

    def get_parsed_receipt_by_id(self, db: Session, receipt_id: int) -> ReceiptParseResponse | None:
        stmt: Select[tuple[Receipt]] = (
            select(Receipt)
            .where(Receipt.id == receipt_id)
            .options(selectinload(Receipt.items).selectinload(ReceiptItem.category))
        )
        receipt = db.execute(stmt).scalar_one_or_none()
        if receipt is None:
            return None

        category_totals = {category: 0.0 for category in PRIMARY_CATEGORIES}
        category_quantities = {category: 0.0 for category in PRIMARY_CATEGORIES}
        for item in receipt.items:
            category_name = item.category.name
            if category_name not in category_totals:
                category_totals[category_name] = 0.0
                category_quantities[category_name] = 0.0
            category_totals[category_name] += float(item.unit_price * item.quantity)
            category_quantities[category_name] += float(item.quantity)

        return ReceiptParseResponse(
            receipt_id=receipt.id,
            merchant=receipt.merchant or "Unknown merchant",
            timestamp=receipt.receipt_date or receipt.created_at,
            receipt_total=float(receipt.total_amount or 0),
            currency=receipt.currency,
            category_totals=category_totals,
            category_quantities=category_quantities,
            source="database",
        )

    def _get_or_create_categories(self, db: Session, category_names: list[str]) -> dict[str, int]:
        if not category_names:
            return {}

        stmt = select(CustomCategory).where(CustomCategory.name.in_(category_names))
        existing = db.execute(stmt).scalars().all()
        mapping = {category.name: category.id for category in existing}

        missing_names = [name for name in category_names if name not in mapping]
        for name in missing_names:
            category = CustomCategory(name=name)
            db.add(category)
            db.flush()
            mapping[name] = category.id

        return mapping
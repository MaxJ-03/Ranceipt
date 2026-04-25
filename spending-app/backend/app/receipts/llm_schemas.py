from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field, field_validator

from app.receipts.categories import PRIMARY_CATEGORIES


_ALLOWED_CATEGORIES = set(PRIMARY_CATEGORIES)


class CategoryTotalEntry(BaseModel):
    category: str
    quantity: float = 1.0
    total: float = 0.0

    @field_validator("category")
    @classmethod
    def validate_category(cls, value: str) -> str:
        if value not in _ALLOWED_CATEGORIES:
            return ""
        return value

    @field_validator("quantity")
    @classmethod
    def validate_quantity(cls, value: float) -> float:
        if value <= 0:
            return 0.0
        return value


class ReceiptExtractionResult(BaseModel):
    merchant: str
    receipt_date: date | None = None
    receipt_time: str | None = None
    currency: str = "EUR"
    receipt_total: float
    category_totals: list[CategoryTotalEntry] = Field(default_factory=list)
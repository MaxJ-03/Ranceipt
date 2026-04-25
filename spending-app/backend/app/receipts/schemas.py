from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class ReceiptParseResponse(BaseModel):
    receipt_id: int | None = None
    merchant: str
    timestamp: datetime
    receipt_total: float
    currency: str = "EUR"
    category_totals: dict[str, float] = Field(default_factory=dict)
    category_quantities: dict[str, float] = Field(default_factory=dict)
    source: str = "claude"


class ReceiptSaveRequest(BaseModel):
    user_id: int
    transaction_id: int | None = None
    parsed_receipt: ReceiptParseResponse
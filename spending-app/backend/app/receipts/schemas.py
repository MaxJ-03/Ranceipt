from __future__ import annotations

from datetime import date
from typing import Any

from pydantic import BaseModel, Field


class ReceiptItem(BaseModel):
    raw_name: str
    normalized_name: str
    category: str
    price: float
    quantity: float = 1.0


class SavingsRecommendation(BaseModel):
    category: str
    message: str
    potential_savings: float = 0.0


class ReceiptParseResponse(BaseModel):
    merchant: str
    date: date | None = None
    total: float | None = None
    currency: str = "EUR"
    line_items: list[ReceiptItem] = Field(default_factory=list)
    category_totals: dict[str, float] = Field(default_factory=dict)
    savings_recommendations: list[SavingsRecommendation] = Field(default_factory=list)
    parsed_text: str | None = None
    source: str = "fallback"
    metadata: dict[str, Any] = Field(default_factory=dict)
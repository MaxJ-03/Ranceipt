from __future__ import annotations

import base64
from datetime import datetime, date, time, timezone
import re
from typing import Any

from app.receipts.categories import PRIMARY_CATEGORIES
from app.receipts.llm_schemas import ReceiptExtractionResult
from app.receipts.prompts import build_receipt_extraction_prompt
from app.receipts.schemas import ReceiptParseResponse
from app.settings import settings


class ReceiptPipeline:
    def parse(self, image_bytes: bytes, filename: str | None = None, content_type: str | None = None) -> ReceiptParseResponse:
        try:
            structured = self._extract_with_langchain(image_bytes=image_bytes, content_type=content_type)
            return self._normalize_response(structured)
        except Exception as e:
            print(f"ERROR: Receipt parsing failed: {type(e).__name__}: {str(e)}")
            return self._demo_fallback_response()

    def _extract_with_langchain(self, image_bytes: bytes, content_type: str | None) -> ReceiptExtractionResult:
        api_key = settings.anthropic_api_key
        if not api_key:
            raise RuntimeError("ANTHROPIC_API_KEY is not set")

        try:
            from langchain_anthropic import ChatAnthropic
            from langchain_core.messages import HumanMessage
        except Exception:
            raise RuntimeError("langchain-anthropic or langchain-core package is not installed")

        media_type = content_type or "image/png"
        encoded = base64.b64encode(image_bytes).decode("ascii")

        llm = ChatAnthropic(
            model=settings.anthropic_model,
            api_key=api_key,
            max_tokens=1500,
            temperature=0,
        )
        structured_llm = llm.with_structured_output(ReceiptExtractionResult)

        message = HumanMessage(
            content=[
                {
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": media_type,
                        "data": encoded,
                    },
                },
                {
                    "type": "text",
                    "text": build_receipt_extraction_prompt(),
                },
            ]
        )

        result = structured_llm.invoke([message])
        if isinstance(result, ReceiptExtractionResult):
            return result
        return ReceiptExtractionResult.model_validate(result)

    def _normalize_response(self, structured: ReceiptExtractionResult) -> ReceiptParseResponse:
        merchant = structured.merchant.strip() or "Unknown merchant"
        receipt_total = self._parse_amount_value(structured.receipt_total)
        currency = structured.currency.strip() or "EUR"

        category_totals: dict[str, float] = {}
        category_quantities: dict[str, float] = {}
        for category in PRIMARY_CATEGORIES:
            category_totals[category] = 0.0
            category_quantities[category] = 0.0

        for entry in structured.category_totals:
            if not entry.category:
                continue
            if entry.category in category_totals:
                category_totals[entry.category] += self._parse_amount_value(entry.total)
                category_quantities[entry.category] += self._parse_amount_value(entry.quantity)

        for category in PRIMARY_CATEGORIES:
            category_totals.setdefault(category, 0.0)
            category_quantities.setdefault(category, 0.0)

        return ReceiptParseResponse(
            merchant=merchant,
            timestamp=self._build_timestamp(structured.receipt_date, structured.receipt_time),
            receipt_total=receipt_total,
            currency=currency,
            category_totals=category_totals,
            category_quantities=category_quantities,
            source="claude",
        )

    def _demo_fallback_response(
        self,
    ) -> ReceiptParseResponse:
        category_totals = {category: 0.0 for category in PRIMARY_CATEGORIES}
        category_quantities = {category: 0.0 for category in PRIMARY_CATEGORIES}
        return ReceiptParseResponse(
            merchant="Demo Market",
            timestamp=datetime.now(timezone.utc),
            receipt_total=18.75,
            currency="EUR",
            category_totals=category_totals,
            category_quantities=category_quantities,
            source="fallback",
        )

    def _build_timestamp(self, receipt_date: date | None, receipt_time: str | None) -> datetime:
        now = datetime.now(timezone.utc)

        if receipt_date is None:
            return now

        if isinstance(receipt_time, str):
            time_value = self._parse_time_value(receipt_time)
            if time_value is not None:
                return datetime.combine(receipt_date, time_value, tzinfo=timezone.utc)

        return datetime.combine(receipt_date, now.time(), tzinfo=timezone.utc)

    def _parse_time_value(self, value: str) -> time | None:
        normalized = value.strip()
        if not normalized:
            return None

        if not re.fullmatch(r"\d{1,2}:\d{2}(:\d{2})?", normalized):
            return None

        parts = normalized.split(":")
        hour = int(parts[0])
        minute = int(parts[1])
        second = int(parts[2]) if len(parts) == 3 else 0

        if hour > 23 or minute > 59 or second > 59:
            return None

        return time(hour=hour, minute=minute, second=second)

    def _parse_amount_value(self, value: Any) -> float:
        if value is None:
            return 0.0
        if isinstance(value, (int, float)):
            return round(float(value), 2)
        if isinstance(value, str):
            normalized = value.replace(",", ".")
            try:
                return round(float(normalized), 2)
            except ValueError:
                return 0.0
        return 0.0
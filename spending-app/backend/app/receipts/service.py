from __future__ import annotations

import base64
import io
import os
import re
from collections import defaultdict
from datetime import date, datetime
from typing import Any

from app.receipts.categories import categorize_product, normalize_product_name, should_skip_line
from app.receipts.schemas import ReceiptItem, ReceiptParseResponse, SavingsRecommendation


class ReceiptPipeline:
    def parse(self, image_bytes: bytes, filename: str | None = None, content_type: str | None = None) -> ReceiptParseResponse:
        parsed_text = ""
        source = "fallback"

        try:
            parsed_text = self._extract_text(image_bytes=image_bytes, filename=filename, content_type=content_type)
            source = "ocr" if parsed_text else "fallback"
        except Exception:
            parsed_text = ""

        if not parsed_text:
            return self._demo_fallback_response()

        merchant = self._extract_merchant(parsed_text)
        parsed_date = self._extract_date(parsed_text)
        currency = self._extract_currency(parsed_text)
        total = self._extract_total(parsed_text)
        line_items = self._extract_line_items(parsed_text, currency)

        if not line_items:
            return self._demo_fallback_response(parsed_text=parsed_text, merchant=merchant, parsed_date=parsed_date, total=total, currency=currency, source=source)

        category_totals = self._aggregate_category_totals(line_items)
        savings_recommendations = self._build_savings_recommendations(category_totals)

        return ReceiptParseResponse(
            merchant=merchant,
            date=parsed_date,
            total=total,
            currency=currency,
            line_items=line_items,
            category_totals=category_totals,
            savings_recommendations=savings_recommendations,
            parsed_text=parsed_text,
            source=source,
            metadata={"filename": filename, "content_type": content_type},
        )

    def _extract_text(self, image_bytes: bytes, filename: str | None, content_type: str | None) -> str:
        claude_text = self._extract_with_claude(image_bytes=image_bytes, filename=filename, content_type=content_type)
        if claude_text:
            return claude_text

        ocr_text = self._extract_with_ocr(image_bytes=image_bytes)
        if ocr_text:
            return ocr_text

        return ""

    def _extract_with_claude(self, image_bytes: bytes, filename: str | None, content_type: str | None) -> str:
        api_key = os.getenv("ANTHROPIC_API_KEY")
        if not api_key:
            return ""

        try:
            from anthropic import Anthropic
        except Exception:
            return ""

        media_type = content_type or "image/png"
        encoded = base64.b64encode(image_bytes).decode("ascii")
        client = Anthropic(api_key=api_key)
        response = client.messages.create(
            model=os.getenv("ANTHROPIC_MODEL", "claude-3-5-sonnet-latest"),
            max_tokens=1200,
            temperature=0,
            messages=[
                {
                    "role": "user",
                    "content": [
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
                            "text": (
                                "Read this receipt and return only the raw text content. "
                                "Preserve product lines, totals, dates, currency, and merchant name."
                            ),
                        },
                    ],
                }
            ],
        )

        return self._message_content_to_text(response)

    def _message_content_to_text(self, response: Any) -> str:
        content = getattr(response, "content", None)
        if not content:
            return ""
        parts: list[str] = []
        for block in content:
            text = getattr(block, "text", None)
            if text:
                parts.append(text)
        return "\n".join(parts).strip()

    def _extract_with_ocr(self, image_bytes: bytes) -> str:
        try:
            from PIL import Image
            import pytesseract
        except Exception:
            return ""

        image = Image.open(io.BytesIO(image_bytes))
        text = pytesseract.image_to_string(image)
        return text.strip()

    def _extract_merchant(self, parsed_text: str) -> str:
        for line in self._clean_lines(parsed_text):
            if not should_skip_line(line):
                return line[:80]
        return "Unknown merchant"

    def _extract_date(self, parsed_text: str) -> date | None:
        patterns = [
            r"(?P<date>\b\d{4}-\d{2}-\d{2}\b)",
            r"(?P<date>\b\d{2}/\d{2}/\d{4}\b)",
            r"(?P<date>\b\d{2}-\d{2}-\d{4}\b)",
        ]
        for pattern in patterns:
            match = re.search(pattern, parsed_text)
            if not match:
                continue
            raw_value = match.group("date")
            for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%d-%m-%Y"):
                try:
                    return datetime.strptime(raw_value, fmt).date()
                except ValueError:
                    continue
        return None

    def _extract_currency(self, parsed_text: str) -> str:
        upper = parsed_text.upper()
        if "€" in parsed_text or "EUR" in upper:
            return "EUR"
        if "$" in parsed_text or "USD" in upper:
            return "USD"
        if "£" in parsed_text or "GBP" in upper:
            return "GBP"
        return "EUR"

    def _extract_total(self, parsed_text: str) -> float | None:
        total_patterns = [r"total\s*[:\-]?\s*(?:€|\$|£)?\s*(\d+[\.,]\d{2})", r"(?:€|\$|£)\s*(\d+[\.,]\d{2})"]
        for pattern in total_patterns:
            matches = re.findall(pattern, parsed_text, flags=re.IGNORECASE)
            if matches:
                return self._parse_amount(matches[-1])
        return None

    def _extract_line_items(self, parsed_text: str, currency: str) -> list[ReceiptItem]:
        items: list[ReceiptItem] = []
        for raw_line in self._clean_lines(parsed_text):
            if should_skip_line(raw_line):
                continue
            parsed_item = self._parse_line_item(raw_line, currency)
            if parsed_item is not None:
                items.append(parsed_item)
        return items

    def _parse_line_item(self, line: str, currency: str) -> ReceiptItem | None:
        price_match = re.search(r"(\d+[\.,]\d{2})\s*$", line)
        if not price_match:
            return None

        raw_price = price_match.group(1)
        raw_name = line[: price_match.start()].strip(" -:\t")
        if not raw_name:
            return None

        normalized_name = normalize_product_name(raw_name)
        category = categorize_product(raw_name)
        return ReceiptItem(
            raw_name=raw_name,
            normalized_name=normalized_name,
            category=category,
            price=self._parse_amount(raw_price),
            quantity=1.0,
        )

    def _aggregate_category_totals(self, line_items: list[ReceiptItem]) -> dict[str, float]:
        totals: dict[str, float] = defaultdict(float)
        for item in line_items:
            totals[item.category] += item.price * item.quantity
        return dict(sorted(totals.items(), key=lambda entry: entry[0].lower()))

    def _build_savings_recommendations(self, category_totals: dict[str, float]) -> list[SavingsRecommendation]:
        recommendations: list[SavingsRecommendation] = []

        coffee_total = category_totals.get("Coffee", 0.0)
        if coffee_total:
            savings = round(coffee_total * 0.25, 2)
            recommendations.append(
                SavingsRecommendation(
                    category="Coffee",
                    message=f"Reducing coffee spending by 25% could save {self._format_currency(savings)}.",
                    potential_savings=savings,
                )
            )

        restaurant_total = category_totals.get("Restaurants", 0.0)
        if restaurant_total:
            savings = round(restaurant_total * 0.15, 2)
            recommendations.append(
                SavingsRecommendation(
                    category="Restaurants",
                    message=f"Cutting restaurant spending by 15% could save {self._format_currency(savings)}.",
                    potential_savings=savings,
                )
            )

        if not recommendations:
            recommendations.append(
                SavingsRecommendation(
                    category="General",
                    message="Track recurring purchases for a month to spot easy savings opportunities.",
                    potential_savings=0.0,
                )
            )

        return recommendations

    def _demo_fallback_response(
        self,
        parsed_text: str = "",
        merchant: str = "Demo Market",
        parsed_date: date | None = None,
        total: float | None = 18.75,
        currency: str = "EUR",
        source: str = "fallback",
    ) -> ReceiptParseResponse:
        line_items = [
            ReceiptItem(raw_name="Americano", normalized_name="americano", category="Coffee", price=3.75, quantity=1.0),
            ReceiptItem(raw_name="Croissant", normalized_name="croissant", category="Groceries", price=2.50, quantity=1.0),
            ReceiptItem(raw_name="Sandwich", normalized_name="sandwich", category="Restaurants", price=7.50, quantity=1.0),
            ReceiptItem(raw_name="Water", normalized_name="water", category="Groceries", price=5.00, quantity=1.0),
        ]
        category_totals = self._aggregate_category_totals(line_items)
        savings_recommendations = self._build_savings_recommendations(category_totals)
        return ReceiptParseResponse(
            merchant=merchant,
            date=parsed_date,
            total=total,
            currency=currency,
            line_items=line_items,
            category_totals=category_totals,
            savings_recommendations=savings_recommendations,
            parsed_text=parsed_text or "Demo receipt text",
            source=source,
            metadata={"demo": True},
        )

    def _clean_lines(self, parsed_text: str) -> list[str]:
        lines = [line.strip() for line in parsed_text.splitlines()]
        return [line for line in lines if line]

    def _parse_amount(self, value: str) -> float:
        normalized = value.replace(",", ".")
        return round(float(normalized), 2)

    def _format_currency(self, amount: float) -> str:
        return f"€{amount:.2f}"
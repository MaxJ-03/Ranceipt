from __future__ import annotations

import json

from app.receipts.categories import PRIMARY_CATEGORIES
from app.receipts.llm_schemas import ReceiptExtractionResult


def build_receipt_extraction_prompt() -> str:
    categories_text = ", ".join(PRIMARY_CATEGORIES)
    schema_json = json.dumps(ReceiptExtractionResult.model_json_schema(), ensure_ascii=True, indent=2)
    return (
        "You are extracting structured data from a grocery or retail receipt image. "
        "Return only valid JSON that matches the required schema. "
        "Never add prose, markdown, or explanations. "
        "\n\n"
        "Rules:\n"
        "1. merchant: the store or merchant name as a string.\n"
        "2. receipt_date: the receipt date in ISO 8601 date format (YYYY-MM-DD) if clearly visible, otherwise null.\n"
        "3. receipt_time: the explicit time only if it is clearly shown on the receipt, otherwise null. Use HH:MM or HH:MM:SS. Do not guess a time.\n"
        "4. currency: ISO code like EUR, USD, GBP. Infer from receipt symbols when needed.\n"
        "5. receipt_total: final paid amount as a number.\n"
        "6. category_totals: array of objects with category, quantity, and total.\n"
        "7. category must be one of the allowed categories.\n"
        "8. quantity must be numeric and non-negative.\n"
        "9. total must be numeric and non-negative.\n"
        "10. Include only categories that have non-zero totals in category_totals.\n"
        "11. Sum based on product-level interpretation from receipt lines.\n"
        "12. If uncertain, choose the closest allowed category. If nothing fits, omit that line item.\n"
        "\n"
        f"Allowed categories: {categories_text}.\n\n"
        "Use this JSON schema exactly:\n"
        f"{schema_json}"
    )
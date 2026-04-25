from __future__ import annotations

import re


PRIMARY_CATEGORIES = [
    "Coffee",
    "Groceries",
    "Restaurants",
    "Transport",
    "Subscriptions",
    "Entertainment",
    "Shopping",
    "Health",
    "Household",
    "Other",
]


CATEGORY_KEYWORDS = {
    "Coffee": ["coffee", "latte", "cappuccino", "espresso", "flat white", "americano", "mocha", "macchiato"],
    "Groceries": [
        "bread",
        "milk",
        "yogurt",
        "butter",
        "cheese",
        "eggs",
        "fruit",
        "vegetable",
        "meat",
        "fish",
        "rice",
        "pasta",
        "sugar",
        "flour",
        "snack",
        "cookie",
        "banana",
        "apple",
        "orange",
    ],
    "Restaurants": ["pizza", "burger", "restaurant", "cafe", "meal", "sandwich", "salad", "takeaway", "delivery"],
    "Transport": ["uber", "bolt", "taxi", "bus", "train", "tram", "metro", "parking", "fuel", "petrol", "diesel"],
    "Subscriptions": ["netflix", "spotify", "subscription", "membership", "prime", "youtube", "icloud"],
    "Entertainment": ["cinema", "movie", "game", "ticket", "concert", "theatre", "theater"],
    "Shopping": ["shirt", "shoes", "clothes", "store", "shop", "electronics", "book", "gift"],
    "Health": ["pharmacy", "medicine", "vitamin", "supplement", "clinic", "doctor", "toothpaste"],
    "Household": ["detergent", "soap", "paper", "tissue", "cleaner", "trash", "battery", "light bulb"],
}

SKIP_LINE_HINTS = ["subtotal", "sub total", "total", "vat", "tax", "change", "cash", "card", "balance", "tip"]


def normalize_product_name(product_name: str) -> str:
    cleaned = product_name.lower().strip()
    cleaned = re.sub(r"\b\d+[xX]?\b", " ", cleaned)
    cleaned = re.sub(r"[^a-z0-9€£$\s\-]", " ", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned.strip()


def categorize_product(product_name: str) -> str:
    normalized = normalize_product_name(product_name)
    for category, keywords in CATEGORY_KEYWORDS.items():
        if any(keyword in normalized for keyword in keywords):
            return category
    return "Other"


def should_skip_line(line: str) -> bool:
    lowered = line.lower()
    return any(hint in lowered for hint in SKIP_LINE_HINTS)
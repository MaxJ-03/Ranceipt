import base64
import json
import uuid
from pathlib import Path
from typing import Any

import httpx
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.hazmat.primitives.serialization import load_pem_private_key

from app.config import BUNQ_API_BASE_URL, BUNQ_SANDBOX_API_KEY


CONTEXT_DIR = Path(__file__).resolve().parents[2] / ".bunq_context"
PRIVATE_KEY_FILE = CONTEXT_DIR / "private_key.pem"
PUBLIC_KEY_FILE = CONTEXT_DIR / "public_key.pem"
DEVICE_TOKEN_FILE = CONTEXT_DIR / "device_token.json"


class BunqClient:
    def __init__(self):
        CONTEXT_DIR.mkdir(exist_ok=True)

        self.base_url = BUNQ_API_BASE_URL
        self.api_key = BUNQ_SANDBOX_API_KEY
        if not self.api_key:
            raise RuntimeError("BUNQ_SANDBOX_API_KEY is missing from backend/.env")

        self.private_key_pem, self.public_key_pem = self._load_or_create_keypair()
        self.device_token = self._load_device_token()

        self.session_token: str | None = None
        self.user_id: int | None = None

    def _load_or_create_keypair(self) -> tuple[str, str]:
        if PRIVATE_KEY_FILE.exists() and PUBLIC_KEY_FILE.exists():
            return (
                PRIVATE_KEY_FILE.read_text(),
                PUBLIC_KEY_FILE.read_text(),
            )

        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=default_backend(),
        )

        public_key = private_key.public_key()

        private_key_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        ).decode("utf-8")

        public_key_pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo,
        ).decode("utf-8")

        PRIVATE_KEY_FILE.write_text(private_key_pem)
        PUBLIC_KEY_FILE.write_text(public_key_pem)

        return private_key_pem, public_key_pem

    def _load_device_token(self) -> str | None:
        if not DEVICE_TOKEN_FILE.exists():
            return None

        data = json.loads(DEVICE_TOKEN_FILE.read_text())
        return data.get("device_token")

    def _save_device_token(self, token: str) -> None:
        DEVICE_TOKEN_FILE.write_text(json.dumps({"device_token": token}))

    def _sign_body(self, body: str) -> str:
        private_key = load_pem_private_key(
            self.private_key_pem.encode("utf-8"),
            password=None,
            backend=default_backend(),
        )

        signature = private_key.sign(
            body.encode("utf-8"),
            padding.PKCS1v15(),
            hashes.SHA256(),
        )

        return base64.b64encode(signature).decode("utf-8")

    def _headers(self, token: str | None = None, signature: str | None = None) -> dict[str, str]:
        headers = {
            "Content-Type": "application/json",
            "Cache-Control": "no-cache",
            "User-Agent": "Ranceipt",
            "X-Bunq-Language": "en_US",
            "X-Bunq-Region": "nl_NL",
            "X-Bunq-Geolocation": "0 0 0 0 000",
            "X-Bunq-Client-Request-Id": str(uuid.uuid4()),
        }

        if token:
            headers["X-Bunq-Client-Authentication"] = token

        if signature:
            headers["X-Bunq-Client-Signature"] = signature

        return headers

    def _extract_token(self, response_json: dict[str, Any]) -> str:
        for item in response_json.get("Response", []):
            if "Token" in item:
                return item["Token"]["token"]

        raise RuntimeError(f"Could not find Token in response: {response_json}")

    def _extract_user_id(self, response_json: dict[str, Any]) -> int:
        for item in response_json.get("Response", []):
            if "UserPerson" in item:
                return item["UserPerson"]["id"]

            if "UserCompany" in item:
                return item["UserCompany"]["id"]

        raise RuntimeError(f"Could not find user id in response: {response_json}")

    def _post_json(self, endpoint: str, body: dict[str, Any], token: str | None = None) -> dict[str, Any]:
        body_json = json.dumps(body, separators=(",", ":"))
        signature = self._sign_body(body_json) if token else None

        with httpx.Client(timeout=30) as client:
            response = client.post(
                f"{self.base_url}{endpoint}",
                headers=self._headers(token=token, signature=signature),
                content=body_json,
            )

        if response.status_code >= 400:
            raise RuntimeError(
                f"bunq POST {endpoint} failed: {response.status_code} {response.text}"
            )

        return response.json()

    def _get(self, endpoint: str) -> dict[str, Any]:
        if not self.session_token:
            raise RuntimeError("No bunq session token. Call ensure_session() first.")

        with httpx.Client(timeout=30) as client:
            response = client.get(
                f"{self.base_url}{endpoint}",
                headers=self._headers(token=self.session_token),
            )

        if response.status_code >= 400:
            raise RuntimeError(
                f"bunq GET {endpoint} failed: {response.status_code} {response.text}"
            )

        return response.json()

    def create_installation_if_needed(self) -> None:
        if self.device_token:
            return

        body = {
            "client_public_key": self.public_key_pem,
        }

        response_json = self._post_json("/installation", body)
        self.device_token = self._extract_token(response_json)
        self._save_device_token(self.device_token)

    def create_device_server(self) -> None:
        if not self.device_token:
            raise RuntimeError("Missing device token. Create installation first.")

        body = {
            "description": "Ranceipt local dev",
            "secret": self.api_key,
            "permitted_ips": ["*"],
        }

        self._post_json("/device-server", body, token=self.device_token)

    def create_session(self) -> None:
        if not self.device_token:
            raise RuntimeError("Missing device token. Create installation first.")

        body = {
            "secret": self.api_key,
        }

        response_json = self._post_json("/session-server", body, token=self.device_token)

        self.session_token = self._extract_token(response_json)
        self.user_id = self._extract_user_id(response_json)

    def ensure_session(self) -> None:
        self.create_installation_if_needed()

        try:
            self.create_session()
        except Exception:
            self.create_device_server()
            self.create_session()

    def get_general_categories(self) -> list[str]:
        self.ensure_session()

        response_json = self._get(
            f"/user/{self.user_id}/additional-transaction-information-category"
        )

        names = []

        for item in response_json.get("Response", []):
            category = item.get("AdditionalTransactionInformationCategory")
            if category and category.get("category"):
                names.append(self._prettify_bunq_category(category["category"]))

        return sorted(set(names))

    def get_monetary_accounts(self) -> list[dict[str, Any]]:
        self.ensure_session()

        response_json = self._get(f"/user/{self.user_id}/monetary-account-bank")

        accounts = []

        for item in response_json.get("Response", []):
            account = item.get("MonetaryAccountBank")
            if account:
                accounts.append(account)

        return accounts

    def get_primary_account_id(self) -> int:
        accounts = self.get_monetary_accounts()

        if not accounts:
            raise RuntimeError("No bunq monetary accounts found")

        return accounts[0]["id"]

    def get_payments_for_account(self, monetary_account_id: int) -> list[dict[str, Any]]:
        self.ensure_session()

        response_json = self._get(
            f"/user/{self.user_id}/monetary-account/{monetary_account_id}/payment?count=200"
        )

        payments = []

        for item in response_json.get("Response", []):
            payment = item.get("Payment")
            if payment:
                payments.append(payment)

        return payments

    def get_all_payments(self) -> list[dict[str, Any]]:
        accounts = self.get_monetary_accounts()
        all_payments = []

        for account in accounts:
            account_id = account["id"]
            payments = self.get_payments_for_account(account_id)
            all_payments.extend(payments)

        return all_payments

    def request_sandbox_money(self, amount: str = "500.00") -> dict:
        self.ensure_session()
        account_id = self.get_primary_account_id()

        body = {
            "amount_inquired": {
                "value": amount,
                "currency": "EUR",
            },
            "counterparty_alias": {
                "type": "EMAIL",
                "value": "sugardaddy@bunq.com",
                "name": "Sugar Daddy",
            },
            "description": "Ranceipt sandbox funding",
            "allow_bunqme": False,
        }

        return self._post_json(
            f"/user/{self.user_id}/monetary-account/{account_id}/request-inquiry",
            body,
            token=self.session_token,
        )

    def make_sandbox_payment(self, amount: str, description: str) -> dict:
        self.ensure_session()
        account_id = self.get_primary_account_id()

        body = {
            "amount": {
                "value": amount,
                "currency": "EUR",
            },
            "counterparty_alias": {
                "type": "EMAIL",
                "value": "sugardaddy@bunq.com",
                "name": "Sugar Daddy",
            },
            "description": description,
        }

        return self._post_json(
            f"/user/{self.user_id}/monetary-account/{account_id}/payment",
            body,
            token=self.session_token,
        )

    def create_demo_spending(self) -> list[dict]:
        demo_payments = [
            ("4.50", "Starbucks coffee"),
            ("18.90", "Albert Heijn groceries"),
            ("12.40", "Lunch sandwich"),
            ("7.20", "Prepared coffee drinks"),
            ("42.00", "Zara clothing"),
            ("9.99", "Spotify subscription"),
            ("24.60", "Uber ride"),
            ("16.80", "Pharmacy personal care"),
            ("31.50", "Restaurant dinner"),
            ("6.30", "Bakery pastries"),
        ]

        created = []

        for amount, description in demo_payments:
            response = self.make_sandbox_payment(
                amount=amount,
                description=description,
            )

            created.append(
                {
                    "amount": amount,
                    "description": description,
                    "bunq_response": response,
                }
            )

        return created

    @staticmethod
    def _prettify_bunq_category(value: str) -> str:
        if value == "HR":
            return "HR"

        return value.replace("_", " ").lower().capitalize()
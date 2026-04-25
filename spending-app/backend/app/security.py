import base64
import hashlib

from cryptography.fernet import Fernet

from app.database import settings


def _fernet() -> Fernet:
	raw_key = settings.token_encryption_key or settings.app_secret_key
	key_bytes = hashlib.sha256(raw_key.encode("utf-8")).digest()
	fernet_key = base64.urlsafe_b64encode(key_bytes)
	return Fernet(fernet_key)


def encrypt_token(raw_token: str) -> str:
	return _fernet().encrypt(raw_token.encode("utf-8")).decode("utf-8")


def decrypt_token(encrypted_token: str) -> str:
	return _fernet().decrypt(encrypted_token.encode("utf-8")).decode("utf-8")

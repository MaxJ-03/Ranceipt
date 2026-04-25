import hashlib
import secrets
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.security import encrypt_token
from app.services.bunq_client import BunqClient

router = APIRouter(prefix="/auth", tags=["auth"])

bearer_scheme = HTTPBearer()


def create_session_token() -> str:
    return secrets.token_urlsafe(32)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def create_app_session(db: Session, user_id: int) -> dict[str, object]:
    raw_token = create_session_token()
    token_hash = hash_token(raw_token)
    expires_at = datetime.utcnow() + timedelta(days=30)

    db.execute(
        text(
            """
            INSERT INTO app_sessions (
                user_id,
                session_token_hash,
                expires_at
            )
            VALUES (:user_id, :token_hash, :expires_at);
            """
        ),
        {
            "user_id": user_id,
            "token_hash": token_hash,
            "expires_at": expires_at,
        },
    )

    return {
        "session_token": raw_token,
        "expires_at": expires_at,
    }


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
):
    token = credentials.credentials
    token_hash = hash_token(token)

    user = db.execute(
        text(
            """
            SELECT u.id, u.created_at
            FROM app_sessions s
            JOIN users u ON u.id = s.user_id
            WHERE s.session_token_hash = :token_hash
              AND s.revoked = FALSE
              AND s.expires_at > NOW()
            LIMIT 1;
            """
        ),
        {"token_hash": token_hash},
    ).mappings().first()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid or expired session")

    return user


@router.post("/bunq/sandbox-login")
def bunq_sandbox_login(db: Session = Depends(get_db)):
    """
    Sandbox-only login endpoint.
    Uses BUNQ_SANDBOX_API_KEY from .env to establish a bunq sandbox session.
    Creates or reuses an internal user linked to that sandbox bunq user.
    Returns session_token for Flutter to use with Authorization: Bearer header.
    """
    try:
        client = BunqClient()
        client.ensure_session()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to establish bunq sandbox session: {str(exc)}")

    if not client.user_id:
        raise HTTPException(status_code=500, detail="Could not retrieve bunq sandbox user_id")

    bunq_sandbox_user_id = f"sandbox-user-{client.user_id}"

    connection = db.execute(
        text(
            """
            SELECT id, user_id
            FROM bunq_connections
            WHERE bunq_user_api_key_id = :bunq_user_api_key_id
            LIMIT 1;
            """
        ),
        {"bunq_user_api_key_id": bunq_sandbox_user_id},
    ).mappings().first()

    if connection:
        user_id = connection["user_id"]
    else:
        user = db.execute(
            text(
                """
                INSERT INTO users DEFAULT VALUES
                RETURNING id;
                """
            )
        ).mappings().first()

        user_id = user["id"]
        db.execute(
            text(
                """
                INSERT INTO bunq_connections (
                    user_id,
                    bunq_user_api_key_id
                )
                VALUES (
                    :user_id,
                    :bunq_user_api_key_id
                );
                """
            ),
            {
                "user_id": user_id,
                "bunq_user_api_key_id": bunq_sandbox_user_id,
            },
        )

    session = create_app_session(db, user_id)
    db.commit()

    return {
        "user_id": user_id,
        "session_token": session["session_token"],
        "bunq_sandbox_user_id": bunq_sandbox_user_id,
        "expires_at": session["expires_at"],
    }


@router.get("/me")
def me(user=Depends(get_current_user)):
    return user
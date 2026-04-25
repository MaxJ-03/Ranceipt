import hashlib
import secrets
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db

router = APIRouter(prefix="/auth", tags=["auth"])

bearer_scheme = HTTPBearer()
DEMO_BUNQ_IDENTITY = "sandbox-demo-user"


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
                expires_at,
                revoked
            )
            VALUES (
                :user_id,
                :token_hash,
                :expires_at,
                FALSE
            );
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


def get_or_create_demo_user(db: Session) -> int:
    connection = db.execute(
        text(
            """
            SELECT user_id
            FROM bunq_connections
            WHERE bunq_user_api_key_id = :bunq_user_api_key_id
            LIMIT 1;
            """
        ),
        {"bunq_user_api_key_id": DEMO_BUNQ_IDENTITY},
    ).mappings().first()

    if connection:
        return int(connection["user_id"])

    user = db.execute(
        text(
            """
            INSERT INTO users DEFAULT VALUES
            RETURNING id;
            """
        )
    ).mappings().first()

    user_id = int(user["id"])

    db.execute(
        text(
            """
            INSERT INTO bunq_connections (
                user_id,
                bunq_user_api_key_id,
                encrypted_access_token,
                last_synced_at
            )
            VALUES (
                :user_id,
                :bunq_user_api_key_id,
                :encrypted_access_token,
                NOW()
            )
            ON CONFLICT (bunq_user_api_key_id)
            DO UPDATE SET
                user_id = EXCLUDED.user_id,
                encrypted_access_token = EXCLUDED.encrypted_access_token,
                last_synced_at = NOW();
            """
        ),
        {
            "user_id": user_id,
            "bunq_user_api_key_id": DEMO_BUNQ_IDENTITY,
            "encrypted_access_token": "sandbox_demo_token",
        },
    )

    return user_id


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

    return dict(user)


@router.post("/bunq/sandbox-login")
def bunq_sandbox_login(db: Session = Depends(get_db)):
    user_id = get_or_create_demo_user(db)
    session = create_app_session(db, user_id)
    db.commit()

    return {
        "message": "bunq sandbox login successful",
        "user_id": user_id,
        "session_token": session["session_token"],
        "bunq_sandbox_user_id": DEMO_BUNQ_IDENTITY,
        "account_count": 1,
        "expires_at": session["expires_at"],
    }


@router.get("/me")
def me(user=Depends(get_current_user)):
    return user
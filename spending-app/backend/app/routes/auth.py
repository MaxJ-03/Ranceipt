import hashlib
import secrets
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from psycopg import Connection

from app.database import get_db

router = APIRouter(prefix="/auth", tags=["auth"])

bearer_scheme = HTTPBearer()


def create_session_token() -> str:
    return secrets.token_urlsafe(32)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Connection = Depends(get_db),
):
    token = credentials.credentials
    token_hash = hash_token(token)

    with db.cursor() as cur:
        cur.execute(
            """
            SELECT u.id, u.created_at
            FROM app_sessions s
            JOIN users u ON u.id = s.user_id
            WHERE s.session_token_hash = %s
              AND s.revoked = FALSE
              AND s.expires_at > NOW()
            LIMIT 1;
            """,
            (token_hash,),
        )

        user = cur.fetchone()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid or expired session")

    return user


@router.post("/dev-login")
def dev_login(db: Connection = Depends(get_db)):
    """
    Temporary dev login.
    Later this gets replaced by real bunq OAuth login.
    """

    raw_token = create_session_token()
    token_hash = hash_token(raw_token)
    expires_at = datetime.utcnow() + timedelta(days=7)

    with db.cursor() as cur:
        cur.execute(
            """
            INSERT INTO users DEFAULT VALUES
            RETURNING id, created_at;
            """
        )
        user = cur.fetchone()

        cur.execute(
            """
            INSERT INTO app_sessions (
                user_id,
                session_token_hash,
                expires_at
            )
            VALUES (%s, %s, %s);
            """,
            (
                user["id"],
                token_hash,
                expires_at,
            ),
        )

    db.commit()

    return {
        "user_id": user["id"],
        "session_token": raw_token,
        "expires_at": expires_at,
    }


@router.get("/me")
def me(user=Depends(get_current_user)):
    return user
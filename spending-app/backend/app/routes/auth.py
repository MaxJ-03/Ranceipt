import hashlib
import os
import secrets
import base64
import json
from datetime import datetime, timedelta
from urllib.parse import urlencode

import httpx
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.security import encrypt_token

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


class BunqOAuthCompleteRequest(BaseModel):
    state: str
    bunq_user_api_key_id: str
    bunq_access_token: str


class BunqOAuthCodeCompleteRequest(BaseModel):
    state: str
    code: str


def _decode_jwt_sub(token: str | None) -> str | None:
    if not token or "." not in token:
        return None

    parts = token.split(".")
    if len(parts) < 2:
        return None

    payload = parts[1]
    padding = "=" * (-len(payload) % 4)

    try:
        decoded = base64.urlsafe_b64decode(payload + padding)
        data = json.loads(decoded.decode("utf-8"))
    except Exception:
        return None

    sub = data.get("sub")
    return str(sub) if sub is not None else None


def _extract_access_token(payload: dict) -> str:
    access_token = (
        payload.get("access_token")
        or payload.get("token")
        or payload.get("accessToken")
    )

    if not access_token:
        raise HTTPException(status_code=500, detail="OAuth token exchange did not return an access token")

    return str(access_token)


def _extract_bunq_identity(payload: dict) -> str:
    candidates = [
        payload.get("bunq_user_api_key_id"),
        payload.get("user_api_key_id"),
        payload.get("user_id"),
        payload.get("sub"),
        payload.get("id"),
    ]

    user_payload = payload.get("user")
    if isinstance(user_payload, dict):
        candidates.extend(
            [
                user_payload.get("id"),
                user_payload.get("sub"),
                user_payload.get("user_id"),
            ]
        )

    jwt_sub = _decode_jwt_sub(payload.get("id_token"))
    if jwt_sub:
        candidates.append(jwt_sub)

    for candidate in candidates:
        if candidate is not None and str(candidate).strip():
            return str(candidate)

    raise HTTPException(
        status_code=500,
        detail=(
            "OAuth token response does not include a stable bunq user identifier. "
            "Ensure your provider returns one of: bunq_user_api_key_id, user_api_key_id, user_id, sub, or id."
        ),
    )


def _exchange_bunq_oauth_code(code: str) -> tuple[str, str]:
    token_url = os.getenv("BUNQ_OAUTH_TOKEN_URL")
    client_id = os.getenv("BUNQ_OAUTH_CLIENT_ID")
    client_secret = os.getenv("BUNQ_OAUTH_CLIENT_SECRET")
    redirect_uri = os.getenv("BUNQ_OAUTH_REDIRECT_URI")

    if not token_url or not client_id or not client_secret or not redirect_uri:
        raise HTTPException(
            status_code=500,
            detail=(
                "bunq OAuth token exchange is not configured. "
                "Set BUNQ_OAUTH_TOKEN_URL, BUNQ_OAUTH_CLIENT_ID, BUNQ_OAUTH_CLIENT_SECRET, and BUNQ_OAUTH_REDIRECT_URI."
            ),
        )

    body = {
        "grant_type": "authorization_code",
        "code": code,
        "client_id": client_id,
        "client_secret": client_secret,
        "redirect_uri": redirect_uri,
    }

    try:
        response = httpx.post(token_url, data=body, timeout=20)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"OAuth token exchange failed: {exc}") from exc

    if response.status_code >= 400:
        raise HTTPException(
            status_code=502,
            detail=f"OAuth token exchange failed: {response.status_code} {response.text}",
        )

    try:
        payload = response.json()
    except ValueError as exc:
        raise HTTPException(status_code=502, detail="OAuth token exchange returned invalid JSON") from exc

    if not isinstance(payload, dict):
        raise HTTPException(status_code=502, detail="OAuth token exchange returned an unexpected payload")

    access_token = _extract_access_token(payload)
    bunq_identity = _extract_bunq_identity(payload)
    return bunq_identity, access_token


def _complete_bunq_login(db: Session, *, state: str, bunq_user_api_key_id: str, bunq_access_token: str) -> dict:
    state_row = db.execute(
        text(
            """
            SELECT id, used
            FROM oauth_states
            WHERE state = :state
            LIMIT 1;
            """
        ),
        {"state": state},
    ).mappings().first()

    if not state_row or state_row["used"]:
        raise HTTPException(status_code=400, detail="Invalid or already used OAuth state")

    db.execute(
        text(
            """
            UPDATE oauth_states
            SET used = TRUE
            WHERE id = :id;
            """
        ),
        {"id": state_row["id"]},
    )

    encrypted_access_token = encrypt_token(bunq_access_token)

    connection = db.execute(
        text(
            """
            SELECT id, user_id
            FROM bunq_connections
            WHERE bunq_user_api_key_id = :bunq_user_api_key_id
            LIMIT 1;
            """
        ),
        {"bunq_user_api_key_id": bunq_user_api_key_id},
    ).mappings().first()

    if connection:
        user_id = connection["user_id"]
        db.execute(
            text(
                """
                UPDATE bunq_connections
                SET encrypted_access_token = :encrypted_access_token
                WHERE id = :id;
                """
            ),
            {
                "encrypted_access_token": encrypted_access_token,
                "id": connection["id"],
            },
        )
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
                    bunq_user_api_key_id,
                    encrypted_access_token
                )
                VALUES (
                    :user_id,
                    :bunq_user_api_key_id,
                    :encrypted_access_token
                );
                """
            ),
            {
                "user_id": user_id,
                "bunq_user_api_key_id": bunq_user_api_key_id,
                "encrypted_access_token": encrypted_access_token,
            },
        )

    session = create_app_session(db, user_id)
    db.commit()

    return {
        "user_id": user_id,
        "session_token": session["session_token"],
        "expires_at": session["expires_at"],
    }


@router.get("/bunq/start")
def bunq_oauth_start(db: Session = Depends(get_db)):
    client_id = os.getenv("BUNQ_OAUTH_CLIENT_ID")
    redirect_uri = os.getenv("BUNQ_OAUTH_REDIRECT_URI")
    authorize_url = os.getenv("BUNQ_OAUTH_AUTHORIZE_URL")

    if not client_id or not redirect_uri or not authorize_url:
        raise HTTPException(
            status_code=500,
            detail=(
                "bunq OAuth is not configured. "
                "Set BUNQ_OAUTH_CLIENT_ID, BUNQ_OAUTH_REDIRECT_URI, and BUNQ_OAUTH_AUTHORIZE_URL."
            ),
        )

    state = secrets.token_urlsafe(32)
    db.execute(
        text(
            """
            INSERT INTO oauth_states (state)
            VALUES (:state);
            """
        ),
        {"state": state},
    )
    db.commit()

    params = urlencode(
        {
            "response_type": "code",
            "client_id": client_id,
            "redirect_uri": redirect_uri,
            "state": state,
        }
    )

    return {
        "state": state,
        "authorization_url": f"{authorize_url}?{params}",
    }


@router.post("/bunq/complete")
def bunq_oauth_complete(body: BunqOAuthCompleteRequest, db: Session = Depends(get_db)):
    return _complete_bunq_login(
        db,
        state=body.state,
        bunq_user_api_key_id=body.bunq_user_api_key_id,
        bunq_access_token=body.bunq_access_token,
    )


@router.post("/bunq/complete-with-code")
def bunq_oauth_complete_with_code(body: BunqOAuthCodeCompleteRequest, db: Session = Depends(get_db)):
    bunq_user_api_key_id, bunq_access_token = _exchange_bunq_oauth_code(body.code)

    return _complete_bunq_login(
        db,
        state=body.state,
        bunq_user_api_key_id=bunq_user_api_key_id,
        bunq_access_token=bunq_access_token,
    )


@router.get("/me")
def me(user=Depends(get_current_user)):
    return user
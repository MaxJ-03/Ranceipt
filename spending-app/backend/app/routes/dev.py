from fastapi import APIRouter, Depends
from psycopg import Connection
from app.database import get_db

router = APIRouter(prefix="/dev", tags=["dev"])


@router.post("/user")
def create_test_user(db: Connection = Depends(get_db)):
    with db.cursor() as cur:
        cur.execute(
            """
            INSERT INTO users DEFAULT VALUES
            RETURNING id, created_at;
            """
        )
        user = cur.fetchone()

    db.commit()
    return user
from fastapi import FastAPI

from app.routes.auth import router as auth_router
from app.routes.bunq import router as bunq_router
from app.routes.categories import router as categories_router
from app.routes.personal_goals import router as personal_goals_router
from app.routes.receipts import router as receipts_router
from app.routes.transactions import router as transactions_router


app = FastAPI(title="Spending App API", version="0.1.0")


@app.get("/health")
def health_check() -> dict[str, str]:
	return {"status": "ok"}


app.include_router(auth_router)
app.include_router(categories_router)
app.include_router(transactions_router)
app.include_router(personal_goals_router)
app.include_router(receipts_router)
app.include_router(bunq_router)
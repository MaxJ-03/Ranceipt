from fastapi import FastAPI

from app.routes.personal_goals import router as personal_goals_router
from app.routes.receipts import router as receipts_router


app = FastAPI(title="Spending App API", version="0.1.0")

app.include_router(receipts_router)
app.include_router(personal_goals_router)


@app.get("/health")
def health_check() -> dict[str, str]:
	return {"status": "ok"}

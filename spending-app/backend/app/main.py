import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.auth import router as auth_router
from app.routes.bunq import router as bunq_router
from app.routes.categories import router as categories_router
from app.routes.demo import router as demo_router
from app.routes.goals import router as goals_router
from app.routes.personal_goals import router as personal_goals_router
from app.routes.receipts import router as receipts_router
from app.routes.transactions import router as transactions_router


app = FastAPI(title="Spending App API", version="0.1.0")

cors_origins_env = os.getenv("CORS_ALLOW_ORIGINS")
if cors_origins_env:
	cors_origins = [origin.strip() for origin in cors_origins_env.split(",") if origin.strip()]
else:
	cors_origins = [
		"http://localhost:60605",
		"http://127.0.0.1:60605",
		"http://localhost:3000",
		"http://127.0.0.1:3000",
	]

app.add_middleware(
	CORSMiddleware,
	allow_origins=cors_origins,
	allow_origin_regex=r"http://(localhost|127\.0\.0\.1):\d+",
	allow_credentials=False,
	allow_methods=["*"],
	allow_headers=["*"],
)


@app.get("/health")
def health_check() -> dict[str, str]:
	return {"status": "ok"}


app.include_router(auth_router)
app.include_router(categories_router)
app.include_router(transactions_router)
app.include_router(goals_router)
app.include_router(personal_goals_router)
app.include_router(receipts_router)
app.include_router(bunq_router)
app.include_router(demo_router)
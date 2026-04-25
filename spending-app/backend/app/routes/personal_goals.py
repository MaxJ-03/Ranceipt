from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.personal_goals.llm_schemas import SpendingInsightsResult
from app.personal_goals.repository import PersonalGoalsRepository
from app.personal_goals.service import SpendingInsightsService

router = APIRouter(prefix="/personal-goals", tags=["personal-goals"])


@router.get("/{user_id}/insights", response_model=SpendingInsightsResult)
def get_spending_insights(user_id: int, db: Session = Depends(get_db)) -> SpendingInsightsResult:
    """
    Get spending insights and recommendations based on the last 30 days of receipts.
    """
    repository = PersonalGoalsRepository(db)
    service = SpendingInsightsService(repository)
    insights = service.analyze_spending(user_id)
    return insights

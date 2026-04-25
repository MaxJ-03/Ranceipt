import os
from decimal import Decimal

from app.personal_goals.llm_schemas import SpendingInsightsResult
from app.personal_goals.repository import PersonalGoalsRepository


class SpendingInsightsService:
    def __init__(self, repository: PersonalGoalsRepository):
        self.repository = repository

    def analyze_spending(self, user_id: int) -> SpendingInsightsResult:
        """Analyze user spending for the last 30 days and generate recommendations."""
        # Get spending data
        spending_by_category = self.repository.get_last_30_days_spending(user_id)
        total_spending = self.repository.get_total_spending_last_30_days(user_id)

        # Format spending data for the prompt
        spending_text = "\n".join(
            [f"- {category}: €{amount:.2f}" for category, amount in spending_by_category.items()]
        )

        # Build the analysis prompt
        prompt = self._build_analysis_prompt(spending_text, total_spending, list(spending_by_category.keys()))

        # Call Claude with structured output
        insights = self._extract_with_langchain(prompt)
        return insights

    def _build_analysis_prompt(self, spending_text: str, total_spending: Decimal, categories: list[str]) -> str:
        return f"""Analyze the following spending data for a user over the last 30 days and provide insights and recommendations.

Total Spending: €{total_spending:.2f}

Spending by Category:
{spending_text}

Please analyze this spending pattern and provide:
1. A summary of their spending habits
2. The total amount spent
3. Top 3 categories by spending
4. Specific, actionable recommendations for reducing spending in the highest-cost categories
5. An estimate of how much they could save by following the recommendations

Be practical and constructive in your recommendations."""

    def _extract_with_langchain(self, prompt: str) -> SpendingInsightsResult:
        from app.settings import settings

        api_key = settings.anthropic_api_key
        if not api_key:
            raise RuntimeError("ANTHROPIC_API_KEY is not set")

        try:
            from langchain_anthropic import ChatAnthropic
            from langchain_core.messages import HumanMessage
        except Exception:
            raise RuntimeError("langchain-anthropic or langchain-core package is not installed")

        llm = ChatAnthropic(
            model=settings.anthropic_model,
            api_key=api_key,
            max_tokens=2000,
            temperature=0,
        )
        structured_llm = llm.with_structured_output(SpendingInsightsResult)

        message = HumanMessage(content=prompt)
        result = structured_llm.invoke([message])

        return result

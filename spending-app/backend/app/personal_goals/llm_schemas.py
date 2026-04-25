from pydantic import BaseModel, Field


class CategoryRecommendation(BaseModel):
    category: str = Field(description="The product category name")
    current_spending: float = Field(description="Amount spent in this category in the last 30 days")
    recommendation: str = Field(description="Recommendation to reduce spending in this category")


class SpendingInsightsResult(BaseModel):
    summary: str = Field(description="Overall summary of spending patterns")
    total_spending: float = Field(description="Total spending in the last 30 days")
    top_categories: list[str] = Field(description="Top 3 categories by spending amount")
    recommendations: list[CategoryRecommendation] = Field(
        description="Specific recommendations for reducing spending in high-cost categories"
    )
    potential_savings: float = Field(
        description="Estimated amount that could be saved by following recommendations"
    )

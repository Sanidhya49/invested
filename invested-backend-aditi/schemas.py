# schemas.py
from pydantic import BaseModel, EmailStr, Field
from datetime import date
from typing import List, Literal, Optional
from uuid import UUID, uuid4 # Import UUID and uuid4
# Schema for the user profile based on the Profile screen
class UserProfile(BaseModel):
    name: str
    email: EmailStr

# Schema for the home screen's net worth card
class NetWorth(BaseModel):
    total_value: float
    change_percentage_this_month: float

# Schema for an individual investment based on the Investments screen
class Investment(BaseModel):
    type: str  # e.g., "Mutual Funds", "Stocks"
    value: float
    returns_percentage: float

# Schema for the complete Investment Portfolio
class InvestmentPortfolio(BaseModel):
    total_value: float
    total_returns_percentage: float
    investments: List[Investment]
    
from datetime import date
from typing import List, Literal # Make sure to import these

# Schema for an individual financial goal
class FinancialGoal(BaseModel):
    goal_id: UUID = Field(default_factory=uuid4) # Add a unique ID
    title: str
    target_date: date
    progress_percentage: int
    current_amount: float
    target_amount: float

class UpdateFinancialGoal(BaseModel):
    # All fields are optional, so the user can update just one thing
    title: Optional[str] = None
    target_date: Optional[date] = None
    progress_percentage: Optional[int] = None
    current_amount: Optional[float] = None
    target_amount: Optional[float] = None
# Schema for an individual subscription
class Subscription(BaseModel):
    name: str
    status: Literal["active", "unused"] # Restricts status to only these two values
    last_used: str # e.g., "2 days ago"
    cost_per_month: int

# Schema for the complete subscriptions page
class SubscriptionInfo(BaseModel):
    monthly_total: int
    potentially_unused_savings: int
    subscriptions: List[Subscription]
from fastapi import FastAPI, HTTPException
from typing import List
from fastapi.responses import JSONResponse
import services
import pipelines
from fastapi.concurrency import run_in_threadpool # <-- Import this
import engine # <-- Import our new engine file

import schemas

app = FastAPI(
    title="Financial Intelligence API",
    description="Backend services for the financial health app.",
    version="0.1.0"
)

@app.get("/")
def read_root():
    return {"message": "Welcome to your Financial Intelligence App Backend!"}

# NEW ENDPOINT
@app.get("/home/{user_id}", response_model=schemas.NetWorth)
def get_user_net_worth(user_id: int):
    """
    Returns the net worth for a given user.
    This is placeholder data based on the screenshot.
    """
    # In the future, this data will come from your Custom Intelligence Engine
    return schemas.NetWorth(
        total_value=2850000, 
        change_percentage_this_month=12.5
    )

# NEW ENDPOINT
@app.get("/investments/{user_id}", response_model=schemas.InvestmentPortfolio)
def get_investment_portfolio(user_id: int):
    """
    Returns the investment portfolio for a given user.
    Placeholder data based on screenshots.
    """
    # This data will eventually be calculated from Fi MCP data
    return schemas.InvestmentPortfolio(
        total_value=27.0 * 100000, # 27.0L
        total_returns_percentage=12.8,
        investments=[
            schemas.Investment(type="Mutual Funds", value=1200000, returns_percentage=12.5),
            schemas.Investment(type="Stocks", value=850000, returns_percentage=15.2),
            schemas.Investment(type="Fixed Deposits", value=400000, returns_percentage=6.8),
        ]
    )
    
    """
    Returns the list of financial goals for a given user.
    Placeholder data from screenshots.
    """
    return [
        schemas.FinancialGoal(
            title="Emergency Fund",
            target_date="2025-12-31",
            progress_percentage=64,
            current_amount=320000,
            target_amount=500000
        ),
        schemas.FinancialGoal(
            title="Home Down Payment",
            target_date="2026-06-30",
            progress_percentage=43,
            current_amount=850000,
            target_amount=2000000
        ),
        schemas.FinancialGoal(
            title="Retirement Planning",
            target_date="2045-12-31",
            progress_percentage=12,
            current_amount=0, # Assuming Current is not shown, let's put 0
            target_amount=0  # Assuming Target is not shown, let's put 0
        )
    ]
    

# 1. In-memory "database" for goals
# We use a dictionary to store goals for different users
# db_goals = {
#     1: [
#         schemas.FinancialGoal(goal_id="f9b4c2a0-7d1a-4b3e-9c7b-7e6a1d4f2b0a", title="Emergency Fund", target_date="2025-12-31", progress_percentage=64, current_amount=320000, target_amount=500000),
#         schemas.FinancialGoal(goal_id="a1b2c3d4-e5f6-7890-1234-567890abcdef", title="Home Down Payment", target_date="2026-06-30", progress_percentage=43, current_amount=850000, target_amount=2000000),
#         schemas.FinancialGoal(goal_id="b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e", title="Retirement Planning", target_date="2045-12-31", progress_percentage=12, current_amount=1200000, target_amount=10000000)
#     ]
# }

# 2. UPDATE the existing GET endpoint for Goals
@app.get("/goals/{user_id}", response_model=List[schemas.FinancialGoal])
async def get_financial_goals(user_id: int): # <-- Add async here
    """
    Returns the list of financial goals by fetching from the MCP mock server.
    NOTE: The user_id is unused for now as the mock server returns a single list.
    """
    mcp_goals = await services.fetch_goals_from_mcp()
    if not mcp_goals:
        raise HTTPException(status_code=404, detail="Could not fetch goals from MCP server.")

    # We need to parse the raw data into our Pydantic model
    return [schemas.FinancialGoal(**goal) for goal in mcp_goals]

# 3. ADD the new POST endpoint for Goals
# @app.post("/goals/{user_id}", response_model=schemas.FinancialGoal, status_code=201)
# def create_financial_goal(user_id: int, goal: schemas.FinancialGoal):
#     """
#     Adds a new financial goal to a user's list.
#     """
#     if user_id not in db_goals:
#         db_goals[user_id] = []

#     db_goals[user_id].append(goal)
#     return goal

# @app.put("/goals/{user_id}/{goal_id}", response_model=schemas.FinancialGoal)
# def update_financial_goal(user_id: int, goal_id: UUID, goal_update: schemas.UpdateFinancialGoal):
#     """
#     Updates an existing financial goal.
#     """
#     user_goals = db_goals.get(user_id)
#     if not user_goals:
#         raise HTTPException(status_code=404, detail="User not found")

#     for i, g in enumerate(user_goals):
#         if g.goal_id == goal_id:
#             # Get existing goal data as a dict
#             update_data = goal_update.dict(exclude_unset=True)
#             # Update the existing goal with the new data
#             updated_goal = g.copy(update=update_data)
#             db_goals[user_id][i] = updated_goal
#             return updated_goal

#     raise HTTPException(status_code=404, detail="Goal not found")

# # ADD the new DELETE endpoint
# @app.delete("/goals/{user_id}/{goal_id}", status_code=204)
# def delete_financial_goal(user_id: int, goal_id: UUID):
#     """
#     Deletes a financial goal.
#     """
#     user_goals = db_goals.get(user_id)
#     if not user_goals:
#         raise HTTPException(status_code=404, detail="User not found")

#     original_len = len(user_goals)
#     db_goals[user_id] = [g for g in user_goals if g.goal_id != goal_id]

#     if len(db_goals[user_id]) == original_len:
#         raise HTTPException(status_code=404, detail="Goal not found")

#     return # Return nothing, as indicated by status_code=204

# NEW ENDPOINT for Subscriptions
@app.get("/subscriptions/{user_id}", response_model=schemas.SubscriptionInfo)
def get_subscriptions(user_id: int):
    """
    Returns subscription info for a given user.
    Placeholder data from screenshots.
    """
    return schemas.SubscriptionInfo(
        monthly_total=4967,
        potentially_unused_savings=2500,
        subscriptions=[
            schemas.Subscription(name="Netflix", status="active", last_used="2 days ago", cost_per_month=649),
            schemas.Subscription(name="Spotify", status="active", last_used="1 day ago", cost_per_month=119),
            schemas.Subscription(name="Gym Membership", status="unused", last_used="45 days ago", cost_per_month=2500),
            schemas.Subscription(name="Adobe Creative", status="active", last_used="5 days ago", cost_per_month=1699),
        ]
    )


@app.get("/analysis/spending-summary")
async def get_spending_summary():
    """
    Fetches transactions, processes them, and returns a spending summary by category.
    """
    raw_transactions = await services.fetch_transactions_from_mcp()
    if not raw_transactions:
        raise HTTPException(status_code=500, detail="Could not fetch transaction data.")

    processed_df = pipelines.process_transactions(raw_transactions)

    # Filter for only expenses (DEBIT) and group by category
    spending_summary = processed_df[processed_df['type'] == 'DEBIT']\
        .groupby('category')['amount'].sum().round(2)

    # Convert the pandas Series to a JSON-friendly dictionary
    summary_dict = spending_summary.to_dict()

    return JSONResponse(content=summary_dict)

@app.get("/analysis/finhealth-score")
async def get_finhealth_score():
    """
    Calculates and returns the user's financial health score.
    """
    # 1. Fetch all required data
    raw_transactions = await services.fetch_transactions_from_mcp()
    investments_data = await services.fetch_investments_from_mcp()

    if not raw_transactions or not investments_data:
        raise HTTPException(status_code=500, detail="Could not fetch all required financial data.")

    # 2. Process transactions
    processed_df = pipelines.process_transactions(raw_transactions)

    # 3. Calculate the score
    score_data = pipelines.calculate_financial_health_score(processed_df, investments_data)

    return JSONResponse(content=score_data)

@app.get("/ai/categorize-transaction")
async def ai_categorize_transaction(description: str):
    """
    Takes a transaction description and uses Gemini to categorize it.
    """
    try:
        # Run the synchronous Gemini function in a thread pool
        category = await run_in_threadpool(engine.categorize_transaction_with_gemini, description)
        return {"description": description, "category": category}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")
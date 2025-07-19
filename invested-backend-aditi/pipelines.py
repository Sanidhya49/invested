# pipelines.py
import pandas as pd
from typing import List, Dict

def categorize_transaction(description: str) -> str:
    """A simple function to categorize transactions based on keywords."""
    desc = description.lower()
    if any(keyword in desc for keyword in ['zomato', 'swiggy']):
        return 'Food & Dining'
    if 'salary' in desc:
        return 'Income'
    if 'uber' in desc:
        return 'Transport'
    if 'netflix' in desc:
        return 'Entertainment'
    if 'sip' in desc or 'mutual fund' in desc:
        return 'Investments'
    if 'rent' in desc:
        return 'Rent & Utilities'
    if 'groceries' in desc:
        return 'Groceries'
    return 'Other'

def process_transactions(transactions_data: List[Dict]) -> pd.DataFrame:
    """
    Takes raw transaction data, cleans it, categorizes it, and returns a DataFrame.
    """
    if not transactions_data:
        return pd.DataFrame()

    df = pd.DataFrame(transactions_data)
    df['date'] = pd.to_datetime(df['date'])
    df['category'] = df['description'].apply(categorize_transaction)
    return df

def calculate_financial_health_score(transactions_df: pd.DataFrame, investments_data: Dict) -> Dict:
    """
    Calculates a financial health score based on savings, investments, and emergency fund.
    """
    score = 0
    breakdown = {}

    # --- 1. Savings Rate (Max 40 points) ---
    income = transactions_df[transactions_df['type'] == 'CREDIT']['amount'].sum()
    spending = transactions_df[transactions_df['type'] == 'DEBIT']['amount'].sum()
    
    # Avoid division by zero if there's no income
    savings_rate = 0
    if income > 0:
        savings_rate = (income - spending) / income

    if savings_rate > 0.20: # Saving more than 20%
        score += 40
    elif savings_rate > 0.10: # Saving 10-20%
        score += 25
    else: # Saving less than 10%
        score += 10
    breakdown['savings_score'] = score

    # --- 2. Emergency Fund (Max 30 points) ---
    # For now, we'll hardcode the 64% progress from your UI.
    # Later, this would come from the goals data.
    emergency_fund_progress = 0.64 
    if emergency_fund_progress > 0.9:
        score += 30
    elif emergency_fund_progress > 0.5:
        score += 20
    else:
        score += 5
    breakdown['emergency_fund_score'] = score - breakdown['savings_score']


    # --- 3. Investment Level (Max 30 points) ---
    total_investments = investments_data.get('total_value', 0)
    # Annualize the monthly income
    annual_income = income * 12
    
    investment_ratio = 0
    if annual_income > 0:
        investment_ratio = total_investments / annual_income

    if investment_ratio > 1: # Investments are > 1x annual income
        score += 30
    elif investment_ratio > 0.5: # Investments are 0.5x - 1x annual income
        score += 20
    else:
        score += 10
    breakdown['investment_score'] = score - breakdown['savings_score'] - breakdown['emergency_fund_score']

    breakdown['total_score'] = score
    return breakdown
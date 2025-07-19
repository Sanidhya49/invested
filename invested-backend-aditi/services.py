# services.py
import httpx
from typing import List, Dict

# The base URL of the mock server we just started
MCP_MOCK_SERVER_URL = "http://localhost:8080"

async def fetch_transactions_from_mcp() -> List[Dict]:
    """
    Fetches transaction data from the simple Python mock server.
    """
    async with httpx.AsyncClient() as client:
        try:
            # IMPORTANT: The path must include the full filename
            response = await client.get(f"{MCP_MOCK_SERVER_URL}/transactions.json")
            response.raise_for_status()
            return response.json()
        except httpx.RequestError as exc:
            print(f"An error occurred while requesting {exc.request.url!r}.")
            return []
        

async def fetch_investments_from_mcp() -> Dict:
    """
    Fetches investment portfolio data from the simple Python mock server.
    """
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{MCP_MOCK_SERVER_URL}/investments.json")
            response.raise_for_status()
            return response.json()
        except httpx.RequestError as exc:
            print(f"An error occurred while requesting {exc.request.url!r}.")
            return {} # Return empty dict on failure
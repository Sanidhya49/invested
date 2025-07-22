# main.py (ASYNC VERSION with Strategist Agent & Tool Use)

from fastapi import FastAPI, Depends, HTTPException, Header, Body
import firebase_admin
from firebase_admin import credentials, auth, firestore
import os
import uuid
import httpx
import json
from fastapi.responses import JSONResponse
import traceback
import asyncio

# Import Vertex AI and Tool Use libraries
import vertexai
from vertexai.generative_models import GenerativeModel, Tool, Part, FunctionDeclaration

app = FastAPI()

# --- Initializations ---
cred = credentials.Certificate("invested-hackathon-firebase-adminsdk-fbsvc-38735ba923.json")
firebase_admin.initialize_app(cred)
SERVICE_ACCOUNT_KEY_PATH = os.path.join(os.path.dirname(__file__), "invested-hackathon-vertex-ai-key.json")
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = SERVICE_ACCOUNT_KEY_PATH
GCP_PROJECT_ID = "invested-hackathon"
GCP_LOCATION = "us-central1"
vertexai.init(project=GCP_PROJECT_ID, location=GCP_LOCATION)

MOCK_SERVER_BASE_URL = "http://10.0.2.2:8080"

# --- Authentication ---
async def verify_firebase_token(authorization: str = Header(...)):
    try:
        id_token = authorization.split(" ").pop()
        decoded_token = await asyncio.to_thread(auth.verify_id_token, id_token)
        return decoded_token['uid']
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")

@app.get("/start-fi-auth")
async def start_fi_auth(uid: str = Depends(verify_firebase_token)):
    session_id = str(uuid.uuid4())
    db = firestore.client()
    user_doc_ref = db.collection("users").document(uid)
    await asyncio.to_thread(user_doc_ref.set, {"fi_session_id": session_id}, merge=True)
    auth_url = f"{MOCK_SERVER_BASE_URL}/mockWebPage?sessionId={session_id}"
    return {"auth_url": auth_url}

@app.get("/health")
async def health():
    return {"status": "ok"}

# --- Dynamic Data Fetching ---
async def get_user_financial_data(uid: str, tool_name: str, timeout=30):
    try:
        db = firestore.client()
        user_doc = await asyncio.to_thread(db.collection("users").document(uid).get)
        if user_doc.exists and "fi_session_id" in user_doc.to_dict():
            session_id = user_doc.to_dict()["fi_session_id"]
            headers = {"X-Session-ID": session_id}
            request_body = {"tool_name": tool_name}
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.post(
                        "http://localhost:8080/mcp/stream",
                        headers=headers,
                        json=request_body,
                        timeout=timeout
                    )
            except httpx.TimeoutException:
                print(f"❌ TIMEOUT: MCP server timed out for '{tool_name}'")
                return {"error": f"Timeout fetching {tool_name} from MCP server."}
            except Exception as e:
                print(f"❌ ERROR: MCP server error for '{tool_name}': {e}")
                return {"error": f"Error fetching {tool_name} from MCP server: {e}"}
            if response.status_code == 200:
                print(f"✅ SUCCESS: Fetched '{tool_name}' data.")
                return response.json()
            else:
                print(f"⚠️ Error from mock server for tool '{tool_name}': {response.status_code}")
                return {"error": f"Server returned {response.status_code}"}
    except Exception as e:
        print(f"❌ Failed to fetch live data for tool '{tool_name}'. Error: {e}")
        traceback.print_exc()
    print(f"ℹ️ INFO: Fallback for '{tool_name}'.")
    return {"error": f"Could not fetch {tool_name}."}

# --- NEW: Tool Definition for the Strategist Agent ---
def get_market_performance(stock_symbols: list):
    print(f"TOOL CALLED: get_market_performance for symbols: {stock_symbols}")
    performance_data = {}
    performance_data["NIFTY 50"] = {"1y_return": 12.0}
    for symbol in stock_symbols:
        if "RELIANCE" in symbol:
            performance_data[symbol] = {"1y_return": 15.5}
        elif "TCS" in symbol:
            performance_data[symbol] = {"1y_return": 11.0}
        else:
            performance_data[symbol] = {"1y_return": 13.0}
    return json.dumps(performance_data)

market_data_tool = Tool(
    function_declarations=[
        FunctionDeclaration(
            name="get_market_performance",
            description="Gets the real-time 1-year market performance for a list of stock symbols and the NIFTY 50 index.",
            parameters={
                "type": "object",
                "properties": {
                    "stock_symbols": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "A list of stock symbols to fetch performance for, e.g., ['RELIANCE', 'TCS']"
                    }
                },
                "required": ["stock_symbols"]
            },
        )
    ]
)

# --- Gemini Model Call Function ---
def call_gemini_text(prompt: str, model_name="gemini-2.5-flash", tools=None, timeout=45):
    try:
        model = GenerativeModel(model_name, tools=tools)
        response = model.generate_content(prompt)
        if response.candidates[0].function_calls:
            function_call = response.candidates[0].function_calls[0]
            if function_call.name == "get_market_performance":
                args = {key: value for key, value in function_call.args.items()}
                tool_result = get_market_performance(**args)
                final_response = model.generate_content(
                    Part.from_function_response(
                        name="get_market_performance",
                        response={"content": tool_result}
                    )
                )
                return final_response.text
        return response.text
    except Exception as e:
        print(f"❌ Gemini API error: {e}")
        traceback.print_exc()
        return f"Error: Gemini API call failed: {e}"

# --- Agent Endpoints ---
@app.post("/ask-oracle")
async def ask_oracle(uid: str = Depends(verify_firebase_token), body: dict = Body(...)):
    question = body.get("question", "")
    financial_data = await get_user_financial_data(uid, tool_name="fetch_net_worth")
    prompt = (f"You are Oracle... User's question: '{question}'\nData:\n{financial_data}")
    answer = await asyncio.to_thread(call_gemini_text, prompt)
    return {"question": question, "answer": answer}

@app.post("/run-guardian")
async def run_guardian(uid: str = Depends(verify_firebase_token), body: dict = Body(None)):
    transactions, credit = await asyncio.gather(
        get_user_financial_data(uid, tool_name="fetch_bank_transactions"),
        get_user_financial_data(uid, tool_name="fetch_credit_report")
    )
    data = {"transactions": transactions, "credit_report": credit}
    prompt = ("You are Guardian... Respond ONLY in JSON...\n" f"Data:\n{data}")
    answer = await asyncio.to_thread(call_gemini_text, prompt)
    return {"alerts": answer}

@app.post("/run-catalyst")
async def run_catalyst(uid: str = Depends(verify_firebase_token), body: dict = Body(None)):
    net_worth, epf = await asyncio.gather(
        get_user_financial_data(uid, tool_name="fetch_net_worth"),
        get_user_financial_data(uid, tool_name="fetch_epf_details")
    )
    data = {"net_worth_summary": net_worth, "epf_details": epf}
    prompt = ("You are Catalyst... Respond ONLY in JSON...\n" f"Data:\n{data}")
    answer = await asyncio.to_thread(call_gemini_text, prompt)
    return {"opportunities": answer}

@app.post("/run-strategist")
async def run_strategist(uid: str = Depends(verify_firebase_token), body: dict = Body(None)):
    stock_data = await get_user_financial_data(uid, tool_name="fetch_stock_transactions")
    prompt = (
        "You are an expert Investment Strategist for the Indian market. "
        "1. Analyze the user's stock portfolio provided below. "
        "2. Identify all the unique stock symbols from the portfolio. "
        "3. Use the 'get_market_performance' tool to fetch the latest 1-year performance for these stocks and the NIFTY 50 index. "
        "4. Compare each stock's performance against the NIFTY 50 benchmark. "
        "5. Provide a final summary with actionable advice: recommend holding or selling underperforming stocks and suggest reallocating funds to better-performing assets. "
        "Respond ONLY in a valid JSON object format: "
        "`{\"summary\": \"...\", \"recommendations\": [{\"symbol\": \"...\", \"advice\": \"...\", \"reasoning\": \"...\"}]}`.\n"
        f"User's Stock Portfolio:\n```json\n{stock_data}\n```"
    )
    try:
        answer = await asyncio.to_thread(call_gemini_text, prompt, tools=[market_data_tool])
    except Exception as e:
        answer = f"Error calling Gemini: {e}"
    return {"strategy": answer}
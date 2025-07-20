# main.py (FINAL VERSION with Strategist Agent & Tool Use)

from fastapi import FastAPI, Depends, HTTPException, Header, Body
import firebase_admin
from firebase_admin import credentials, auth, firestore
import os
import uuid
import requests
import json

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
def verify_firebase_token(authorization: str = Header(...)):
    try:
        id_token = authorization.split(" ").pop()
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token['uid']
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")

@app.get("/start-fi-auth")
def start_fi_auth(uid: str = Depends(verify_firebase_token)):
    session_id = str(uuid.uuid4())
    db = firestore.client()
    user_doc_ref = db.collection("users").document(uid)
    user_doc_ref.set({"fi_session_id": session_id}, merge=True)
    auth_url = f"{MOCK_SERVER_BASE_URL}/mockWebPage?sessionId={session_id}"
    return {"auth_url": auth_url}

# --- Dynamic Data Fetching ---
def get_user_financial_data(uid: str, tool_name: str):
    # ... (This function remains the same as before)
    try:
        db = firestore.client()
        user_doc = db.collection("users").document(uid).get()
        if user_doc.exists and "fi_session_id" in user_doc.to_dict():
            session_id = user_doc.to_dict()["fi_session_id"]
            headers = {"X-Session-ID": session_id}
            request_body = {"tool_name": tool_name}
            response = requests.post(f"http://localhost:8080/mcp/stream", headers=headers, json=request_body)
            if response.status_code == 200:
                print(f"✅ SUCCESS: Fetched '{tool_name}' data.")
                return response.json()
    except Exception:
        pass
    print(f"ℹ️ INFO: Fallback for '{tool_name}'.")
    return {"error": f"Could not fetch {tool_name}."}

# --- NEW: Tool Definition for the Strategist Agent ---
def get_market_performance(stock_symbols: list):
    """
    A mock tool that simulates fetching real-time stock performance data.
    In a real app, this would call a live financial API.
    """
    print(f"TOOL CALLED: get_market_performance for symbols: {stock_symbols}")
    performance_data = {}
    # NIFTY 50 benchmark
    performance_data["NIFTY 50"] = {"1y_return": 12.0} 
    for symbol in stock_symbols:
        # Generate mock performance data
        if "RELIANCE" in symbol:
            performance_data[symbol] = {"1y_return": 15.5} # Outperforming
        elif "TCS" in symbol:
            performance_data[symbol] = {"1y_return": 11.0} # Underperforming
        else:
            performance_data[symbol] = {"1y_return": 13.0} # Slightly outperforming
            
    return json.dumps(performance_data)

# Describe the tool to the Gemini model
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
def call_gemini_text(prompt: str, model_name="gemini-2.5-flash", tools=None):
    model = GenerativeModel(model_name, tools=tools)
    response = model.generate_content(prompt)
    
    # Check if the model wants to call a tool
    if response.candidates[0].function_calls:
        function_call = response.candidates[0].function_calls[0]
        if function_call.name == "get_market_performance":
            # Execute the function
            args = {key: value for key, value in function_call.args.items()}
            tool_result = get_market_performance(**args)
            
            # Send the result back to the model
            final_response = model.generate_content(
                Part.from_function_response(
                    name="get_market_performance",
                    response={"content": tool_result}
                )
            )
            return final_response.text

    return response.text

# --- Agent Endpoints ---
@app.post("/ask-oracle")
def ask_oracle(uid: str = Depends(verify_firebase_token), body: dict = Body(...)):
    question = body.get("question", "")
    financial_data = get_user_financial_data(uid, tool_name="fetch_net_worth")
    prompt = (f"You are Oracle... User's question: '{question}'\nData:\n{financial_data}")
    # ... (rest of the logic)
    return {"question": question, "answer": call_gemini_text(prompt)}

@app.post("/run-guardian")
def run_guardian(uid: str = Depends(verify_firebase_token), body: dict = Body(None)):
    transactions = get_user_financial_data(uid, tool_name="fetch_bank_transactions")
    credit = get_user_financial_data(uid, tool_name="fetch_credit_report")
    data = {"transactions": transactions, "credit_report": credit}
    prompt = ("You are Guardian... Respond ONLY in JSON...\n" f"Data:\n{data}")
    # ... (rest of the logic)
    return {"alerts": call_gemini_text(prompt)}

@app.post("/run-catalyst")
def run_catalyst(uid: str = Depends(verify_firebase_token), body: dict = Body(None)):
    net_worth = get_user_financial_data(uid, tool_name="fetch_net_worth")
    epf = get_user_financial_data(uid, tool_name="fetch_epf_details")
    data = {"net_worth_summary": net_worth, "epf_details": epf}
    prompt = ("You are Catalyst... Respond ONLY in JSON...\n" f"Data:\n{data}")
    # ... (rest of the logic)
    return {"opportunities": call_gemini_text(prompt)}

# --- NEW STRATEGIST AGENT ENDPOINT ---
@app.post("/run-strategist")
def run_strategist(uid: str = Depends(verify_firebase_token), body: dict = Body(None)):
    stock_data = get_user_financial_data(uid, tool_name="fetch_stock_transactions")
    
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
        # Pass the tool to the Gemini model
        answer = call_gemini_text(prompt, tools=[market_data_tool])
    except Exception as e:
        answer = f"Error calling Gemini: {e}"
        
    return {"strategy": answer}
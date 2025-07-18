# main.py (Ha bhai yeh Vertex AI ke liye hai)
from fastapi import FastAPI, Depends, HTTPException, Header, Body
import firebase_admin
from firebase_admin import credentials, auth
import os

# --- NEW: Import Vertex AI libraries ---
import vertexai
from vertexai.generative_models import GenerativeModel

app = FastAPI()

# --- Firebase Initialization (remains the same) ---
cred = credentials.Certificate("invested-hackathon-firebase-adminsdk-fbsvc-38735ba923.json")
firebase_admin.initialize_app(cred)

# --- NEW: Vertex AI Initialization ---
# This line tells the Google library where to find your downloaded key file
SERVICE_ACCOUNT_KEY_PATH = os.path.join(os.path.dirname(__file__), "invested-hackathon-vertex-ai-key.json")
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = SERVICE_ACCOUNT_KEY_PATH

# Initialize Vertex AI with your project details
# Find your Project ID in the Google Cloud Console dashboard
# Location is typically a region like "us-central1" or "asia-south1"
GCP_PROJECT_ID = "invested-hackathon"
GCP_LOCATION = "us-central1" # e.g., us-central1
vertexai.init(project=GCP_PROJECT_ID, location=GCP_LOCATION)


# Firebase token verification (remains the same)
def verify_firebase_token(authorization: str = Header(...)):
    try:
        id_token = authorization.split(" ").pop()
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token['uid']
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")

# NEW: The Vertex AI way of calling Gemini
def call_gemini_text(prompt: str, model_name="gemini-2.5-flash"):
    model = GenerativeModel(model_name)
    response = model.generate_content(prompt)
    return response.text

# Mock financial data function (remains the same)
def get_mock_financial_data(uid: str):
    return {
        "user_id": uid,
        "assets": [
            {"type": "bank_account", "name": "HDFC Savings", "balance": 120000},
            {"type": "mutual_fund", "name": "Axis Bluechip Fund", "current_value": 45000},
            {"type": "stock", "name": "TCS", "current_value": 32000, "shares": 10}
        ],
        "liabilities": [
            {"type": "credit_card", "issuer": "HDFC", "outstanding": 8000},
            {"type": "loan", "name": "Home Loan", "outstanding": 1200000}
        ],
        "net_worth": -1011000, # Corrected net worth calculation
        "credit_score": 782,
        "epf": 250000,
        "sip_performance": [
            {"name": "Axis Bluechip Fund", "1y_return": 11.2, "benchmark": 12.0},
            {"name": "Nippon India Growth", "1y_return": 9.5, "benchmark": 12.0}
        ]
    }

 # Truncated for brevity
@app.get("/fetch-data")
def fetch_data(uid: str = Depends(verify_firebase_token)):
    return get_mock_financial_data(uid)

@app.get("/protected")
def protected_route(uid: str = Depends(verify_firebase_token)):
    return {"message": f"Hello, user {uid}!"}

# --- API Endpoints (Updated to use the new function) ---

@app.post("/ask-oracle")
def ask_oracle(uid: str = Depends(verify_firebase_token), body: dict = Body(...)):
    question = body.get("question", "")
    financial_data = get_mock_financial_data(uid)
    
    prompt = (
        f"You are Oracle, an expert financial scenario modeling AI. Here is the user's financial data:\n"
        f"{financial_data}\n"
        f"User's question: {question}\n"
        f"Respond with a clear, actionable answer."
    )
    try:
        # This function call looks the same, but it's now using the Vertex AI setup!
        answer = call_gemini_text(prompt, model_name="gemini-2.5-flash")
    except Exception as e:
        answer = f"Error calling Gemini via Vertex AI: {e}"
    return {"question": question, "answer": answer}

@app.post("/run-guardian")
def run_guardian(uid: str = Depends(verify_firebase_token), body: dict = Body(None)):
    financial_data = get_mock_financial_data(uid)
    prompt = (
        "You are Guardian, a silent financial anomaly detection agent. "
        "Analyze the provided user financial data. Identify 3 potential risks or anomalies. "
        "Consider spending spikes, underperforming assets compared to benchmarks, and upcoming bill payments that have insufficient funds. "
        "Respond ONLY in structured JSON format: { 'alerts': [ ... ] }. If no alerts, return an empty array.\n"
        f"User's financial data: {financial_data}"
    )
    try:
        answer = call_gemini_text(prompt, model_name="gemini-2.5-flash")
    except Exception as e:
        answer = f"Error calling Gemini: {e}"
    return {"alerts": answer}

@app.post("/run-catalyst")
def run_catalyst(uid: str = Depends(verify_firebase_token), body: dict = Body(None)):
    financial_data = get_mock_financial_data(uid)
    prompt = (
        "You are Catalyst, an opportunity engine for financial health. "
        "Analyze the user's financial data and suggest 3 actionable opportunities to improve their financial health. "
        "Consider debt consolidation, better savings options, and tax-saving investments. "
        "Respond ONLY in JSON format: { 'opportunities': [ ... ] }.\n"
        f"User's financial data: {financial_data}"
    )
    try:
        answer = call_gemini_text(prompt, model_name="gemini-2.5-flash")
    except Exception as e:
        answer = f"Error calling Gemini: {e}"
    return {"opportunities": answer}

# (The /run-guardian and /run-catalyst endpoints would be updated in the same way)
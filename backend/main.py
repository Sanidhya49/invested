# main.py (Full version with ALL endpoints)

from fastapi import FastAPI, Depends, HTTPException, Header, Body
from fastapi.responses import RedirectResponse
import firebase_admin
from firebase_admin import credentials, auth, firestore
import os
import uuid # Used to generate unique session IDs
import requests

# Import Vertex AI libraries
import vertexai
from vertexai.generative_models import GenerativeModel

app = FastAPI()

# --- Firebase & Vertex AI Initialization ---
cred = credentials.Certificate("invested-hackathon-firebase-adminsdk-fbsvc-38735ba923.json")
firebase_admin.initialize_app(cred)

SERVICE_ACCOUNT_KEY_PATH = os.path.join(os.path.dirname(__file__), "invested-hackathon-vertex-ai-key.json")
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = SERVICE_ACCOUNT_KEY_PATH

GCP_PROJECT_ID = "invested-hackathon"
GCP_LOCATION = "us-central1"
vertexai.init(project=GCP_PROJECT_ID, location=GCP_LOCATION)

# --- URLs & Credentials for the LOCAL mock server ---
# TODO: Find these inside the Go project's files (e.g., config or main.go)
FI_CLIENT_ID = "YOUR_MOCK_CLIENT_ID_FROM_THE_GO_SERVER"
FI_CLIENT_SECRET = "YOUR_MOCK_CLIENT_SECRET_FROM_THE_GO_SERVER"
FI_REDIRECT_URI = "http://127.0.0.1:8000/fi-callback"
MOCK_SERVER_BASE_URL = "http://10.0.2.2:8080" # yess, special IP for emulator access # The Go server you are running


# --- Firebase token verification ---
def verify_firebase_token(authorization: str = Header(...)):
    try:
        id_token = authorization.split(" ").pop()
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token['uid']
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")

# --- NEW Authentication Endpoints ---
@app.get("/start-fi-auth")
def start_fi_auth(uid: str = Depends(verify_firebase_token)):
    session_id = str(uuid.uuid4())
    db = firestore.client()
    user_doc_ref = db.collection("users").document(uid)
    user_doc_ref.set({"fi_session_id": session_id}, merge=True)
    auth_url = f"{MOCK_SERVER_BASE_URL}/mockWebPage?sessionId={session_id}"
    return {"auth_url": auth_url}

@app.get("/fi-callback")
def fi_callback(code: str, state: str):
    uid = state
    token_payload = {
        "grant_type": "authorization_code", "code": code,
        "redirect_uri": FI_REDIRECT_URI, "client_id": FI_CLIENT_ID,
        "client_secret": FI_CLIENT_SECRET,
    }
    response = requests.post(f"{MOCK_SERVER_BASE_URL}/token", data=token_payload)
    
    if response.status_code == 200:
        access_token = response.json().get("access_token")
        db = firestore.client()
        user_doc_ref = db.collection("users").document(uid)
        user_doc_ref.set({"fi_access_token": access_token}, merge=True)
        return {"message": "Successfully connected! You can close this window."}
    else:
        raise HTTPException(status_code=400, detail="Failed to get access token from mock server.")


# --- NEW Data Fetching Function ---
def get_user_financial_data(uid: str):
    try:
        db = firestore.client()
        user_doc = db.collection("users").document(uid).get()
        if user_doc.exists:
            access_token = user_doc.to_dict().get("fi_access_token")
            if access_token:
                headers = {"Authorization": f"Bearer {access_token}"}
                response = requests.get(f"{MOCK_SERVER_BASE_URL}/accounts", headers=headers)
                if response.status_code == 200:
                    print("SUCCESS: Fetched live data from mock server.")
                    return response.json()
    except Exception as e:
        print(f"Failed to fetch live data, falling back to mock. Error: {e}")

    print("INFO: Falling back to mock data.")
    return { "user_id": uid, "assets": [{"type": "bank_account (Mock)", "balance": 120000}], "liabilities": [], "net_worth": 120000 }


# --- Gemini Model Call Function ---
def call_gemini_text(prompt: str, model_name="gemini-2.5-flash"):
    model = GenerativeModel(model_name)
    response = model.generate_content(prompt)
    return response.text

# --- Agent Endpoints ---
@app.post("/ask-oracle")
def ask_oracle(uid: str = Depends(verify_firebase_token), body: dict = Body(...)):
    question = body.get("question", "")
    financial_data = get_user_financial_data(uid)
    prompt = ( f"You are Oracle... User's question: {question}\nData: {financial_data}" )
    try:
        answer = call_gemini_text(prompt)
    except Exception as e:
        answer = f"Error calling Gemini: {e}"
    return {"question": question, "answer": answer}

@app.post("/run-guardian")
def run_guardian(uid: str = Depends(verify_firebase_token), body: dict = Body(None)):
    financial_data = get_user_financial_data(uid)
    prompt = ( "You are Guardian... Respond ONLY in JSON... \n" f"Data: {financial_data}" )
    try:
        answer = call_gemini_text(prompt)
    except Exception as e:
        answer = f"Error calling Gemini: {e}"
    return {"alerts": answer}

@app.post("/run-catalyst")
def run_catalyst(uid: str = Depends(verify_firebase_token), body: dict = Body(None)):
    financial_data = get_user_financial_data(uid)
    prompt = ( "You are Catalyst... Respond ONLY in JSON...\n" f"Data: {financial_data}" )
    try:
        answer = call_gemini_text(prompt)
    except Exception as e:
        answer = f"Error calling Gemini: {e}"
    return {"opportunities": answer}
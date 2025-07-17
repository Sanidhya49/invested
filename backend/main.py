from fastapi import FastAPI, Depends, HTTPException, Header
import firebase_admin
from firebase_admin import credentials, auth

app = FastAPI()

# Initialize Karo Firebase Admin SDK (download your service account key from Firebase Console)
cred = credentials.Certificate("invested-hackathon-firebase-adminsdk-fbsvc-38735ba923.json")
firebase_admin.initialize_app(cred)

def verify_firebase_token(authorization: str = Header(...)):
    try:
        id_token = authorization.split(" ").pop()
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token['uid']
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")

@app.get("/protected")
def protected_route(uid: str = Depends(verify_firebase_token)):
    return {"message": f"Hello, user {uid}!"}

@app.get("/fetch-data")
def fetch_data(uid: str = Depends(verify_firebase_token)):
    # Mocked financial data
    return {
        "user_id": uid,
        "assets": [
            {"type": "bank_account", "name": "HDFC Savings", "balance": 120000},
            {"type": "mutual_fund", "name": "Axis Bluechip Fund", "current_value": 45000, "returns_pct": 11.2},
            {"type": "stock", "name": "TCS", "current_value": 32000, "shares": 10}
        ],
        "liabilities": [
            {"type": "credit_card", "issuer": "HDFC", "outstanding": 8000},
            {"type": "loan", "name": "Home Loan", "outstanding": 1200000}
        ],
        "net_worth": 134000,
        "credit_score": 782,
        "epf": 250000,
        "sip_performance": [
            {"name": "Axis Bluechip Fund", "1y_return": 11.2, "benchmark": 12.0},
            {"name": "Nippon India Growth", "1y_return": 9.5, "benchmark": 12.0}
        ]
    }
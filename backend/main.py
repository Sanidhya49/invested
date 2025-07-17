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
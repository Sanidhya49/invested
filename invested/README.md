# Invested

A cross-platform Flutter app for secure, AI-powered personal finance.

## Project Structure

```
/ (project root)
|-- invested/         # Flutter app (mobile frontend)
|-- backend/          # FastAPI backend (Python)
|   |-- main.py
|   |-- requirements.txt
|   |-- invested-hackathon-firebase-adminsdk-xxxx.json
|-- README.md
|-- .gitignore
```

## Getting Started

### Flutter App (Frontend)

1. **Install dependencies:**
   ```
   flutter pub get
   ```

2. **Run the app:**
   ```
   flutter run
   ```

3. **Firebase Setup:**
   - Place your `google-services.json` in `invested/android/app/`.
   - Make sure your Firebase project is configured for Auth and Firestore.

### Backend (FastAPI)

1. **Install dependencies:**
   ```
   cd backend
   python -m venv .venv
   .venv\Scripts\activate  # or source .venv/bin/activate on Mac/Linux
   pip install -r requirements.txt
   ```

2. **Service Account:**
   - Download your Firebase service account JSON and place it in the `backend/` folder.
   - Update the path in `main.py` if needed.

3. **Run the backend:**
   ```
   uvicorn main:app --reload
   ```

---

## Contributing

- Commit your changes to a new branch and open a pull request.
- Don’t commit secrets or environment files.

---

## License

MIT

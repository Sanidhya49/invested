# Invested

A cross-platform Flutter app for secure, AI-powered personal finance.

## Getting Started

### Flutter App

1. **Install dependencies:**
   ```
   flutter pub get
   ```

2. **Run the app:**
   ```
   flutter run
   ```

3. **Firebase Setup:**
   - Place your `google-services.json` in `android/app/`.
   - Make sure your Firebase project is configured for Auth and Firestore.

### Backend (FastAPI) — *optional, for future expansion*

1. **Install dependencies:**
   ```
   cd backend
   python -m venv venv
   source venv/bin/activate  # or venv\Scripts\activate on Windows
   pip install -r requirements.txt
   ```

2. **Set up environment variables:**
   - Copy `.env.example` to `.env` and fill in your secrets.

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

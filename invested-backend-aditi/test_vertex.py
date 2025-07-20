# test_vertex.py
import vertexai
from vertexai.generative_models import GenerativeModel

# --- Your Project Details ---
PROJECT_ID = "invested-vertex"
LOCATION = "asia-south1"
# --------------------------

print("--- Starting Vertex AI Connection Test ---")

try:
    print(f"Attempting to initialize Vertex AI for project '{PROJECT_ID}' in location '{LOCATION}'...")
    vertexai.init(project=PROJECT_ID, location=LOCATION)
    print("SDK Initialized Successfully.")

    print("\nAttempting to create a handle for model 'gemini-pro'...")
    model = GenerativeModel("gemini-pro")
    print("Successfully created a model handle.")

    print("\n--- TEST SUCCEEDED ---")
    print("If you see this message, your project and authentication are working correctly.")

except Exception as e:
    print("\n--- !!! TEST FAILED !!! ---")
    print(f"The connection failed with the following error:\n{e}")
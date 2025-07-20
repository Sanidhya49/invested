# engine.py
import vertexai
from vertexai.generative_models import GenerativeModel

# Explicitly initialize with your project ID.
# The SDK will use the service account key for authentication.
vertexai.init(project="invested-vertex")

def categorize_transaction_with_gemini(description: str) -> str:
    """
    Uses Gemini to categorize a transaction based on its description.
    """
    model = GenerativeModel("gemini-pro")
    prompt = f"""
    You are a classification model. Your only job is to classify the user's text into one of these exact categories: ['Food & Dining', 'Transport', 'Entertainment', 'Shopping', 'Health', 'Groceries', 'Rent & Utilities', 'Investments', 'Income', 'Other'].
    Do not provide any explanation or extra words. Respond with only the category name.
    Text to classify: "{description}"
    Category:
    """
    try:
        response = model.generate_content(prompt)
        category = response.text.strip().replace("'", "").replace('"', '')
        return category
    except Exception as e:
        print(f"An error occurred with the Gemini API: {e}")
        return "Other"
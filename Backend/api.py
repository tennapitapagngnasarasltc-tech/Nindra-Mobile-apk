from fastapi import FastAPI, Depends
from auth import get_user_id

from predict_sleep import run_prediction
from recommendations import run_recommendations
from suggestions import run_suggestions

app = FastAPI()


@app.get("/")
def home():
    return {"message": "Nidra AI Backend Running"}


@app.post("/run-ai")
def run_ai(user_id: str = Depends(get_user_id)):

    prediction = run_prediction(user_id)

    recommendations = run_recommendations(user_id)

    suggestions = run_suggestions(user_id)

    return {
        "success": True,
        "user_id": user_id,
        "prediction": prediction,
        "recommendations_count": len(recommendations),
        "suggestions_count": len(suggestions)
    }
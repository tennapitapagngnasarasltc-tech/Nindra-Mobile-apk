"""
api.py — FastAPI server for Sleep Quality Predictor
---------------------------------------------------
Exposes REST API endpoints to trigger sleep prediction functions.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import os
import sys
from supabase import create_client, Client
from config import SUPABASE_URL, SUPABASE_KEY
from model import predict_sleep
from db import fetch_profile, save_predictions, fetch_entertainments, save_recommendations, save_suggestions
from suggestions import build_user_prompt, get_sleep_suggestions, parse_suggestions, get_image_url
import random
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()


class PredictRequest(BaseModel):
    user_id: str


def get_supabase_client() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_KEY)


def find_matching_entertainments(user_quality: str, entertainments: list[dict]) -> list[dict]:
    matches = []
    for item in entertainments:
        if item.get("sleep_quality") == user_quality:
            matches.append({
                **item,
                "entertainment_sleep_quality": user_quality,
                "user_sleep_quality": user_quality,
            })
    return matches


def build_recommendations(matches: list[dict], max_items: int = 5) -> list[dict]:
    if not matches:
        return []
    return random.sample(matches, min(max_items, len(matches)))


def run_prediction(user_id: str) -> dict:
    """
    Run the full prediction pipeline for a given user_id.
    Returns a dict with status and results.
    """
    if not user_id:
        raise ValueError("No user_id provided.")

    client = get_supabase_client()

    # Fetch profile
    try:
        profile = fetch_profile(client, user_id)
    except Exception as e:
        raise ValueError(f"Failed to fetch profile: {e}")

    # Run prediction
    predictions = predict_sleep(profile)

    # Save predictions
    try:
        save_predictions(client, user_id, predictions)
    except Exception as e:
        raise ValueError(f"Failed to save predictions: {e}")

    # Generate recommendations
    user_quality = predictions['sleep_quality']
    entertainments = fetch_entertainments(client)
    matches = find_matching_entertainments(user_quality, entertainments)
    if matches:
        recommendations = build_recommendations(matches)
        try:
            saved_recs = save_recommendations(client, user_id, recommendations)
        except Exception as e:
            raise ValueError(f"Failed to save recommendations: {e}")
    else:
        recommendations = []

    # Generate suggestions
    try:
        suggestions_text = get_sleep_suggestions(profile)
        parsed = parse_suggestions(suggestions_text)
        if parsed:
            suggestions_with_images = [(title, suggestion, get_image_url(title)) for title, suggestion in parsed]
            saved_sugs = save_suggestions(client, user_id, suggestions_with_images)
        else:
            saved_sugs = []
    except Exception as e:
        raise ValueError(f"Failed to generate/save suggestions: {e}")

    return {
        "status": "success",
        "predictions": predictions,
        "recommendations_count": len(recommendations),
        "suggestions_count": len(saved_sugs) if 'saved_sugs' in locals() else 0,
    }


app = FastAPI(title="Sleep Predictor API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/predict")
async def predict(request: PredictRequest):
    """
    Trigger sleep prediction for a user.
    Expects JSON: {"user_id": "uuid"}
    """
    try:
        result = run_prediction(request.user_id)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {e}")


@app.get("/")
async def root():
    return {"message": "Sleep Predictor API is running"}


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
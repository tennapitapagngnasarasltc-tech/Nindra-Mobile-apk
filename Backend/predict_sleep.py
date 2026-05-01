"""
Sleep Quality Predictor — Supabase Integration
-----------------------------------------------
Fetches a user's profile from public.profiles by user_id,
predicts sleep quality, deep sleep %, and REM sleep %,
then writes the results back to the same row.
"""

import sys
from supabase import create_client, Client
from config import SUPABASE_URL, SUPABASE_KEY
from model import predict_sleep
from db import fetch_profile, save_predictions


def get_supabase_client() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_KEY)


def run_prediction(user_id: str):
    client = get_supabase_client()

    profile = fetch_profile(client, user_id)

    predictions = predict_sleep(profile)

    save_predictions(client, user_id, predictions)

    return predictions


if __name__ == "__main__":
    main()

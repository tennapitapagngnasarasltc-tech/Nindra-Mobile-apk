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


def main():
    user_id = input("Enter user_id (UUID): ").strip()
    if not user_id:
        print("❌  No user_id provided.")
        sys.exit(1)

    print(f"\n🔗  Connecting to Supabase...")
    client = get_supabase_client()

    print(f"📥  Fetching profile for user_id: {user_id}")
    try:
        profile = fetch_profile(client, user_id)
    except Exception as e:
        print(f"❌  {e}")
        sys.exit(1)

    print("\n📋  Profile data retrieved:")
    for k, v in profile.items():
        print(f"    {k}: {v}")

    print("\n🧠  Running sleep prediction model...")
    predictions = predict_sleep(profile)

    print("\n✅  Predictions:")
    print(f"    Sleep Quality  : {predictions['sleep_quality']}")
    print(f"    Sleep Percent  : {predictions['sleep_percent']} %")
    print(f"    Deep Sleep     : {predictions['deep_sleep_pct']} %")
    print(f"    REM Sleep      : {predictions['rem_sleep_pct']} %")

    print("\n💾  Saving predictions to Supabase...")
    try:
        save_predictions(client, user_id, predictions)
        print("✅  Predictions stored successfully.")
    except Exception as e:
        print(f"❌  Save failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

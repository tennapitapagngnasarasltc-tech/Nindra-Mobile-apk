"""
main.py — Run all sleep predictor programs in one place
-------------------------------------------------------
Takes a user_id, predicts sleep metrics, generates recommendations,
and creates personalized suggestions, saving all to the database.
"""

import sys
from supabase import create_client, Client
from config import SUPABASE_URL, SUPABASE_KEY
from model import predict_sleep
from db import fetch_profile, save_predictions, fetch_entertainments, save_recommendations, save_suggestions
from suggestions import build_user_prompt, get_sleep_suggestions, parse_suggestions, get_image_url
import random


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

    print("\n📋  Profile data:")
    for k, v in profile.items():
        print(f"    {k}: {v}")

    print("\n🧠  Running sleep prediction model...")
    predictions = predict_sleep(profile)
    print("\n✅  Predictions:")
    print(f"    Sleep Quality  : {predictions['sleep_quality']}")
    print(f"    Sleep Percent  : {predictions['sleep_percent']} %")
    print(f"    Deep Sleep     : {predictions['deep_sleep_pct']} %")
    print(f"    REM Sleep      : {predictions['rem_sleep_pct']} %")

    print("\n💾  Saving predictions...")
    try:
        save_predictions(client, user_id, predictions)
        print("✅  Predictions saved.")
    except Exception as e:
        print(f"❌  Save failed: {e}")
        sys.exit(1)

    print("\n🎥  Generating recommendations...")
    user_quality = predictions['sleep_quality']
    entertainments = fetch_entertainments(client)
    matches = find_matching_entertainments(user_quality, entertainments)
    if not matches:
        print("⚠️  No matching entertainments found.")
    else:
        recommendations = build_recommendations(matches)
        print(f"✅  Found {len(matches)} matches, saving {len(recommendations)} recommendations.")
        try:
            saved_recs = save_recommendations(client, user_id, recommendations)
            print(f"💾  Saved {len(saved_recs)} recommendations.")
            for rec in recommendations:
                print(f"  - {rec.get('title')} ({rec.get('type')})")
        except Exception as e:
            print(f"❌  Failed to save recommendations: {e}")

    print("\n💡  Generating sleep suggestions...")
    try:
        suggestions_text = get_sleep_suggestions(profile)
        parsed = parse_suggestions(suggestions_text)
        print(f"✅  Generated {len(parsed)} suggestions.")
        if parsed:
            suggestions_with_images = [(title, suggestion, get_image_url(title)) for title, suggestion in parsed]
            saved_sugs = save_suggestions(client, user_id, suggestions_with_images)
            print(f"💾  Saved {len(saved_sugs)} suggestions.")
            for title, _ in parsed:
                print(f"  - {title}")
        print("\n" + "="*50)
        print(suggestions_text)
        print("="*50)
    except Exception as e:
        print(f"❌  Failed to generate/save suggestions: {e}")


if __name__ == "__main__":
    main()
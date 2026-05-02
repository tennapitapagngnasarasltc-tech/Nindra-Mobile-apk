"""
recommendations.py — Generate sleep-based entertainment recommendations

This script reads a user's `sleep_quality` from `public.profiles`, finds matching
entries in `public.entertainments` where `sleep_pecent` falls into the same quality
band, and then saves a random selection into a separate recommendations table.

The target recommendations table should exist before running this script. Example SQL:

CREATE TABLE IF NOT EXISTS public.recommendations (
    id serial PRIMARY KEY,
    user_id uuid NOT NULL,
    entertainment_id integer NOT NULL,
    user_sleep_quality text NOT NULL,
    entertainment_sleep_quality text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);
"""

import random
import sys
from supabase import create_client, Client
from config import SUPABASE_URL, SUPABASE_KEY
from db import fetch_profile, fetch_entertainments, save_recommendations


def get_supabase_client() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_KEY)


def find_matching_entertainments(profile: dict, entertainments: list[dict]) -> list[dict]:
    user_quality = profile.get("sleep_quality")
    if not user_quality:
        return []

    matches = []
    for item in entertainments:
        entertainment_quality = item.get("sleep_quality")
        if entertainment_quality == user_quality:
            matches.append(
                {
                    **item,
                    "entertainment_sleep_quality": entertainment_quality,
                    "user_sleep_quality": user_quality,
                }
            )

    return matches


def build_recommendations(matches: list[dict], max_items: int = 5) -> list[dict]:
    if not matches:
        return []
    return random.sample(matches, min(max_items, len(matches)))


def main() -> None:
    user_id = input("Enter user_id (UUID): ").strip()
    if not user_id:
        print("❌  No user_id provided.")
        sys.exit(1)

    client = get_supabase_client()

    try:
        profile = fetch_profile(client, user_id)
    except Exception as exc:
        print(f"❌  Failed to fetch profile: {exc}")
        sys.exit(1)

    sleep_quality = profile.get("sleep_quality")
    if not sleep_quality:
        print("⚠️  User profile does not contain sleep_quality. Run the prediction script first to populate this value.")
        sys.exit(1)

    print(f"🔎  User sleep_quality: {sleep_quality}")

    entertainments = fetch_entertainments(client)
    matches = find_matching_entertainments(profile, entertainments)

    if not matches:
        print("⚠️  No matching entertainments found for this sleep quality.")
        sys.exit(0)

    recommendations = build_recommendations(matches)
    print(f"✅  Found {len(matches)} matching items, saving {len(recommendations)} randomly selected recommendations.")

    try:
        saved = save_recommendations(client, user_id, recommendations)
        print(f"💾  Saved {len(saved)} recommendations to the recommendations table.")
    except Exception as exc:
        print(f"❌  Failed to save recommendations: {exc}")
        sys.exit(1)

    for rec in recommendations:
        print(f"  - {rec.get('title')} ({rec.get('type')}) — {rec.get('entertainment_sleep_quality')}")


if __name__ == "__main__":
    main()

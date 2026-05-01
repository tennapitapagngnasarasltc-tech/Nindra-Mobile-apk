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


def run_recommendations(user_id: str):
    client = get_supabase_client()

    profile = fetch_profile(client, user_id)

    entertainments = fetch_entertainments(client)

    matches = find_matching_entertainments(
        profile,
        entertainments
    )

    recommendations = build_recommendations(matches)

    save_recommendations(
        client,
        user_id,
        recommendations
    )

    return recommendations


if __name__ == "__main__":
    main()

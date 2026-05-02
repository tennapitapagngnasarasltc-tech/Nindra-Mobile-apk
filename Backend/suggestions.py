"""
Sleep Health Suggestion System
-------------------------------
Fetches user profile data from Supabase and uses Groq LLM
to generate personalized sleep improvement suggestions.

Requirements:
    pip install supabase groq

Environment Variables:
    SUPABASE_URL       - Your Supabase project URL
    SUPABASE_KEY       - Your Supabase anon/service key
    GROQ_API_KEY       - Your Groq API key
"""

import re
import requests
from typing import List, Tuple
from supabase import create_client, Client
from groq import Groq
from config import SUPABASE_URL, SUPABASE_KEY, GROQ_API_KEY, UNSPLASH_ACCESS_KEY
from db import save_suggestions


# ──────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────

GROQ_MODEL = "llama-3.3-70b-versatile"   # or "llama-3.1-8b-instant"


# ──────────────────────────────────────────────
# In-Code System Prompt
# ──────────────────────────────────────────────

SLEEP_SYSTEM_PROMPT = """
You are SleepWise, an expert AI wellness coach specialising in sleep health optimisation.

Your role is to analyse a user's sleep profile data and deliver clear, personalised,
evidence-based suggestions to help them sleep better and feel more rested.

When given a user profile, provide 5–7 specific, actionable suggestions tailored to the user's data.
Format each suggestion with:
- A short bold title best for mobile notifications
- A 2–3 sentence explanation grounded in sleep science best for mobile reading
- A concrete first step the user can take TODAY

Prioritise suggestions from highest to lowest impact given the user's profile.

Tone: Warm, encouraging, non-judgmental. Use plain language; avoid jargon.

Output format:
- Use bullet points for each suggestion.
- Keep the total response under 300 words.
- Do NOT repeat raw data back to the user verbatim; interpret it instead.
"""


def build_user_prompt(profile: dict) -> str:
    """Convert a Supabase profile row into a structured prompt for the LLM."""

    return f"""
Here is the sleep profile for the user. Please analyse it and provide personalised suggestions.

**User Profile:**
- Username       : {profile.get('username', 'N/A')}
- Age            : {profile.get('age', 'N/A')}
- Gender         : {profile.get('gender', 'N/A')}
- Occupation     : {profile.get('occupation', 'N/A')}
- BMI Category   : {profile.get('bmi_category', 'N/A')}

**Sleep Metrics:**
- Sleep Duration       : {profile.get('sleep_duration', 'N/A')} hours/night
- Sleep Quality        : {profile.get('sleep_quality', 'N/A')}
- Sleep Score          : {profile.get('latest_score', 'N/A')} ({profile.get('score_band', 'N/A')})
- Deep Sleep %         : {profile.get('deep_sleep_pct', 'N/A')}%
- REM Sleep %          : {profile.get('rem_sleep_pct', 'N/A')}%
- Overall Sleep %      : {profile.get('sleep_percent', 'N/A')}%

**Lifestyle Factors:**
- Stress Level             : {profile.get('stress_level', 'N/A')} / 10
- Physical Activity Level  : {profile.get('physical_activity_level', 'N/A')} (minutes/day)

Please provide personalised sleep improvement suggestions based on this data.
""".strip()


def parse_suggestions(suggestions_text: str) -> List[Tuple[str, str]]:
    """
    Parse the LLM response to extract individual suggestions.
    Returns list of (title, full_suggestion) tuples.
    """
    pattern = r'\*\*(.*?)\*\*(.*?)(?=\*\*|\Z)'
    suggestions = []
    for match in re.finditer(pattern, suggestions_text, re.DOTALL):
        title = match.group(1).strip()
        content = match.group(2).strip().lstrip(':').strip()
        full_suggestion = f"**{title}**\n{content}"
        suggestions.append((title, full_suggestion))

    return suggestions


def get_image_url(title: str) -> str:
    """
    Fetch a relevant image URL from Unsplash for the given title.
    Falls back to a placeholder if no key or error.
    """
    if not UNSPLASH_ACCESS_KEY:
        return "https://via.placeholder.com/400x300?text=No+Image"

    try:
        query = f"sleep {title.lower()}"  # Add 'sleep' to make it relevant
        response = requests.get(
            f"https://api.unsplash.com/search/photos?query={query}&per_page=1",
            headers={"Authorization": f"Client-ID {UNSPLASH_ACCESS_KEY}"}
        )
        response.raise_for_status()
        data = response.json()
        if data.get('results'):
            return data['results'][0]['urls']['small']
        else:
            return "https://via.placeholder.com/400x300?text=No+Image"
    except Exception as e:
        print(f"Error fetching image for '{title}': {e}")
        return "https://via.placeholder.com/400x300?text=No+Image"


# ──────────────────────────────────────────────
# Supabase helpers
# ──────────────────────────────────────────────

def get_supabase_client() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_KEY)


def fetch_profile_by_email(client: Client, email: str) -> dict | None:
    """Fetch a single user profile from Supabase by email."""
    response = (
        client.table("profiles")
        .select("*")
        .eq("user_email", email)
        .limit(1)
        .execute()
    )
    if response.data:
        return response.data[0]
    return None


def fetch_profile_by_username(client: Client, username: str) -> dict | None:
    """Fetch a single user profile from Supabase by username."""
    response = (
        client.table("profiles")
        .select("*")
        .eq("username", username)
        .limit(1)
        .execute()
    )
    if response.data:
        return response.data[0]
    return None


def fetch_profile_by_user_id(client: Client, user_id: str) -> dict | None:
    """Fetch a single user profile from Supabase by UUID user_id."""
    response = (
        client.table("profiles")
        .select("*")
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    if response.data:
        return response.data[0]
    return None


def fetch_all_profiles(client: Client) -> list[dict]:
    """Fetch all profiles (useful for batch processing)."""
    response = client.table("profiles").select("*").execute()
    return response.data or []


# ──────────────────────────────────────────────
# Groq LLM helper
# ──────────────────────────────────────────────

def get_sleep_suggestions(profile: dict) -> str:
    """
    Send the profile data to Groq LLM and return sleep suggestions.
    """
    if not GROQ_API_KEY:
        raise EnvironmentError(
            "❌  Missing GROQ_API_KEY in your environment."
            "\n    Add GROQ_API_KEY to your .env file or environment variables."
        )

    groq_client = Groq(api_key=GROQ_API_KEY)

    user_prompt = build_user_prompt(profile)

    chat_completion = groq_client.chat.completions.create(
        model=GROQ_MODEL,
        messages=[
            {"role": "system", "content": SLEEP_SYSTEM_PROMPT},
            {"role": "user",   "content": user_prompt},
        ],
        temperature=0.7,
        max_tokens=500,
    )

    return chat_completion.choices[0].message.content


# ──────────────────────────────────────────────
# Main entry points
# ──────────────────────────────────────────────

def suggest_for_user(identifier: str, by: str = "email") -> None:
    """
    Fetch one user's profile and print personalised sleep suggestions.

    Args:
        identifier : email address, username, or UUID of the user
        by         : "email" | "username" | "user_id" | "uuid"
    """
    sb = get_supabase_client()

    if by == "email":
        profile = fetch_profile_by_email(sb, identifier)
    elif by == "username":
        profile = fetch_profile_by_username(sb, identifier)
    elif by in {"user_id", "uuid"}:
        profile = fetch_profile_by_user_id(sb, identifier)
    else:
        raise ValueError("'by' must be 'email', 'username', 'user_id', or 'uuid'")

    if not profile:
        print(f"[!] No profile found for {by}='{identifier}'")
        return

    print(f"\n{'='*60}")
    print(f"  Sleep Suggestions for: {profile.get('username', identifier)}")
    print(f"{'='*60}\n")

    suggestions = get_sleep_suggestions(profile)
    parsed = parse_suggestions(suggestions)
    print(f"Parsed {len(parsed)} suggestions")
    if parsed:
        suggestions_with_images = [(title, suggestion, get_image_url(title)) for title, suggestion in parsed]
        saved = save_suggestions(sb, profile['user_id'], suggestions_with_images)
        print(f"Saved {len(saved)} suggestions to DB")
    print(suggestions)
    print(f"\n{'='*60}\n")


def suggest_for_all_users() -> None:
    """
    Fetch every profile and print personalised suggestions for each user.
    Useful for batch reports or admin dashboards.
    """
    sb = get_supabase_client()
    profiles = fetch_all_profiles(sb)

    if not profiles:
        print("[!] No profiles found in the database.")
        return

    print(f"[*] Processing {len(profiles)} profile(s)...\n")

    for profile in profiles:
        label = profile.get("username") or profile.get("user_email", "unknown")
        print(f"\n{'='*60}")
        print(f"  Sleep Suggestions for: {label}")
        print(f"{'='*60}\n")

        try:
            suggestions = get_sleep_suggestions(profile)
            parsed = parse_suggestions(suggestions)
            print(f"Parsed {len(parsed)} suggestions for {label}")
            if parsed:
                suggestions_with_images = [(title, suggestion, get_image_url(title)) for title, suggestion in parsed]
                saved = save_suggestions(sb, profile['user_id'], suggestions_with_images)
                print(f"Saved {len(saved)} suggestions to DB for {label}")
            print(suggestions)
        except Exception as e:
            print(f"[!] Error generating suggestions for {label}: {e}")

        print()


# ──────────────────────────────────────────────
# Run
# ──────────────────────────────────────────────

if __name__ == "__main__":
    user_id = input("Enter user_id (UUID): ").strip()
    if not user_id:
        print("❌  No user_id provided.")
        exit(1)

    suggest_for_user(user_id, by="user_id")
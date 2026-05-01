"""
db.py — Supabase database operations
"""

from supabase import Client


def fetch_profile(client: Client, user_id: str) -> dict:
    """
    Fetch a single profile row from public.profiles by user_id.
    Raises ValueError if no profile is found.
    """
    response = (
        client.table("profiles")
        .select(
            "user_id, gender, age, occupation, sleep_duration, "
            "physical_activity_level, bmi_category, stress_level, latest_score, user_email, sleep_quality"
        )
        .eq("user_id", user_id)
        .single()
        .execute()
    )

    if not response.data:
        raise ValueError(f"No profile found for user_id: {user_id}")

    return response.data


def save_predictions(client: Client, user_id: str, predictions: dict) -> list:
    """
    Update the profiles row with prediction results.
    Raises RuntimeError if the update affects no rows.

    predictions dict should contain:
        - sleep_quality   (str)
        - sleep_percent   (float)
        - deep_sleep_pct  (float)
        - rem_sleep_pct   (float)
    """
    response = (
        client.table("profiles")
        .update(predictions)
        .eq("user_id", user_id)
        .execute()
    )

    if not response.data:
        raise RuntimeError(
            "Update failed — no rows affected.\n"
            "Check that the user_id exists and that RLS policies allow updates."
        )

    return response.data


def fetch_entertainments(client: Client) -> list[dict]:
    """Fetch all entertainments from public.entertainments."""
    response = client.table("entertainments").select(
        "id, title, type, description, cover_img_url, media_file_url, category, mood_states, status, sleep_quality"
    ).execute()
    return response.data or []


def save_recommendations(client: Client, uid: str, recommendations: list[dict]) -> list[dict]:
    """Insert matched recommendations into the public.recommendations table."""
    rows = [
        {
            "uid": uid,
            "entertainment_id": rec["id"],
            "user_sleep_quality": rec.get("user_sleep_quality"),
            "entertainment_sleep_quality": rec.get("entertainment_sleep_quality"),
        }
        for rec in recommendations
    ]

    response = client.table("recommendations").insert(rows).execute()
    if not response.data:
        raise RuntimeError(
            "Recommendation save failed — no rows affected.\n"
            "Ensure the public.recommendations table exists and is writable."
        )

    return response.data


def get_all_user_ids(client: Client) -> list[str]:
    """
    Utility: returns all user_ids in the profiles table.
    Useful for batch processing or debugging.
    """
    response = client.table("profiles").select("user_id").execute()
    return [row["user_id"] for row in response.data] if response.data else []


def save_suggestions(client: Client, user_id: str, suggestions: list[tuple[str, str, str]]) -> list[dict]:
    """
    Insert suggestions into the public.user_suggestions table.
    Deletes existing suggestions for the user first to avoid duplicates.

    Args:
        client: Supabase client
        user_id: UUID of the user
        suggestions: List of (title, suggestion, image_url) tuples

    Returns:
        Inserted rows
    """
    # Delete existing suggestions for the user
    client.table("user_suggestions").delete().eq("user_id", user_id).execute()

    # Insert new suggestions
    rows = [
        {
            "user_id": user_id,
            "title": title,
            "suggestion": suggestion,
        }
        for title, suggestion, _ in suggestions
    ]

    if rows:
        response = client.table("user_suggestions").insert(rows).execute()
        if not response.data:
            raise RuntimeError(
                "Suggestion save failed — no rows affected.\n"
                "Ensure the public.user_suggestions table exists and is writable."
            )
        return response.data
    else:
        return []

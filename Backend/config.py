"""
config.py — Loads environment variables from .env
"""

import os
from dotenv import load_dotenv

# Load .env and override any existing environment vars, to ensure the project
# uses the credentials stored in this repository's .env file.
load_dotenv(override=True)

SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")
GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
UNSPLASH_ACCESS_KEY: str = os.getenv("UNSPLASH_ACCESS_KEY", "")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise EnvironmentError(
        "❌  Missing SUPABASE_URL or SUPABASE_KEY in your .env file.\n"
        "    Copy .env.example → .env and fill in your credentials."
    )

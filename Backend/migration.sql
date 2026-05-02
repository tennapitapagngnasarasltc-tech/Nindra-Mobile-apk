-- ─────────────────────────────────────────────────────────────────────────────
-- migration.sql
-- Run this in your Supabase SQL Editor BEFORE running the Python script.
-- Adds the three prediction output columns to public.profiles.
-- ─────────────────────────────────────────────────────────────────────────────

-- Add sleep quality columns (safe to run multiple times)
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS sleep_quality   TEXT,
    ADD COLUMN IF NOT EXISTS sleep_percent   DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS deep_sleep_pct  DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS rem_sleep_pct   DOUBLE PRECISION;

-- Optional: add comments for documentation
COMMENT ON COLUMN public.profiles.sleep_quality
    IS 'Predicted sleep quality band: Poor / Fair / Good / Excellent';

COMMENT ON COLUMN public.profiles.sleep_percent
    IS 'Predicted overall sleep quality score as a percentage (0-100)';

COMMENT ON COLUMN public.profiles.deep_sleep_pct
    IS 'Predicted percentage of total sleep spent in deep (N3) sleep stage';

COMMENT ON COLUMN public.profiles.rem_sleep_pct
    IS 'Predicted percentage of total sleep spent in REM sleep stage';

-- ─────────────────────────────────────────────────────────────────────────────
-- Optional: verify columns were added
-- ─────────────────────────────────────────────────────────────────────────────
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'profiles'
  AND column_name IN ('sleep_quality', 'sleep_percent', 'deep_sleep_pct', 'rem_sleep_pct');

-- Create recommendations table
CREATE TABLE IF NOT EXISTS public.recommendations (
    id serial PRIMARY KEY,
    uid uuid NOT NULL,
    entertainment_id integer NOT NULL,
    user_sleep_quality text NOT NULL,
    entertainment_sleep_quality text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE public.recommendations
    IS 'Stores matched entertainment recommendations for users based on sleep quality.';

COMMENT ON COLUMN public.recommendations.uid
    IS 'User unique identifier associated with this recommendation.';

COMMENT ON COLUMN public.recommendations.entertainment_id
    IS 'Referenced entertainment item ID.';

COMMENT ON COLUMN public.recommendations.user_sleep_quality
    IS 'The user''s sleep quality band when the recommendation was generated.';

COMMENT ON COLUMN public.recommendations.entertainment_sleep_quality
    IS 'The sleep quality band assigned to the recommended entertainment.';

-- Create user_suggestions table
CREATE TABLE IF NOT EXISTS public.user_suggestions (
    id serial PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    title text NOT NULL,
    suggestion text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE public.user_suggestions
    IS 'Stores personalized sleep improvement suggestions for each user.';

COMMENT ON COLUMN public.user_suggestions.user_id
    IS 'User unique identifier associated with this suggestion.';

COMMENT ON COLUMN public.user_suggestions.title
    IS 'Short bold title of the suggestion.';

COMMENT ON COLUMN public.user_suggestions.suggestion
    IS 'Full suggestion text including explanation and first step.';

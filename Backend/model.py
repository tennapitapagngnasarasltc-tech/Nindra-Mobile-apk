"""
model.py — Sleep quality prediction logic
------------------------------------------
Rule-based statistical model that estimates:
  - sleep_quality   : Poor / Fair / Good / Excellent
  - deep_sleep_pct  : Estimated % of total sleep in deep sleep stage
  - rem_sleep_pct   : Estimated % of total sleep in REM stage

Inputs (from profiles table):
  - sleep_duration          (hours)
  - stress_level            (1–10)
  - physical_activity_level (minutes/day)
  - age                     (years)
  - bmi_category            (Normal / Overweight / Obese)
  - gender                  (male / female)
"""


def predict_sleep(profile: dict) -> dict:
    """
    Main prediction function.

    Args:
        profile (dict): Row from public.profiles

    Returns:
        dict with keys: sleep_quality, sleep_percent, deep_sleep_pct, rem_sleep_pct
    """
    sleep_dur = float(profile.get("sleep_duration") or 7.0)
    stress    = int(profile.get("stress_level") or 5)
    activity  = int(profile.get("physical_activity_level") or 30)
    age       = int(profile.get("age") or 30)
    bmi_cat   = str(profile.get("bmi_category") or "Normal").strip().lower()
    gender    = str(profile.get("gender") or "male").strip().lower()

    # ── Internal quality score (0–100) ────────────────────────────────────

    score = 50.0

    # Sleep duration (optimal window: 7–9 hrs)
    if 7.0 <= sleep_dur <= 9.0:
        score += 20
    elif 6.0 <= sleep_dur < 7.0 or 9.0 < sleep_dur <= 10.0:
        score += 10
    elif sleep_dur < 5.0:
        score -= 20

    # Stress penalty (1 = low stress, 10 = high stress)
    score -= (stress - 1) * 3.5          # range: 0 to −31.5

    # Physical activity boost
    if activity >= 60:
        score += 15
    elif activity >= 30:
        score += 8
    elif activity >= 15:
        score += 3

    # BMI category penalty
    bmi_penalties = {
        "obese": -12,
        "overweight": -6,
        "normal": 0,
        "normal weight": 0,
        "underweight": -4,
    }
    score += bmi_penalties.get(bmi_cat, 0)

    # Age-related decline (starts after 30)
    age_penalty = max(0.0, (age - 30) * 0.3)
    score -= age_penalty

    # Clamp to [0, 100]
    score = max(0.0, min(100.0, score))

    # ── Quality band ─────────────────────────────────────────────────────
    if score >= 75:
        quality = "Excellent"
    elif score >= 55:
        quality = "Good"
    elif score >= 35:
        quality = "Fair"
    else:
        quality = "Poor"

    # ── Deep Sleep % ─────────────────────────────────────────────────────
    # Research baseline: ~18 % of total sleep
    # Decreases with age and stress; increases with physical activity
    deep_base = 18.0
    deep_base -= max(0.0, (age - 30) * 0.15)   # age-related reduction
    deep_base -= (stress - 5) * 0.5             # stress reduces deep sleep
    deep_base += (activity / 60.0) * 1.5        # activity improves deep sleep
    if "obese" in bmi_cat:
        deep_base -= 2.5
    deep_pct = round(max(8.0, min(25.0, deep_base)), 2)

    # ── REM Sleep % ──────────────────────────────────────────────────────
    # Research baseline: ~22 % of total sleep
    # Sensitive to stress and sleep duration
    rem_base = 22.0
    rem_base -= (stress - 5) * 0.6
    if sleep_dur < 6.0:
        rem_base -= 4.0                          # deprivation cuts REM
    elif sleep_dur > 9.0:
        rem_base += 2.0                          # extended sleep recovers REM
    if gender == "female":
        rem_base += 1.5                          # females average slightly more REM
    rem_pct = round(max(10.0, min(30.0, rem_base)), 2)

    return {
        "sleep_quality":  quality,
        "sleep_percent":  round(score, 2),
        "deep_sleep_pct": deep_pct,
        "rem_sleep_pct":  rem_pct,
    }


def get_score_details(profile: dict) -> dict:
    """
    Debug helper — returns the breakdown of score contributions.
    """
    sleep_dur = float(profile.get("sleep_duration") or 7.0)
    stress    = int(profile.get("stress_level") or 5)
    activity  = int(profile.get("physical_activity_level") or 30)
    age       = int(profile.get("age") or 30)
    bmi_cat   = str(profile.get("bmi_category") or "Normal").strip().lower()

    bmi_penalties = {"obese": -12, "overweight": -6, "normal": 0, "normal weight": 0}

    return {
        "base_score":         50.0,
        "duration_bonus":     20 if 7 <= sleep_dur <= 9 else (10 if 6 <= sleep_dur <= 10 else -20),
        "stress_penalty":     -round((stress - 1) * 3.5, 2),
        "activity_bonus":     15 if activity >= 60 else (8 if activity >= 30 else 3),
        "bmi_penalty":        bmi_penalties.get(bmi_cat, 0),
        "age_penalty":        -round(max(0.0, (age - 30) * 0.3), 2),
    }

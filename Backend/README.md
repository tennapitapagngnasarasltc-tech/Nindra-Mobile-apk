# 😴 Sleep Quality Predictor

A Python CLI tool that reads a user's health profile from **Supabase** and predicts their:

- **Sleep Quality** — `Poor` / `Fair` / `Good` / `Excellent`
- **Sleep %** — Predicted overall sleep quality score as a percentage
- **Deep Sleep %** — Estimated % of sleep spent in N3 (deep) stage
- **REM Sleep %** — Estimated % of sleep spent in REM stage

Results are written back directly to the user's row in `public.profiles`.

---

## 📁 Project Structure

```
sleep_predictor/
├── predict_sleep.py     # Entry point — run this
├── model.py             # Prediction logic
├── db.py                # Supabase fetch & save functions
├── config.py            # Loads credentials from .env
├── migration.sql        # SQL to add prediction columns to Supabase
├── requirements.txt     # Python dependencies
├── .env.example         # Environment variable template
├── .gitignore
└── README.md
```

---

## ⚙️ Prerequisites

- Python 3.10 or higher
- A [Supabase](https://supabase.com) project with the `public.profiles` table set up
- Your Supabase **service role key** (not the anon key)

---

## 🚀 Setup & Installation

### 1. Clone / download the project

```bash
cd sleep_predictor
```

### 2. Create a virtual environment (recommended)

```bash
python -m venv venv

# Activate it:
# macOS / Linux:
source venv/bin/activate

# Windows:
venv\Scripts\activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure environment variables

```bash
cp .env.example .env
```

Open `.env` and fill in your credentials:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_KEY=your-service-role-key-here
GROQ_API_KEY=your-groq-api-key-here
UNSPLASH_ACCESS_KEY=your-unsplash-access-key-here
```

> ⚠️ **Use the `service_role` key**, not the `anon` key.  
> Found at: **Supabase Dashboard → Settings → API → service_role secret**

### 5. Run the database migration

In the **Supabase SQL Editor**, run the contents of `migration.sql` to add the prediction columns:

```sql
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS sleep_quality   TEXT,
    ADD COLUMN IF NOT EXISTS sleep_percent   DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS deep_sleep_pct  DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS rem_sleep_pct   DOUBLE PRECISION;
```

---

## ▶️ Running the Script

```bash
python predict_sleep.py
```

You will be prompted:

```
Enter user_id (UUID): xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Paste any valid `user_id` from `auth.users` / `public.profiles` and press Enter.

### Example output

```
🔗  Connecting to Supabase...
📥  Fetching profile for user_id: abc123...

📋  Profile data retrieved:
    gender: male
    age: 34
    sleep_duration: 6.5
    stress_level: 7
    physical_activity_level: 45
    bmi_category: Normal

🧠  Running sleep prediction model...

✅  Predictions:
    Sleep Quality  : Fair
    Sleep Percent  : 63.5 %
    Deep Sleep     : 14.75 %
    REM Sleep      : 19.8 %

💾  Saving predictions to Supabase...
✅  Predictions stored successfully.
```

---

## 🧠 How the Model Works

The prediction uses a **rule-based statistical model** calibrated against published sleep research:

| Input Feature | Impact |
|---|---|
| `sleep_duration` | Optimal 7–9 hrs → highest quality score |
| `stress_level` (1–10) | Higher stress → lower quality, less deep & REM sleep |
| `physical_activity_level` | More activity → deeper sleep |
| `age` | Quality and deep sleep % decrease naturally after 30 |
| `bmi_category` | Obese/Overweight → quality penalty |
| `gender` | Females average ~1.5% more REM sleep |

### Output ranges

| Metric | Range |
|---|---|
| `sleep_quality` | Poor / Fair / Good / Excellent |
| `deep_sleep_pct` | 8 % – 25 % |
| `rem_sleep_pct` | 10 % – 30 % |

---

## 🗄️ Database Schema

The script reads from and writes to `public.profiles`.

**Columns read:**

| Column | Type | Description |
|---|---|---|
| `sleep_duration` | float | Hours of sleep per night |
| `stress_level` | int | Self-reported stress (1–10) |
| `physical_activity_level` | int | Minutes of activity per day |
| `age` | int | User age in years |
| `bmi_category` | text | Normal / Overweight / Obese |
| `gender` | text | male / female |

**Columns written (after migration):**

| Column | Type | Description |
|---|---|---|
| `sleep_quality` | text | Predicted quality band |
| `sleep_percent` | float | Predicted overall sleep quality score as a percentage |
| `deep_sleep_pct` | float | Predicted deep sleep % |
| `rem_sleep_pct` | float | Predicted REM sleep % |

---

## 🔒 Security Notes

- Never commit your `.env` file — it's in `.gitignore`
- The `service_role` key bypasses Row Level Security — keep it secret
- For production use, consider running this as a Supabase Edge Function with server-side auth

---

## 🐛 Troubleshooting

| Error | Fix |
|---|---|
| `Missing SUPABASE_URL or SUPABASE_KEY` | Check your `.env` file exists and has correct values |
| `No profile found for user_id` | Verify the UUID exists in `public.profiles` |
| `Update failed — no rows affected` | Check RLS policies or use the service role key |
| `column does not exist` | Run `migration.sql` in the Supabase SQL Editor |

---

## 📄 License

MIT — free to use and modify.

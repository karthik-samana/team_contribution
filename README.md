# Team Contribution Payment App

A shareable web app to collect team contributions via UPI. No Google dependency — uses **GitHub Pages** (free hosting) + **Supabase** (free database).

---

## How It Works

1. Share a single URL with your team
2. They enter name & amount → UPI app opens with payment pre-filled (or scan QR code)
3. After paying, they click "I've Paid" → entry is auto-logged to your Supabase database
4. You see all contributions in the Supabase dashboard (or on the page itself)

---

## Setup (One-Time, ~10 minutes)

### Step 1: Create a Supabase Project (Free)

1. Go to [supabase.com](https://supabase.com) and sign up (free)
2. Click **New Project** → give it a name (e.g., "team-contributions") → set a database password → Create
3. Wait for the project to finish setting up (~1 minute)

### Step 2: Create the Database Table

1. In your Supabase project, go to **SQL Editor** (left sidebar)
2. Click **New query**
3. Copy-paste the entire contents of `setup.sql` from this project
4. Click **Run** — you should see "Success. No rows returned"

### Step 3: Get Your Supabase Credentials

1. Go to **Settings → API** (left sidebar → gear icon)
2. Copy these two values:
   - **Project URL** — looks like `https://abcdefgh.supabase.co`
   - **anon public key** — a long string starting with `eyJ...`

### Step 4: Configure the App

1. Open `index.html` in a text editor
2. Find the `CONFIG` section near the bottom and update:

```javascript
var CONFIG = {
  EVENT_NAME: "Farewell for Ravi",                              // ← Your event name
  TARGET_AMOUNT: 5000,                                          // ← Target amount in ₹
  UPI_ID: "skar1234@ybl",                                       // ← Your UPI ID
  UPI_NUMBER: "9347134395",                                     // ← Your UPI number
  PAYEE_NAME: "Team Contribution",                              // ← Display name
  SUPABASE_URL: "https://abcdefgh.supabase.co",                 // ← Your Project URL
  SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6..."         // ← Your anon key
};
```

### Step 5: Host on GitHub Pages (Free)

1. Go to [github.com](https://github.com) → **New Repository**
2. Name it `contribute` (or anything) → make it **Public** → Create
3. Upload `index.html` to the repository
4. Go to **Settings → Pages** → Source: **Deploy from a branch** → Branch: `main` → Folder: `/ (root)` → Save
5. Wait ~1 minute → your app is live at `https://YOUR_USERNAME.github.io/contribute/`

### Step 6: Share the URL

Send the GitHub Pages URL to your team via Slack, WhatsApp, email, etc.

---

## Reusing for a New Event

1. Open `index.html` → update `EVENT_NAME` and `TARGET_AMOUNT` in CONFIG
2. Push the change to GitHub (or edit directly on github.com)
3. Same URL, new event! Past contributions are preserved (filtered by event name)

---

## Where to See All Contributions

- **On the page itself** — the Contributors section shows everyone who's contributed
- **In Supabase** — go to your project → **Table Editor** → `contributions` table
  - You can filter, sort, export to CSV, and update the Status column here

---

## Features

| Feature | Description |
|---------|-------------|
| UPI Deep Links | Opens UPI app with amount pre-filled (mobile) |
| QR Code | For desktop users to scan and pay |
| Progress Bar | Shows ₹collected / ₹target with percentage |
| Live Contributors | Shows who has contributed (newest first) |
| Quick Amounts | ₹200, ₹500, ₹1000, ₹2000 one-tap buttons |
| Multi-Event | Reuse for birthdays, farewells, etc. — past data preserved |
| Mobile-First | Optimized for phone screens |
| Free Hosting | GitHub Pages (static) + Supabase free tier |

---

## Project Files

| File | Purpose |
|------|---------|
| `index.html` | The complete app (frontend + Supabase integration) |
| `setup.sql` | SQL to create the database table (run once in Supabase) |
| `README.md` | This setup guide |

---

## Verifying Payments

Entries are logged as **"Pending Verification"**. To verify:

1. Open your UPI app → check transaction history
2. Go to Supabase → **Table Editor** → `contributions`
3. Match amounts → update the `status` column to `Verified`

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Could not load contributions" | Check that SUPABASE_URL and SUPABASE_ANON_KEY are correct in CONFIG |
| "Something went wrong" on submit | Verify the `contributions` table exists (run `setup.sql` again) |
| UPI app doesn't open | UPI deep links only work on mobile with a UPI app installed |
| QR code not showing | Check internet — the QR library loads from CDN |
| Page shows "Setup Required" | You haven't replaced the placeholder Supabase credentials yet |
| CORS errors in console | Make sure you're using the `anon` key, not the `service_role` key |

---

## Security Notes

- The **anon key** is safe to expose in client-side code — that's its intended purpose
- **Row Level Security (RLS)** is enabled — users can only INSERT and SELECT, never UPDATE or DELETE
- Only you can edit/delete rows from the Supabase dashboard
- Input validation on both client and database level (name length, amount range)

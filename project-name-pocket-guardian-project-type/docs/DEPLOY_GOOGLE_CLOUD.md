# Deploy to Google Cloud — Beginner Guide (100% FREE)

> This guide gets your backend live on the internet for **free**, step by step.
> No prior cloud experience needed. Follow each step exactly.

We'll use:
- **Google Cloud Run** — runs your backend. Free forever (2 million requests/month).
- **Neon** — free PostgreSQL database. Free forever (no credit card, no expiry).

> **Why not Google's Cloud SQL database?** It costs ~$7/month (only free during the 90-day trial). Neon is free *forever*, so it's better for you. Your backend still runs on Google Cloud.

**Total cost: ₹0 / $0** — permanently.

---

# Part 1: Create a Free Database (Neon) — 5 minutes

1. Go to **https://neon.tech** and click **Sign up** (use your Google account)
2. Click **Create Project**
   - Name: `pocket-guardian`
   - Region: pick the one closest to you (e.g. Singapore for India)
3. After it's created, click **Connect** / **Connection String**
4. Copy the connection string. It looks like:
   ```
   postgresql://user:password@ep-xxxx.ap-southeast-1.aws.neon.tech/pocket-guardian?sslmode=require
   ```
5. **Save this somewhere** — you'll paste it in Part 3.

> Django needs `postgres://` — if your string starts with `postgresql://`, that's fine, it works too.

---

# Part 2: Set Up Google Cloud — 10 minutes

## 2.1 Create account (if you don't have one)

1. Go to **https://cloud.google.com/free**
2. Click **Get started for free**
3. Sign in with Google, enter card details (for verification — **you won't be charged** on free tier)

## 2.2 Install the gcloud CLI

- **Windows:** Download and run the installer from
  https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe
- **Mac:** `brew install --cask google-cloud-sdk`
- **Linux:** `curl https://sdk.cloud.google.com | bash` then restart your terminal

Verify it works:
```bash
gcloud --version
```

## 2.3 Login and create a project

```bash
# Login (opens browser)
gcloud auth login

# Create a project (the ID must be globally unique — add numbers if taken)
gcloud projects create pocket-guardian-12345 --name="Pocket Guardian"

# Set it as your active project
gcloud config set project pocket-guardian-12345
```

> Replace `pocket-guardian-12345` everywhere with your actual project ID.

## 2.4 Link billing (required even for free tier)

1. Go to **https://console.cloud.google.com/billing**
2. Link your project to your billing account (the free trial account is fine)

## 2.5 Enable the services we need

```bash
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
```

---

# Part 3: Deploy the Backend — 5 minutes

## 3.1 Generate a secret key

```bash
python -c "import secrets; print(secrets.token_urlsafe(50))"
```
Copy the output — this is your `DJANGO_SECRET_KEY`.

## 3.2 Deploy with ONE command

Navigate to the backend folder and run:

```bash
cd VIGIL/project-name-pocket-guardian-project-type/pocket_guardian_backend

gcloud run deploy pocket-guardian-backend \
  --source . \
  --region asia-south1 \
  --allow-unauthenticated \
  --set-env-vars "DJANGO_DEBUG=0" \
  --set-env-vars "DJANGO_ALLOWED_HOSTS=*" \
  --set-env-vars "SECURE_SSL_REDIRECT=0" \
  --set-env-vars "DJANGO_SECRET_KEY=PASTE_YOUR_SECRET_KEY_HERE" \
  --set-env-vars "^@^DATABASE_URL=PASTE_YOUR_NEON_STRING_HERE"
```

**Important notes:**
- Replace `PASTE_YOUR_SECRET_KEY_HERE` with the key from step 3.1
- Replace `PASTE_YOUR_NEON_STRING_HERE` with your Neon connection string from Part 1
- The `^@^` before DATABASE_URL tells gcloud to use `@` as the separator instead of `,` — needed because the database URL contains commas/special characters. Keep it exactly as shown.
- `asia-south1` is Mumbai. Change if you prefer another region.

The first time, gcloud will ask:
- *"Deploy from source? This will create an Artifact Registry repository"* → type **Y**
- It builds your Docker image in the cloud (~3-5 min) and deploys it

## 3.3 Get your live URL

When it finishes, you'll see:
```
Service URL: https://pocket-guardian-backend-xxxxx-el.a.run.app
```

**This is your live backend!** Migrations run automatically on startup.

## 3.4 Test it

Open in your browser:
```
https://YOUR_SERVICE_URL/api/dashboard/
```
You should see the guardian dashboard page.

---

# Part 4: Connect Your Phone App — 5 minutes

## 4.1 Build the APK pointing to your live backend

```bash
cd VIGIL/project-name-pocket-guardian-project-type/pocket_guardian

flutter build apk --release \
  --dart-define=POCKET_GUARDIAN_API_URL=https://YOUR_SERVICE_URL/api \
  --dart-define=POCKET_GUARDIAN_ENV=production
```

> Replace `YOUR_SERVICE_URL` with your Cloud Run URL from step 3.3.

## 4.2 Install on your phone

The APK is at:
```
build/app/outputs/flutter-apk/app-release.apk
```

Options to install:
- **USB cable connected:** run `flutter install`
- **No cable:** Send the APK file to your phone (WhatsApp/Drive/email), open it, tap Install. You may need to allow "Install from unknown sources" in settings.

## 4.3 Use it!

1. Open the app → Create account
2. Set your security PIN
3. Add emergency contact
4. Enable Pocket Mode and test

Check the dashboard (`https://YOUR_SERVICE_URL/api/dashboard/`) to see your alerts appear live.

---

# Updating After Code Changes

Whenever you change backend code, redeploy with:
```bash
cd pocket_guardian_backend
gcloud run deploy pocket-guardian-backend --source . --region asia-south1
```
(It remembers your env vars from last time.)

When you change app code, rebuild the APK (step 4.1) and reinstall.

---

# Create an Admin Login (optional)

To access `/admin/` and view all data:
```bash
# One-off command to create a superuser
gcloud run services proxy pocket-guardian-backend --region asia-south1
# Then in another terminal, or use the Cloud Run console "Execute" feature
```

Easier: temporarily set `DJANGO_DEBUG=1`, then use the signup API, or create the user via a Cloud Run Job. Ask me if you need this.

---

# Troubleshooting

| Problem | Fix |
|---------|-----|
| `billing account not found` | Link billing at console.cloud.google.com/billing |
| Build fails | Make sure you're in the `pocket_guardian_backend` folder (where the Dockerfile is) |
| `DATABASE_URL` error | Check the `^@^` prefix is included; verify Neon string is correct |
| Dashboard shows 500 error | Check logs: `gcloud run services logs read pocket-guardian-backend --region asia-south1` |
| App can't connect | Verify the URL in `--dart-define` matches your Cloud Run URL exactly, with `/api` at the end |
| "Service Unavailable" first load | Normal cold start — wait 5 seconds and refresh |

### View live logs anytime:
```bash
gcloud run services logs read pocket-guardian-backend --region asia-south1 --limit 50
```

---

# Cost Reminder

- **Cloud Run:** Free (you'd need 2 million requests/month to pay anything)
- **Neon database:** Free forever
- **Cloud Build:** 120 free build-minutes/day (each deploy uses ~3-4 min)

You will **not** be charged for normal personal use. To be 100% safe, set a budget alert:
1. Go to https://console.cloud.google.com/billing/budgets
2. Create a budget of ₹100 with email alerts

---

# About Your Google Developer Student Enrollment

- If you did **Google Cloud Study Jams / GDSC**, you may have gotten Cloud Skills Boost credits — those are for *learning labs*, not for hosting your own app.
- The **$300 free trial** (Part 2) is separate and available to everyone.
- For this project you don't even need the $300 — Cloud Run's always-free tier + Neon covers everything.

Check any credits at: https://console.cloud.google.com/billing

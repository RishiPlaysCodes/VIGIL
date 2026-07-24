# Google Cloud Deployment Guide (FREE Tier)

> Deploy Pocket Guardian backend to Google Cloud **completely free** using Cloud Run + Cloud SQL.

---

## What You'll Use (All Free)

| Service | Free Tier Limit | Our Usage |
|---------|----------------|-----------|
| **Cloud Run** | 2 million requests/month, 360,000 GB-seconds | Way under limit for personal use |
| **Cloud SQL (PostgreSQL)** | Not free, but we use **$300 free trial credits** | ~$7/month (covered by credits) |
| **Artifact Registry** | 500 MB storage free | Docker image storage |
| **Cloud Storage** | 5 GB free | Media/photo storage |

### Free Options:
1. **$300 Free Trial** — New Google Cloud accounts get $300 credits for 90 days
2. **Google Developer Student** — If you enrolled in GDSC, you might have credits
3. **Always Free Tier** — Cloud Run stays free forever within limits

---

## Prerequisites

- Google account (Gmail)
- Credit/Debit card (for verification only — won't be charged on free tier)
- `gcloud` CLI installed on your PC

---

## Step 0: Check Your Google Cloud / Student Account

### If you enrolled in Google Developer Student Club (GDSC):

1. Go to: https://cloud.google.com/edu/students
2. Check if you have active credits under your account
3. OR go to: https://console.cloud.google.com/billing
4. If you see a billing account with credits, you're good!

### If you're new to Google Cloud:

1. Go to: https://cloud.google.com/free
2. Click **"Get started for free"**
3. Sign in with your Google account
4. Enter card details (verification only, **FREE trial = $300 credits for 90 days**)
5. You'll see "Free Trial" active in console

---

## Step 1: Install Google Cloud CLI

### Windows (PowerShell):
```powershell
# Download and run installer
(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:temp\GoogleCloudSDKInstaller.exe")
& "$env:temp\GoogleCloudSDKInstaller.exe"
```

### Mac:
```bash
brew install google-cloud-sdk
```

### Linux:
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### Verify installation:
```bash
gcloud --version
```

---

## Step 2: Login & Create Project

```bash
# Login to Google Cloud
gcloud auth login

# Create a new project (choose a unique name)
gcloud projects create pocket-guardian-prod --name="Pocket Guardian"

# Set it as active project
gcloud config set project pocket-guardian-prod

# Enable billing (links to your free trial)
# Go to: https://console.cloud.google.com/billing
# Link the project to your billing account

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

---

## Step 3: Create PostgreSQL Database (Cloud SQL)

```bash
# Create a PostgreSQL instance (smallest = cheapest, covered by free credits)
gcloud sql instances create pocket-guardian-db \
  --database-version=POSTGRES_16 \
  --tier=db-f1-micro \
  --region=asia-south1 \
  --storage-size=10GB \
  --storage-type=HDD

# Set the database password
gcloud sql users set-password postgres \
  --instance=pocket-guardian-db \
  --password=YOUR_STRONG_PASSWORD_HERE

# Create the database
gcloud sql databases create pocket_guardian \
  --instance=pocket-guardian-db
```

> **Note:** `asia-south1` = Mumbai. Choose the region closest to you.
> `db-f1-micro` is the cheapest tier (~$7/month, covered by $300 credits).

### Get the connection name (you'll need this later):
```bash
gcloud sql instances describe pocket-guardian-db --format="value(connectionName)"
# Output will be like: pocket-guardian-prod:asia-south1:pocket-guardian-db
```

---

## Step 4: Store Secrets Securely

```bash
# Generate a secret key
python -c "import secrets; print(secrets.token_urlsafe(50))"
# Copy the output

# Store secrets in Google Secret Manager
echo -n "YOUR_GENERATED_SECRET_KEY" | gcloud secrets create django-secret-key --data-file=-
echo -n "YOUR_STRONG_PASSWORD_HERE" | gcloud secrets create db-password --data-file=-
```

---

## Step 5: Create Artifact Registry (Docker Image Storage)

```bash
gcloud artifacts repositories create pocket-guardian \
  --repository-format=docker \
  --location=asia-south1 \
  --description="Pocket Guardian Docker images"
```

---

## Step 6: Build & Push Docker Image

```bash
# Navigate to the backend directory
cd VIGIL/project-name-pocket-guardian-project-type/pocket_guardian_backend

# Configure Docker authentication
gcloud auth configure-docker asia-south1-docker.pkg.dev

# Build and push using Cloud Build (no local Docker needed!)
gcloud builds submit \
  --tag asia-south1-docker.pkg.dev/pocket-guardian-prod/pocket-guardian/backend:latest
```

> This builds the Docker image in the cloud and stores it. No Docker needed on your PC!

---

## Step 7: Deploy to Cloud Run

```bash
# Get your connection name from Step 3
CONNECTION_NAME=$(gcloud sql instances describe pocket-guardian-db --format="value(connectionName)")

# Deploy!
gcloud run deploy pocket-guardian-backend \
  --image=asia-south1-docker.pkg.dev/pocket-guardian-prod/pocket-guardian/backend:latest \
  --region=asia-south1 \
  --platform=managed \
  --allow-unauthenticated \
  --port=8000 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=2 \
  --add-cloudsql-instances=$CONNECTION_NAME \
  --set-env-vars="DJANGO_DEBUG=0" \
  --set-env-vars="DJANGO_ALLOWED_HOSTS=*" \
  --set-env-vars="DATABASE_URL=postgres://postgres:YOUR_STRONG_PASSWORD_HERE@/pocket_guardian?host=/cloudsql/$CONNECTION_NAME" \
  --set-env-vars="SECURE_SSL_REDIRECT=0" \
  --set-secrets="DJANGO_SECRET_KEY=django-secret-key:latest"
```

### After deployment, you'll see:
```
Service [pocket-guardian-backend] revision [...] has been deployed
Service URL: https://pocket-guardian-backend-xxxxx-xx.a.run.app
```

**Save this URL! This is your production backend.**

---

## Step 8: Run Database Migrations

```bash
# Run migrations on the deployed service
gcloud run jobs create migrate-db \
  --image=asia-south1-docker.pkg.dev/pocket-guardian-prod/pocket-guardian/backend:latest \
  --region=asia-south1 \
  --add-cloudsql-instances=$CONNECTION_NAME \
  --set-env-vars="DJANGO_DEBUG=0" \
  --set-env-vars="DATABASE_URL=postgres://postgres:YOUR_STRONG_PASSWORD_HERE@/pocket_guardian?host=/cloudsql/$CONNECTION_NAME" \
  --set-secrets="DJANGO_SECRET_KEY=django-secret-key:latest" \
  --command="python" \
  --args="manage.py,migrate,--noinput"

# Execute the migration job
gcloud run jobs execute migrate-db --region=asia-south1 --wait
```

---

## Step 9: Connect Flutter App to Production Backend

```bash
cd pocket_guardian

# Build APK pointing to your Cloud Run URL
flutter build apk --release \
  --dart-define=POCKET_GUARDIAN_API_URL=https://pocket-guardian-backend-xxxxx-xx.a.run.app/api \
  --dart-define=POCKET_GUARDIAN_ENV=production
```

Transfer the APK to your phone:
```bash
# If phone is connected via USB:
flutter install

# Or find APK at:
# build/app/outputs/flutter-apk/app-release.apk
# Transfer via WhatsApp, Drive, cable, etc.
```

---

## Step 10: Verify Everything Works

1. **Open browser:** `https://YOUR_CLOUD_RUN_URL/api/dashboard/`
2. **Open app on phone:** Create account, set PIN, enable Pocket Mode
3. **Trigger a test alert:** Use the strong movement button
4. **Check dashboard:** See the alert appear

---

## Cost Breakdown (You Won't Pay Anything)

| Service | Monthly Cost | Free Coverage |
|---------|-------------|---------------|
| Cloud Run | $0 | Always free (under 2M requests) |
| Cloud SQL (db-f1-micro) | ~$7-9 | Covered by $300 free credits |
| Artifact Registry | $0 | Under 500MB free |
| Cloud Build | $0 | 120 min/day free |
| **Total** | **~$7-9/month** | **$300 credits = ~33 months free** |

After $300 credits expire, you can:
- Downgrade to Cloud SQL Starter (free tier when available)
- Switch to Supabase free tier for PostgreSQL
- Or just keep paying ~$7/month

---

## Updating Your App After Code Changes

### Redeploy backend:
```bash
cd pocket_guardian_backend

# Build and push new image
gcloud builds submit \
  --tag asia-south1-docker.pkg.dev/pocket-guardian-prod/pocket-guardian/backend:latest

# Deploy new version
gcloud run deploy pocket-guardian-backend \
  --image=asia-south1-docker.pkg.dev/pocket-guardian-prod/pocket-guardian/backend:latest \
  --region=asia-south1
```

### Rebuild Flutter app:
```bash
cd pocket_guardian
flutter build apk --release \
  --dart-define=POCKET_GUARDIAN_API_URL=https://YOUR_CLOUD_RUN_URL/api \
  --dart-define=POCKET_GUARDIAN_ENV=production
```

---

## One-Line Deploy Script

Create `deploy.sh` in your project root:

```bash
#!/bin/bash
set -e

PROJECT_ID="pocket-guardian-prod"
REGION="asia-south1"
IMAGE="asia-south1-docker.pkg.dev/$PROJECT_ID/pocket-guardian/backend:latest"

echo "Building and pushing Docker image..."
cd pocket_guardian_backend
gcloud builds submit --tag $IMAGE --project $PROJECT_ID

echo "Deploying to Cloud Run..."
gcloud run deploy pocket-guardian-backend \
  --image=$IMAGE \
  --region=$REGION \
  --project=$PROJECT_ID

echo "Done! Check your service URL above."
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Billing not enabled" | Go to console.cloud.google.com/billing and link project |
| "Permission denied" | Run `gcloud auth login` again |
| Cloud Build fails | Check Dockerfile exists in the directory |
| App can't reach backend | Check the Cloud Run URL is correct in --dart-define |
| Database connection error | Verify CONNECTION_NAME and password are correct |
| "Cold start" slow first request | Normal for min-instances=0, first request takes 3-5 sec |
| Credits running low | Check at console.cloud.google.com/billing |

---

## Alternative: Even Simpler (No Cloud SQL)

If you want **zero cost** after free trial expires, use SQLite on Cloud Run:

> **Warning:** SQLite on Cloud Run loses data when the container restarts. Only use for testing.

```bash
gcloud run deploy pocket-guardian-backend \
  --source=. \
  --region=asia-south1 \
  --allow-unauthenticated \
  --set-env-vars="DJANGO_SECRET_KEY=your-key,DJANGO_DEBUG=0,DJANGO_ALLOWED_HOSTS=*"
```

For a permanent free database, consider:
- **Supabase** (free PostgreSQL, 500 MB)
- **Neon** (free PostgreSQL, 512 MB)
- **PlanetScale** (free MySQL, 5 GB)

---

## Google Developer Student Club (GDSC) Specific

If you enrolled in GDSC:
1. Check https://cloud.google.com/edu/students for any active programs
2. Some GDSC events give out **Qwiklabs credits** — these work for Cloud Skills Boost labs but NOT for deploying your own apps
3. The **$300 free trial** is separate from GDSC — anyone can get it
4. If your campus had a "Google Cloud Study Jam" you might have gotten extra credits — check your billing at console.cloud.google.com

**Bottom line:** Just sign up for the regular $300 free trial. It's the easiest path.

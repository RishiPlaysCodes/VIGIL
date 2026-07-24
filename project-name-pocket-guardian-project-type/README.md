# Pocket Guardian (VIGIL)

> Smart anti-theft and personal safety mobile app with real-time alerting, evidence capture, and guardian notifications.

## Architecture Overview

```
+─────────────────────+     HTTPS      +──────────────────────+
|   Flutter Mobile    | ◄────────────► |   Django Backend     |
|   (Android / iOS)   |                |   (REST API)         |
+─────────────────────+                +──────────────────────+
       │                                       │
       │ Native Platform                       │ Services
       ├─ Foreground Service (sensors)         ├─ PostgreSQL
       ├─ Camera2 (intruder photo)             ├─ Email (SMTP)
       ├─ SMS Manager                          ├─ SMS (Twilio/MSG91)
       └─ AlarmManager (scheduling)            └─ File Storage (media)
```

## Project Structure

```
project-name-pocket-guardian-project-type/
├── pocket_guardian/              # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart            # Entry point with error boundaries
│   │   └── src/
│   │       ├── config/          # App configuration
│   │       ├── models.dart      # Data models
│   │       ├── screens/         # UI screens
│   │       ├── services/        # API, storage, logging, connectivity
│   │       └── widgets/         # Reusable UI components
│   ├── android/                 # Android native (Kotlin)
│   ├── ios/                     # iOS configuration
│   └── test/                    # Widget & unit tests
├── pocket_guardian_backend/      # Django REST API
│   ├── alerts/                  # Core app (models, views, services)
│   ├── pocket_guardian_backend/ # Django project settings
│   ├── Dockerfile               # Production container
│   └── requirements.txt         # Python dependencies
├── docker-compose.yml           # Local development stack
└── .github/workflows/           # CI/CD pipelines
```

## Features

### Mobile App
- **Pocket Mode** — motion-sensor-based theft detection with configurable sensitivity
- **Lock-screen emergency UI** — native Android activity shown over lock screen
- **Intruder photo capture** — front camera auto-capture on failed verification
- **Emergency SMS** — automatic SMS to trusted contact with location
- **Biometric + PIN verification** — multi-factor alert cancellation
- **Daily scheduling** — automatic Pocket Mode activation windows
- **Travel timer** — delayed auto-activation for commuters
- **Background execution** — foreground service for continuous monitoring
- **Encrypted storage** — tokens and PINs stored in platform keychain

### Backend
- **Token-based auth** — with automatic expiration and rotation
- **Alert management** — create, track, and review alerts with photo evidence
- **Email notifications** — with photo attachments to guardian contacts
- **SMS notifications** — via Twilio or MSG91 providers
- **Guardian dashboard** — web UI for reviewing alerts and locations
- **Rate limiting** — prevents brute-force authentication attacks
- **Location tracking** — real-time location pings during active monitoring

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Local Testing (VS Code)](docs/LOCAL_TESTING_VSCODE.md) | Step-by-step VS Code setup, testing commands, launch configs |
| [Deploy to Google Cloud (FREE)](docs/DEPLOY_GOOGLE_CLOUD.md) | Full Google Cloud Run deployment with $300 free credits |
| [Security Policy](SECURITY.md) | Vulnerability reporting and security architecture |

---

## Quick Start (Development)

### Prerequisites
- Flutter SDK 3.32+
- Python 3.12+
- Docker & Docker Compose (optional, for backend)

### Backend

**Option A: Docker (recommended)**
```bash
cd project-name-pocket-guardian-project-type
docker compose up --build
```
Backend available at `http://localhost:8000/api/`

**Option B: Manual**
```bash
cd project-name-pocket-guardian-project-type/pocket_guardian_backend

# Create virtual environment
python -m venv .venv && source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set required environment variable
export DJANGO_SECRET_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(50))")
export DJANGO_DEBUG=1
export DJANGO_ALLOWED_HOSTS=127.0.0.1,localhost

# Run migrations and start server
python manage.py migrate
python manage.py runserver
```

### Flutter App
```bash
cd project-name-pocket-guardian-project-type/pocket_guardian

flutter pub get
flutter run
```

For a physical Android device on the same network:
```bash
flutter run --dart-define=POCKET_GUARDIAN_API_URL=http://YOUR_IP:8000/api
```

---

## Production Deployment

### Google Cloud (Recommended — FREE)

Deploy the backend to Google Cloud Run using the **$300 free trial credits**:

```bash
# 1. Install gcloud CLI and login
gcloud auth login
gcloud config set project pocket-guardian-prod

# 2. Enable APIs
gcloud services enable run.googleapis.com sqladmin.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com

# 3. Build & deploy (from pocket_guardian_backend directory)
gcloud builds submit --tag asia-south1-docker.pkg.dev/pocket-guardian-prod/pocket-guardian/backend:latest
gcloud run deploy pocket-guardian-backend \
  --image=asia-south1-docker.pkg.dev/pocket-guardian-prod/pocket-guardian/backend:latest \
  --region=asia-south1 \
  --allow-unauthenticated

# 4. Build Flutter APK pointing to Cloud Run URL
flutter build apk --release \
  --dart-define=POCKET_GUARDIAN_API_URL=https://YOUR_CLOUD_RUN_URL/api \
  --dart-define=POCKET_GUARDIAN_ENV=production
```

**Full step-by-step guide:** [docs/DEPLOY_GOOGLE_CLOUD.md](docs/DEPLOY_GOOGLE_CLOUD.md)

### Docker (Self-hosted)

#### Backend Deployment

#### Environment Variables (required)

| Variable | Description | Example |
|----------|-------------|---------|
| `DJANGO_SECRET_KEY` | Cryptographic secret (generate fresh) | `python -c "import secrets; print(secrets.token_urlsafe(50))"` |
| `DJANGO_DEBUG` | Must be `0` in production | `0` |
| `DJANGO_ALLOWED_HOSTS` | Comma-separated hostnames | `api.yourapp.com` |
| `DATABASE_URL` | PostgreSQL connection string | `postgres://user:pass@host:5432/dbname` |
| `CORS_ALLOWED_ORIGINS` | Allowed frontend origins | `https://dashboard.yourapp.com` |

See `.env.example` for full list including email and SMS provider credentials.

#### Deploy with Docker
```bash
# Build production image
docker build -t pocket-guardian-backend ./pocket_guardian_backend

# Run with environment
docker run -d \
  --name pocket-guardian \
  -p 8000:8000 \
  -e DJANGO_SECRET_KEY="your-secret" \
  -e DJANGO_DEBUG=0 \
  -e DJANGO_ALLOWED_HOSTS="api.yourapp.com" \
  -e DATABASE_URL="postgres://..." \
  pocket-guardian-backend
```

#### Database Setup
```bash
# Run migrations
docker exec pocket-guardian python manage.py migrate

# Create admin user
docker exec -it pocket-guardian python manage.py createsuperuser

# Set up periodic token cleanup (add to cron)
# 0 3 * * * docker exec pocket-guardian python manage.py cleanup_expired_tokens
```

### Mobile App Release

#### Android APK/AAB
```bash
cd pocket_guardian

# Generate signing key (one-time)
keytool -genkey -v -keystore pocket-guardian-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias pocket_guardian

# Build release
flutter build appbundle --release \
  --dart-define=POCKET_GUARDIAN_ENV=production \
  --dart-define=POCKET_GUARDIAN_API_URL=https://api.yourapp.com/api
```

Set signing environment variables:
```bash
export KEYSTORE_FILE=/path/to/pocket-guardian-release.jks
export KEYSTORE_PASSWORD=your_password
export KEY_ALIAS=pocket_guardian
export KEY_PASSWORD=your_password
```

#### iOS
```bash
flutter build ipa --release \
  --dart-define=POCKET_GUARDIAN_ENV=production \
  --dart-define=POCKET_GUARDIAN_API_URL=https://api.yourapp.com/api
```

---

## Security Architecture

### Authentication Flow
1. User signs up/logs in via API
2. Server generates a 64-character hex token stored in `ApiToken` model
3. Token stored in device keychain (EncryptedSharedPreferences / iOS Keychain)
4. All API requests authenticated via `Authorization: Token <key>` header
5. Tokens auto-expire after 30 days (configurable via `API_TOKEN_EXPIRY_SECONDS`)
6. Expired tokens are rotated on next login

### Rate Limiting
- Login/signup: 5 attempts per IP per 5-minute window
- Returns HTTP 429 when exceeded

### Data Protection
- Security PIN stored in platform encrypted storage (never in SharedPreferences)
- API tokens stored in Flutter Secure Storage (AES-encrypted)
- HTTPS enforced in production via `SECURE_SSL_REDIRECT`
- Security headers (HSTS, X-Frame-Options, CSP) applied in production

### Mobile Security
- ProGuard/R8 code shrinking enabled for release builds
- No hardcoded secrets or credentials in source code
- Debug builds use separate application ID suffix (`.debug`)

---

## CI/CD

GitHub Actions workflows are configured for:

| Workflow | Trigger | Steps |
|----------|---------|-------|
| `backend-ci.yml` | Push/PR to backend code | Lint (ruff), test (PostgreSQL), security audit |
| `flutter-ci.yml` | Push/PR to Flutter code | Analyze, format check, test, build APK, build iOS |

---

## Testing

### Backend
```bash
cd pocket_guardian_backend
python manage.py test
```

### Flutter
```bash
cd pocket_guardian
flutter test
```

---

## Maintenance

### Token Cleanup
Run periodically to remove expired tokens:
```bash
python manage.py cleanup_expired_tokens
```

### Database Backups
```bash
pg_dump -h localhost -U guardian pocket_guardian > backup_$(date +%Y%m%d).sql
```

### Monitoring Checklist
- [ ] Backend health endpoint responds (`/api/dashboard/`)
- [ ] Database connections healthy
- [ ] Email delivery working (check notification records)
- [ ] SMS delivery working (check notification records)
- [ ] Alert photo uploads succeeding
- [ ] Token cleanup cron running

---

## Device Testing Requirements

Before release, test on physical devices for:
- [ ] Alarm triggers correctly after motion detection
- [ ] Lock-screen emergency activity appears
- [ ] Intruder photo captures with front camera
- [ ] SMS sends to emergency contact
- [ ] Background service survives battery optimization
- [ ] Daily schedule activates after device reboot
- [ ] Biometric verification works on supported devices
- [ ] Custom ringtone plays correctly
- [ ] Location accuracy under different modes

Test on at least 2 different Android brands (Samsung, Pixel, Xiaomi, etc.) due to varying battery optimization behaviors.

---

## Author

**Rishi** — [@RishiPlaysCodes](https://github.com/RishiPlaysCodes)

---

## License

Private — All rights reserved.

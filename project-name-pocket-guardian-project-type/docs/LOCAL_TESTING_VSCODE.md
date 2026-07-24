# VS Code Local Testing Guide

## Prerequisites

Install these before starting:

1. **Flutter SDK** — https://docs.flutter.dev/get-started/install
2. **Python 3.12+** — https://www.python.org/downloads/
3. **VS Code Extensions:**
   - Flutter (Dart-Code.flutter)
   - Dart (Dart-Code.dart-code)
   - Python (ms-python.python)
   - Docker (ms-azuretools.vscode-docker) (optional)

---

## Step 1: Clone the Repository

```bash
git clone https://github.com/RishiPlaysCodes/VIGIL.git
cd VIGIL/project-name-pocket-guardian-project-type
```

---

## Step 2: Run the Backend (Django)

### Terminal 1: Start Backend

```bash
# Navigate to backend
cd pocket_guardian_backend

# Create virtual environment
python -m venv .venv

# Activate it
# Windows:
.venv\Scripts\activate
# Mac/Linux:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set required environment variable (one-time)
# Windows PowerShell:
$env:DJANGO_SECRET_KEY = "my-dev-secret-key-change-in-production-12345"
$env:DJANGO_DEBUG = "1"
$env:DJANGO_ALLOWED_HOSTS = "127.0.0.1,localhost,10.0.2.2"

# Mac/Linux:
export DJANGO_SECRET_KEY="my-dev-secret-key-change-in-production-12345"
export DJANGO_DEBUG=1
export DJANGO_ALLOWED_HOSTS="127.0.0.1,localhost,10.0.2.2"

# Run database migrations
python manage.py migrate

# Create admin user (optional, for dashboard)
python manage.py createsuperuser

# Start the server
python manage.py runserver 0.0.0.0:8000
```

Backend is now running at: `http://127.0.0.1:8000/api/`  
Dashboard at: `http://127.0.0.1:8000/api/dashboard/`

---

## Step 3: Run the Flutter App

### Terminal 2: Start Flutter

```bash
# Navigate to Flutter app
cd pocket_guardian

# Get dependencies
flutter pub get

# Check connected devices
flutter devices

# Run on Android emulator (uses 10.0.2.2 to reach host)
flutter run

# Run on physical Android phone (replace YOUR_IP with your PC's local IP)
# Find your IP: ipconfig (Windows) or ifconfig (Mac/Linux)
flutter run --dart-define=POCKET_GUARDIAN_API_URL=http://YOUR_LOCAL_IP:8000/api
```

---

## Step 4: Testing the App Flow

### 4.1 Create Account
1. Open the app
2. Enter a username (3+ chars) and password (8+ chars)
3. Tap "Create account"

### 4.2 Set Security PIN
1. When you first enable Pocket Mode, a PIN setup dialog appears
2. Enter a 4-8 digit PIN and confirm it
3. This PIN is stored securely in device keychain

### 4.3 Test Pocket Mode
1. Toggle "Enable Pocket Mode" ON
2. The native foreground service starts
3. Try the test buttons: "Small shake", "Strong movement", "Screen wake"
4. When countdown starts, enter your PIN to cancel

### 4.4 Set Emergency Contact
1. Go to Contacts tab
2. Enter a name, phone number, and email
3. These get synced to the backend

### 4.5 Check Dashboard
1. Open browser: `http://127.0.0.1:8000/api/dashboard/`
2. See alerts, locations, notification status

---

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| `flutter pub get` fails | Run `flutter doctor` and fix issues |
| Backend won't start | Check DJANGO_SECRET_KEY is set |
| App can't connect to backend | Check IP address, ensure phone/emulator is on same network |
| Android emulator can't reach backend | Use `10.0.2.2:8000` (Android emulator's host alias) |
| Physical phone can't connect | Use your PC's local IP (e.g., `192.168.1.x`) |
| Permission denied on phone | Go to Settings > Apps > Pocket Guardian > Permissions |
| Camera not working in emulator | Use physical device for camera testing |
| SMS not sending in emulator | SMS only works on real devices with SIM |

---

## VS Code Run Configurations

Create `.vscode/launch.json` in the `pocket_guardian` folder:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Debug - Emulator)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart"
    },
    {
      "name": "Flutter (Debug - Physical Device)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=POCKET_GUARDIAN_API_URL=http://192.168.1.100:8000/api"
      ]
    },
    {
      "name": "Flutter (Release Build)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "flutterMode": "release"
    }
  ]
}
```

---

## Build Release APK

```bash
cd pocket_guardian

# Debug APK (for testing on phone without Play Store)
flutter build apk --debug

# Release APK (optimized, smaller)
flutter build apk --release \
  --dart-define=POCKET_GUARDIAN_API_URL=https://your-backend-url.com/api \
  --dart-define=POCKET_GUARDIAN_ENV=production

# Find the APK at:
# build/app/outputs/flutter-apk/app-release.apk
```

Transfer the APK to your phone and install it directly.

---

## Quick Reference Commands

```bash
# Flutter
flutter doctor          # Check setup
flutter pub get         # Install dependencies
flutter pub upgrade     # Upgrade dependencies
flutter analyze         # Lint code
flutter test            # Run tests
flutter run             # Run app (debug)
flutter build apk      # Build APK

# Backend
python manage.py migrate              # Apply DB changes
python manage.py runserver 0.0.0.0:8000  # Start server
python manage.py createsuperuser      # Create admin
python manage.py cleanup_expired_tokens  # Clean old tokens
python manage.py shell                # Django shell
```

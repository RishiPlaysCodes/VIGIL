# VIGIL - Your Personal Safety Guardian

<div align="center">

**Anti-Theft & Personal Safety Mobile App**

*Protect your phone during travel — buses, metro, markets, and crowded places.*

</div>

---

## Overview

Vigil is a mobile anti-theft and personal safety application that detects when your phone is suspiciously removed from your pocket or bag. It uses smart multi-sensor detection to reduce false alarms and alerts trusted contacts with your location and intruder evidence.

## Architecture

```
VIGIL/
├── backend/          # Django REST API
│   ├── accounts/     # User auth, profiles, settings
│   ├── alerts/       # Alert management & notifications
│   ├── contacts/     # Emergency contacts
│   ├── location/     # Location tracking & sync
│   └── dashboard/    # Dashboard statistics
└── frontend/         # Flutter Mobile App
    └── vigil_app/
        └── lib/
            ├── screens/    # Premium UI screens
            ├── services/   # Core detection & alert services
            ├── widgets/    # Reusable glassmorphism components
            ├── theme/      # Dark premium theme
            └── models/     # Data models
```

## Features

### Smart Detection
- **Proximity Sensor** — Detects near/far state (in/out of pocket)
- **Light Sensor** — Detects dark (pocket) vs exposed (removed)
- **Motion Sensor** — Detects suspicious grab vs normal movement
- **Combined Analysis** — Requires 2/3 signals to trigger (reduces false alarms)
- **False Alarm Filter** — Ignores walking, bus brakes, pocket shifting

### Alert Flow
1. Phone enters pocket → monitoring active
2. Suspicious removal detected → grace period starts (default 3s)
3. User can tap "Using phone — pause 5 min" notification
4. Grace expires → Safety screen shows "Are you safe?"
5. Not cancelled → Loud alarm + location share + intruder photo + contact alerts

### Customization
- Grace period: 3 / 5 / 10 / 20 seconds
- Daily schedule with start/end travel window
- Battery saver & high security modes
- Custom alarm ringtone selection
- Safety avatar / lock-screen image
- Emergency contact management

### Premium UI
- Dark navy / cyan safety theme
- Glassmorphism card design
- 3D depth and glow effects
- Smooth animations throughout
- Strong "Vigil" branding

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter (Dart) |
| Backend API | Django + Django REST Framework |
| Auth | JWT (SimpleJWT) |
| Database | SQLite (dev) / PostgreSQL (prod) |
| SMS | MSG91 / Twilio |
| Email | SMTP (Gmail / any provider) |

## Getting Started

### Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env  # Edit with your keys
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

### Frontend Setup

```bash
cd frontend/vigil_app
flutter pub get
flutter run
```

### Required Permissions (Android)

- `ACCESS_FINE_LOCATION` — GPS tracking
- `ACCESS_BACKGROUND_LOCATION` — Background location sync
- `CAMERA` — Intruder photo capture
- `BODY_SENSORS` / sensor access — Proximity, light, accelerometer
- `POST_NOTIFICATIONS` — Alert notifications
- `WAKE_LOCK` — Screen wake during alert
- `FOREGROUND_SERVICE` — Background protection

## Important Notes

- **Phone power-off**: A normal Android app cannot prevent the phone from being physically switched off.
- **Background camera**: Android restricts background camera use. Photo capture happens through the visible emergency safety screen.
- **Real SMS**: Requires a configured SMS provider (MSG91/Twilio) with valid API keys.
- **Background location**: Requires proper Android permissions and battery optimization handling.

## Project Status

### Completed
- Flutter mobile app with premium UI
- Django backend with full API
- Login/signup authentication
- Emergency contact management
- Pocket Mode with smart detection
- Alert history and dashboard
- Grace period with customization
- Alarm trigger flow
- Lock-screen safety check
- Location sync architecture
- Camera capture flow
- SMS/email notification architecture

### Needs Final Polish
- End-to-end SMS delivery with real provider
- Real device testing for background behavior
- Alarm persistence across all edge cases
- Permission onboarding flow improvements
- Production deployment

## License

Private — All rights reserved.

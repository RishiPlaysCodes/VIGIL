# Pocket Guardian

Pocket Guardian is a mobile safety and anti-theft MVP made of:

- a Flutter mobile app
- a Django backend
- a browser dashboard for alert history and notification status

## What is already built

### Mobile app

- polished multi-screen mobile experience with auth, home, history, contacts, and settings
- account creation and sign-in against the backend
- emergency contact setup with phone and email
- Pocket Mode on/off
- travel timer auto-activation
- daily scheduled Pocket Mode preference with user-selected start time
- reboot-aware Android alarm receiver configuration for restoring schedules after restart
- motion detection using device sensors
- Android foreground-service support for active Pocket Mode monitoring
- screen-wake simulation hooks for demo testing
- countdown + cancel flow
- local PIN cancel path
- alarm feedback
- current location capture
- intruder photo capture attempt and backend upload endpoint
- local alert history
- backend sync for triggered and cancelled alerts

### Backend

- signup and login APIs with token-based mobile authentication
- emergency-contact API
- alert API
- notification records
- automatic email notification sending when a contact email is available
- provider-ready SMS notification interface with a console development provider
- admin support
- dashboard at `/api/dashboard/`
- detail pages at `/api/alerts/<id>/`
- guardian-friendly dashboard links for latest locations and photo evidence previews

## Project folders

- `pocket_guardian/` — Flutter app
- `pocket_guardian_backend/` — Django backend

## Run the backend

```powershell
cd pocket_guardian_backend
python manage.py migrate
python manage.py runserver
```

Dashboard:

```text
http://127.0.0.1:8000/api/dashboard/
```

## Run the Flutter app

```powershell
cd pocket_guardian
flutter pub get
flutter run
```

Android emulator uses this backend URL by default:

```text
http://10.0.2.2:8000/api
```

For a real Android phone, run with:

```powershell
flutter run --dart-define=POCKET_GUARDIAN_API_URL=http://YOUR_LOCAL_IP:8000/api
```

## Email behavior

The backend currently uses Django's console email backend, so emergency emails are printed in the backend terminal during development. To send real email, replace the email settings in `pocket_guardian_backend/settings.py` with SMTP credentials.

For deployment, copy `.env.example` values into your real environment and set SMTP credentials there instead of hardcoding secrets.

## What still depends on external setup

These are not missing code features; they require real device or provider access:

- testing motion sensors, camera, and GPS on a physical phone
- enabling Windows Developer Mode if building Flutter desktop plugins locally
- adding real SMTP/SMS/push credentials for production delivery
- operating-system permissions for background camera/location behavior

## Demo PIN

The local demo cancel PIN is:

```text
1234
```

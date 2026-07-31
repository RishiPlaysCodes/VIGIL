# VIGIL (Pocket Guardian) — Complete Code Documentation

> This document explains **every file, function, class, and technology** used in the project.
> Written by: **RishiPlaysCodes**

---

## Table of Contents

1. [Technologies Used](#technologies-used)
2. [Project Architecture](#project-architecture)
3. [Flutter App — File-by-File Explanation](#flutter-app)
4. [Android Native Code (Kotlin)](#android-native-code)
5. [Django Backend — File-by-File Explanation](#django-backend)
6. [CI/CD Pipelines](#cicd-pipelines)
7. [Docker & Deployment](#docker--deployment)
8. [Data Flow Diagrams](#data-flow-diagrams)
9. [Security Implementation](#security-implementation)

---

## Technologies Used

### Frontend (Mobile App)
| Technology | Version | Purpose |
|-----------|---------|---------|
| **Flutter** | 3.44.x | Cross-platform mobile UI framework |
| **Dart** | 3.12.x | Programming language for Flutter |
| **Kotlin** | 1.9.x | Native Android code (foreground service, sensors) |
| **Material Design 3** | — | UI component library |

### Flutter Packages
| Package | Purpose |
|---------|---------|
| `sensors_plus` | Access accelerometer for motion detection |
| `geolocator` | GPS location capture |
| `camera` | Front camera for intruder photo |
| `http` | HTTP client for API calls |
| `shared_preferences` | Local key-value storage (non-sensitive) |
| `flutter_secure_storage` | Encrypted storage for tokens/PIN |
| `flutter_background` | Keep app running in background |
| `local_auth` | Biometric (fingerprint/face) authentication |
| `audioplayers` | Custom alarm sound playback |
| `file_picker` | Select custom ringtone/image files |
| `android_alarm_manager_plus` | Schedule daily auto-activation |
| `connectivity_plus` | Monitor network status |

### Backend
| Technology | Version | Purpose |
|-----------|---------|---------|
| **Django** | 6.0.4 | Python web framework (REST API) |
| **PostgreSQL** | 18 | Production database (via Neon) |
| **Gunicorn** | 23.0 | Production WSGI server |
| **WhiteNoise** | 6.9 | Serve static files efficiently |
| **Pillow** | 11.3 | Image processing (photo uploads) |
| **django-cors-headers** | 4.7 | Cross-Origin Resource Sharing |
| **dj-database-url** | 2.3 | Parse DATABASE_URL for PostgreSQL |
| **Docker** | — | Containerized deployment |

### Infrastructure
| Service | Purpose | Cost |
|---------|---------|------|
| **Render** | Backend hosting (Cloud Run alternative) | FREE |
| **Neon** | PostgreSQL database hosting | FREE |
| **GitHub** | Source code + CI/CD | FREE |
| **GitHub Actions** | Automated testing pipeline | FREE |

---


## Project Architecture

```
User's Phone                          Cloud (Internet)
┌─────────────────────┐              ┌──────────────────────┐
│  Flutter App (Dart)  │◄── HTTPS ──►│  Django Backend       │
│  ├─ UI Screens       │              │  (Render - Free)      │
│  ├─ Services Layer   │              │  ├─ REST API          │
│  └─ Config           │              │  ├─ Auth (Token)      │
│                      │              │  ├─ Alerts CRUD       │
│  Native Kotlin Code  │              │  └─ Email/SMS Service │
│  ├─ Foreground Svc   │              └──────────┬───────────┘
│  ├─ Sensor Listener  │                         │
│  ├─ Camera2 API      │              ┌──────────▼───────────┐
│  └─ SMS Manager      │              │  PostgreSQL (Neon)    │
└─────────────────────┘              │  ├─ Users             │
                                      │  ├─ Alerts            │
                                      │  ├─ Contacts          │
                                      │  ├─ LocationPings     │
                                      │  └─ Notifications     │
                                      └──────────────────────┘
```

### How It All Works Together:
1. User opens app → `AuthScreen` → creates account or logs in via API
2. Backend creates a `User` + generates a 64-char `ApiToken`
3. Token stored encrypted on phone via `flutter_secure_storage`
4. User enables **Pocket Mode** → native foreground service starts
5. Service monitors accelerometer, light, proximity sensors
6. If phone leaves pocket + movement detected → Emergency Activity launches
7. Countdown starts → if user doesn't enter PIN → alarm triggers
8. Alarm captures: location (GPS), intruder photo (front camera), sends SMS
9. All data synced to backend → guardian gets email notification with photo

---

## Flutter App

### File Structure:
```
pocket_guardian/lib/
├── main.dart                          ← App entry point
└── src/
    ├── app.dart                       ← MaterialApp configuration
    ├── config/
    │   └── app_config.dart            ← Compile-time configuration
    ├── models.dart                    ← Data classes and enums
    ├── screens/
    │   ├── auth_screen.dart           ← Login/signup UI
    │   ├── home_shell.dart            ← Main app logic (state management)
    │   ├── home_screen.dart           ← Home tab UI
    │   ├── history_screen.dart        ← Alert history tab
    │   ├── contacts_screen.dart       ← Emergency contact tab
    │   ├── settings_screen.dart       ← Settings tab
    │   └── pin_setup_screen.dart      ← PIN setup dialog
    ├── services/
    │   ├── api_service.dart           ← HTTP client with retry logic
    │   ├── secure_storage_service.dart ← Encrypted token/PIN storage
    │   ├── logger_service.dart        ← Centralized logging
    │   └── connectivity_service.dart  ← Network monitoring
    └── widgets/
        ├── glass_card.dart            ← Glassmorphism card widget
        └── section_card.dart          ← Section container widget
```

---


### `lib/main.dart` — Entry Point

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Required before async ops
  // Global error handling — catches all unhandled errors
  FlutterError.onError = ...       // Framework errors (widget build failures)
  PlatformDispatcher.instance.onError = ...  // Non-framework errors
  await AndroidAlarmManager.initialize();    // For daily scheduling
  runApp(const PocketGuardianApp());
}
```

**What it does:**
- Initializes Flutter engine
- Sets up global error boundaries (so app never crashes silently)
- Initializes the alarm manager (for scheduled pocket mode activation)
- Runs the root widget

---

### `lib/src/app.dart` — MaterialApp Configuration

```dart
class PocketGuardianApp extends StatelessWidget {
  // Configures:
  // - Light theme (teal seed color)
  // - Dark theme (auto-follows system)
  // - Material Design 3 components
  // - First screen: AuthScreen (login page)
}
```

**What it does:**
- Defines the app's visual theme (colors, typography)
- Sets the starting screen to `AuthScreen`
- Enables automatic dark/light mode switching

---

### `lib/src/config/app_config.dart` — Configuration

```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'POCKET_GUARDIAN_API_URL',
    defaultValue: 'https://pocket-guardian-backend.onrender.com/api',
  );
  static const bool isProduction = ...;
  static const int httpTimeoutSeconds = 60;
  static const int maxRetryAttempts = 2;
  static const int minPinLength = 4;
  static const int maxPinLength = 8;
  // ... more constants
}
```

**What it does:**
- All app-wide settings in one place
- `apiBaseUrl`: The backend URL (can be overridden at build time)
- `isProduction`: Tells the app if it's in production mode
- `httpTimeoutSeconds`: How long to wait for server response (60s for Render cold start)
- All values are compile-time constants (cannot be changed at runtime)

---

### `lib/src/models.dart` — Data Models

**`AlertRecord`** — Represents a single alert event:
```dart
class AlertRecord {
  final int? id;          // Backend database ID
  final DateTime time;    // When the alert happened
  final String reason;    // Why (e.g., "Continuous movement detected")
  final String status;    // "Alert sent" or "Cancelled"
  final double? latitude; // GPS coordinates
  final double? longitude;
  
  // Methods:
  toJson()              // Convert to JSON for storage/API
  fromJson()            // Create from JSON
  copyWith()            // Create modified copy (immutability)
}
```

**Enums:**
- `SecurityLevel` — `saver` / `balanced` / `highSecurity` (motion sensitivity)
- `LocationMode` — `alertOnly` / `travelWindow` / `whilePocketModeOn`
- `VerificationMode` — `pinOnly` / `biometricAndPin`
- `SafetyAvatar` — `guardian` / `fox` / `dragon` / `custom` (lock screen icon)

**`DailySchedule`** — Auto-activation time window:
```dart
class DailySchedule {
  final int startHour, startMinute;  // e.g., 08:00
  final int endHour, endMinute;      // e.g., 09:00
  final bool enabled;                // Is scheduling active?
}
```

---


### `lib/src/screens/auth_screen.dart` — Login/Signup

**Functions:**
| Function | Purpose |
|----------|---------|
| `_restoreSession()` | On app start, checks if user was previously logged in (from encrypted storage). If yes, skips login. |
| `_submit({createAccount})` | Calls `signUp()` or `login()` API. Saves token securely. Navigates to HomeShell. |
| `initState()` | Calls `_restoreSession()` + `_api.warmUp()` to wake the backend immediately |

**Security:**
- Password field is obscured (`obscureText: true`)
- Validates: username >=3 chars, password >=8 chars (for signup)
- Token stored in encrypted platform keychain (NOT SharedPreferences)
- Warm-up call wakes the Render server early so login is fast

**Error handling:**
- `ApiException` → shows server's error message
- Any other error → "Server is waking up. Please wait 30 seconds and try again."
- Shows "Connecting to server..." during loading (cold start awareness)

---

### `lib/src/screens/home_shell.dart` — Main Logic Hub (500+ lines)

This is the **brain of the app**. It manages ALL state and business logic.

**State Variables:**
```dart
bool _pocketModeEnabled    // Is pocket mode active?
bool _isCountingDown       // Is countdown running?
bool _alarmActive          // Is alarm blaring?
int _secondsRemaining      // Countdown timer value
String _statusMessage      // Current status text shown to user
String _lastKnownLocation  // GPS coordinates as text
String? _intruderPhotoPath // Path to captured photo
List<AlertRecord> _history // Alert history list
```

**Key Functions:**

| Function | What It Does |
|----------|-------------|
| `togglePocketMode(bool)` | Turns pocket mode ON/OFF. Starts/stops sensors, background service, location sharing. **Requires PIN setup first.** |
| `registerMovement(strongMovement)` | Called when sensor detects motion. If strong + screen wake = start countdown. |
| `detectScreenWake()` | Called when screen turns on unexpectedly (suspicious). |
| `_startCountdown(reason)` | 10-second countdown. If not cancelled → alarm triggers. |
| `cancelWithPin()` | User enters PIN to cancel alert. Checks PIN, biometric, stops countdown. |
| `_triggerAlarm()` | THE BIG ONE: captures location, photo, plays alarm, sends SMS, syncs to backend. |
| `resetAlarm()` | Stops the alarm (after user confirms they're safe). |
| `scheduleAutoActivation(minutes)` | "Activate pocket mode in X minutes" for commuters. |
| `_startMotionMonitoring()` | Subscribes to accelerometer stream. Filters by security level threshold. |
| `_captureCurrentLocation()` | Gets GPS position using Geolocator. |
| `_captureIntruderPhoto()` | Opens front camera, takes one photo, saves path. |
| `_sendEmergencySms()` | Sends SMS to emergency contact via native Kotlin bridge. |
| `_syncAlertSafe(status)` | Sends alert to backend. Catches errors silently (alarm works offline). |
| `saveContact()` | Saves contact locally + syncs to backend (debounced). |
| `_loadSecurityPin()` | Loads PIN from encrypted storage. |
| `_showPinSetupPrompt()` | Forces PIN setup dialog if user tries to enable pocket mode without PIN. |

**Lifecycle:**
- `initState()` → loads saved data, loads PIN, sets API token
- `dispose()` → cancels all timers, subscriptions, controllers
- `didChangeAppLifecycleState()` → on resume, checks for scheduled pocket mode requests

---

### `lib/src/screens/home_screen.dart` — Home Tab UI

Displays:
- Hero banner with app branding
- Status card (protection active/inactive/alarm)
- Pocket Mode toggle switch
- Test buttons (Small shake, Strong movement, Screen wake)
- Travel timer scheduler (1min, 5min, 15min)
- Countdown PIN entry (when counting down)
- Emergency alert details (when alarm active)

All logic is in HomeShell — this screen is purely UI (StatelessWidget).

---

### `lib/src/screens/pin_setup_screen.dart` — PIN Dialog

- Shows when user first enables Pocket Mode
- Requires 4-8 digit PIN
- Confirms by entering twice
- Saves to encrypted storage (`flutter_secure_storage`)
- Can also be accessed from Settings to change PIN

---


### `lib/src/services/api_service.dart` — HTTP Client

**Exception Hierarchy:**
```
ApiException (base)
├── NetworkException     — No internet / timeout
├── UnauthorizedException — 401 (invalid token)
├── RateLimitException   — 429 (too many attempts)
├── ServerException      — 5xx (backend crashed)
└── ValidationException  — 400 (bad input)
```

**Key Methods:**
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `signUp()` | `POST /signup/` | Create new account |
| `login()` | `POST /login/` | Authenticate and get token |
| `warmUp()` | `GET /dashboard/` | Wake up sleeping Render server |
| `syncContact()` | `POST /users/{id}/contacts/` | Save emergency contact |
| `syncAlert()` | `POST /users/{id}/alerts/` | Report triggered/cancelled alert |
| `uploadAlertPhoto()` | `POST /users/{id}/alerts/{id}/photo/` | Upload intruder photo |
| `syncLocation()` | `POST /users/{id}/location/` | Send GPS ping |

**Retry Logic (`_post` method):**
1. Makes HTTP request with 60-second timeout
2. If 2xx → success, return parsed JSON
3. If 4xx (except 429) → throw immediately (don't retry user errors)
4. If 5xx or 429 → wait (exponential backoff: 1s, 2s) → retry
5. If timeout/socket error → retry with backoff
6. After `maxRetryAttempts` (2) → throw NetworkException

**Headers sent on every request:**
```
Content-Type: application/json
Accept: application/json
Authorization: Token <user's token>  (if authenticated)
```

---

### `lib/src/services/secure_storage_service.dart` — Encrypted Storage

Uses platform-native encryption:
- **Android:** EncryptedSharedPreferences (AES-256)
- **iOS:** Keychain (hardware-backed on newer devices)

**Stored data:**
| Key | Content |
|-----|---------|
| `api_token` | User's authentication token |
| `user_id` | Backend user ID |
| `username` | Display username |
| `security_pin` | The alarm cancellation PIN |

**Methods:**
- `saveAuthSession()` — saves token + user info after login
- `getAuthSession()` — retrieves stored session (for auto-login)
- `clearAuthSession()` — called on logout
- `saveSecurityPin()` / `getSecurityPin()` — manage the PIN
- `deleteAll()` — nuclear option (clear everything)

---

### `lib/src/services/logger_service.dart` — Logging

**Levels:** `debug` < `info` < `warning` < `error`

- In **development**: all levels logged to console
- In **production**: only `warning` + `error` logged
- Error-level logs include stack traces
- Uses Dart's `developer.log()` for IDE integration

---

### `lib/src/services/connectivity_service.dart` — Network Monitor

- Listens to connectivity changes (WiFi/mobile/none)
- `isConnected` getter for quick checks
- `startMonitoring()` with callback for UI updates

---


## Android Native Code

Located in: `android/app/src/main/kotlin/com/example/pocket_guardian/`

### `MainActivity.kt` — Flutter ↔ Native Bridge

**MethodChannel:** `pocket_guardian/native`

| Method Call | What Native Code Does |
|-------------|----------------------|
| `playAlarm` | Plays device's default alarm ringtone at max volume |
| `stopAlarm` | Stops the alarm ringtone |
| `sendSms` | Sends SMS using Android's SmsManager (needs permission) |
| `placeCall` | Initiates a phone call to emergency contact |
| `startPocketGuardService` | Starts the foreground sensor monitoring service |
| `stopPocketGuardService` | Stops the foreground service |
| `requestEmergencyPermissions` | Requests SMS + Call + Notification permissions |

**Static helper methods:**
- `triggerNativeAlarm(context)` — plays custom ringtone if set, else default alarm
- `stopNativeAlarm()` — stops whatever alarm is playing

---

### `PocketGuardService.kt` — Foreground Sensor Service

This is the **core anti-theft engine** running even when the app is in background.

**How it works:**
1. Registers as a foreground service (shows persistent notification)
2. Acquires a WakeLock (prevents CPU from sleeping)
3. Listens to 3 sensors simultaneously:
   - **Accelerometer** — detects phone movement/shaking
   - **Light sensor** — detects when phone leaves dark pocket
   - **Proximity sensor** — detects when phone moves away from body

**Detection Logic:**
```
Pocket state:
  Light < 8 lux AND Proximity < max → Phone is IN pocket
  Light >= 8 lux OR Proximity >= max → Phone REMOVED from pocket

Alert trigger:
  Phone removed from pocket
  + Grace period expires (configurable: 3/5/10/20 seconds)
  + Strong movement detected (accelerometer magnitude > 185)
  + Not snoozed
  → Launch EmergencyActivity (lock screen alarm)
```

**Snooze feature:**
- User can tap "Using phone — pause 5 min" in notification
- Disables detection for 5 minutes (e.g., when intentionally using phone)

---

### `EmergencyActivity.kt` — Lock Screen Emergency UI

Shows over lock screen when suspicious activity detected.

**What it does:**
1. Shows full-screen overlay (works even when phone is locked)
2. Displays countdown timer (10 seconds)
3. Immediately captures photo using front camera (Camera2 API)
4. If user taps "I am safe" → alarm cancelled
5. If countdown expires:
   - Triggers loud alarm
   - Sends emergency SMS with location
   - Syncs alert to backend (creates alert record)
   - Stores captured photo path for upload when app resumes

**Camera capture flow:**
```
Open Camera → Create ImageReader → Capture request → Save JPEG to cache
→ Store path in SharedPreferences → Upload when app resumes
```

---

### `SnoozeReceiver.kt` — Broadcast Receiver

- Triggered when user taps "Pause 5 min" in the notification
- Sets a `snoozed_until` timestamp in SharedPreferences
- Refreshes the service notification text

---


## Django Backend

### File Structure:
```
pocket_guardian_backend/
├── manage.py                          ← Django CLI entry point
├── requirements.txt                   ← Python dependencies
├── Dockerfile                         ← Production container config
├── entrypoint.sh                      ← Startup script (migrate + serve)
├── .env.example                       ← Environment variable template
├── pocket_guardian_backend/
│   ├── settings.py                    ← Django configuration
│   ├── urls.py                        ← Root URL routing
│   └── wsgi.py                        ← WSGI application interface
└── alerts/
    ├── models.py                      ← Database models (5 tables)
    ├── views.py                       ← API endpoint handlers
    ├── urls.py                        ← API URL routing
    ├── services.py                    ← Email/SMS notification logic
    ├── providers.py                   ← SMS provider implementations
    ├── middleware.py                  ← Custom middleware (security, logging)
    ├── rate_limiter.py               ← Authentication rate limiting
    └── management/commands/
        └── cleanup_expired_tokens.py  ← Maintenance command
```

---

### `alerts/models.py` — Database Tables

**5 Models (tables in PostgreSQL):**

#### 1. `EmergencyContact`
| Field | Type | Purpose |
|-------|------|---------|
| `user` | ForeignKey → User | Owner of this contact |
| `name` | CharField(120) | Contact name |
| `phone_number` | CharField(30) | Phone number for SMS |
| `email` | EmailField | Email for notifications |
| `relationship` | CharField(80) | "Mother", "Friend", etc. |
| `is_primary` | Boolean | Main contact (gets alerts) |

#### 2. `ApiToken`
| Field | Type | Purpose |
|-------|------|---------|
| `user` | OneToOne → User | Token owner |
| `key` | CharField(64) | 64-character hex token |
| `created_at` | DateTime | When token was created |
| `last_used_at` | DateTime | Last API request time |

Methods:
- `is_expired` → checks if token is older than 30 days
- `rotate()` → generates new key, resets timestamp
- `touch()` → updates last_used_at

#### 3. `Alert`
| Field | Type | Purpose |
|-------|------|---------|
| `user` | ForeignKey → User | Who got alerted |
| `reason` | CharField(255) | "Continuous movement detected" |
| `status` | Choices: triggered/cancelled | Outcome |
| `latitude/longitude` | Decimal(9,6) | GPS at time of alert |
| `photo_path` | CharField(500) | Filename of evidence |
| `photo` | ImageField | Actual uploaded photo |
| `occurred_at` | DateTime | When it happened |

#### 4. `NotificationRecord`
| Field | Type | Purpose |
|-------|------|---------|
| `alert` | ForeignKey → Alert | Which alert |
| `contact` | ForeignKey → Contact | Who was notified |
| `channel` | Choices: sms/email/push | How |
| `status` | Choices: queued/sent/failed | Delivery status |
| `message` | TextField | Notification content |
| `error_message` | TextField | If failed, why |

#### 5. `LocationPing`
| Field | Type | Purpose |
|-------|------|---------|
| `user` | ForeignKey → User | Whose location |
| `latitude/longitude` | Decimal(9,6) | GPS coordinates |
| `recorded_at` | DateTime | When captured |

---

### `alerts/views.py` — API Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/signup/` | POST | No | Create new user account |
| `/api/login/` | POST | No | Authenticate, get token |
| `/api/users/{id}/contacts/` | GET, POST | Token | Manage emergency contacts |
| `/api/users/{id}/alerts/` | GET, POST | Token | View/create alerts |
| `/api/users/{id}/alerts/{id}/photo/` | POST | Token | Upload evidence photo |
| `/api/users/{id}/location/` | POST | Token | Record GPS ping |
| `/api/dashboard/` | GET | No | Web dashboard (HTML) |
| `/api/alerts/{id}/` | GET | No | Alert detail page (HTML) |

**Authentication flow in `_request_user()`:**
1. Read `Authorization` header
2. Extract token after "Token "
3. Look up in database
4. Check if expired (30-day TTL)
5. Update `last_used_at` timestamp
6. Return the associated User object

**Rate limiting on login/signup:**
- 5 failed attempts per IP address per 5-minute window
- Returns HTTP 429 when exceeded
- Resets on successful login

---


### `alerts/services.py` — Notification Dispatch

**`process_notification(notification)`:**
1. If channel is EMAIL:
   - Builds EmailMessage with alert details
   - Attaches intruder photo if available
   - Sends via Django's email backend (SMTP)
   - Updates status to "sent" or "failed"
2. If channel is SMS:
   - Gets SMS provider (Console/Twilio/MSG91)
   - Sends message to contact's phone number
   - Records delivery result

---

### `alerts/providers.py` — SMS Providers

Three implementations of `BaseSmsProvider`:

| Provider | When Used | How |
|----------|-----------|-----|
| `ConsoleSmsProvider` | Development | Prints SMS to terminal |
| `TwilioSmsProvider` | Production (international) | Twilio REST API |
| `Msg91SmsProvider` | Production (India) | MSG91 REST API |

Selected by `SMS_PROVIDER` env var. Default: `console`.

---

### `alerts/middleware.py` — Custom Middleware

3 middleware classes (run on every request):

| Middleware | Purpose |
|-----------|---------|
| `ContentLengthLimitMiddleware` | Rejects requests > 10MB (prevents abuse) |
| `RequestLoggingMiddleware` | Logs: method, path, status code, duration |
| `SecurityHeadersMiddleware` | Adds: X-Content-Type-Options, X-Frame-Options, Referrer-Policy |

---

### `alerts/rate_limiter.py` — Authentication Protection

**`RateLimiter` class:**
- Thread-safe (uses threading Lock)
- Sliding window algorithm
- Tracks failed attempts by IP address
- After 5 failures in 5 min → blocks further attempts
- Resets on successful login

---

### `pocket_guardian_backend/settings.py` — Configuration

**Key settings:**
| Setting | Development | Production |
|---------|-------------|------------|
| `SECRET_KEY` | Required from env | Required from env |
| `DEBUG` | `1` (True) | `0` (False) |
| `DATABASE` | SQLite (fallback) | PostgreSQL (from DATABASE_URL) |
| `ALLOWED_HOSTS` | localhost | `*` or specific domain |
| `SECURE_SSL_REDIRECT` | Off | On (optional) |
| `HSTS` | Off | 1 year |
| `CORS` | localhost | Specified origins |
| `EMAIL_BACKEND` | Console (print) | SMTP |

**Production security (auto-enabled when DEBUG=0):**
- HSTS (force HTTPS for 1 year)
- Secure cookies
- XSS protection
- Content-type sniffing prevention
- Clickjacking protection

---

## CI/CD Pipelines

### `.github/workflows/flutter-ci.yml`
Triggers on push/PR to Flutter code.
1. Set up Flutter 3.32.x
2. `flutter pub get`
3. `flutter analyze` (lint)
4. `dart format --set-exit-if-changed` (formatting)
5. `flutter test --coverage`
6. Build release APK (on main branch)
7. Build iOS (on main branch, macOS runner)

### `.github/workflows/backend-ci.yml`
Triggers on push/PR to backend code.
1. Set up Python 3.12 + PostgreSQL 16
2. Install dependencies
3. `ruff check` (Python linter)
4. `ruff format --check` (formatting)
5. Run Django migrations
6. `python manage.py test`
7. Security audit with `pip-audit`

---

## Docker & Deployment

### `Dockerfile` (Multi-stage build)
```
Stage 1 (base): Python 3.12 slim + system dependencies
Stage 2 (dependencies): Install pip packages
Stage 3 (production): Copy app + packages, collectstatic, set entrypoint
```

### `entrypoint.sh` (Startup script)
```bash
1. Run database migrations (python manage.py migrate)
2. Start Gunicorn on $PORT (Cloud Run/Render provide this)
```

### `docker-compose.yml` (Local development)
- PostgreSQL 16 database container
- Backend container linked to database
- Shared volume for media files

---

## Data Flow Diagrams

### Login Flow:
```
User → [Enter credentials] → Flutter AuthScreen
  → POST /api/login/ → Django validates password
  → Returns: {id, username, token}
  → Flutter saves token in EncryptedSharedPreferences
  → Navigate to HomeShell
```

### Alert Trigger Flow:
```
Sensor detects movement → PocketGuardService (Kotlin)
  → Checks: phone out of pocket? + movement strong? + not snoozed?
  → YES → Launch EmergencyActivity (over lock screen)
  → 10s countdown starts
  → Captures front camera photo immediately
  → User doesn't respond in 10s
  → Alarm sound plays (max volume)
  → SMS sent to emergency contact
  → POST /api/users/{id}/alerts/ → Backend saves alert
  → Backend sends email notification to guardian
  → Photo uploaded when app resumes
```

---

## Security Implementation

| Layer | Protection |
|-------|-----------|
| Token storage | AES-256 encrypted (platform keychain) |
| PIN storage | Same encrypted storage |
| API authentication | 64-char hex token in Authorization header |
| Token expiry | 30 days, auto-rotated on login |
| Rate limiting | 5 attempts / 5 min per IP |
| Password | Django's PBKDF2-SHA256 hashing |
| Transport | HTTPS (TLS via Render) |
| Code obfuscation | ProGuard/R8 in release builds |
| Input validation | Client-side + server-side |
| SQL injection | Django ORM (parameterized queries) |
| CORS | Restricted to allowed origins |
| Headers | HSTS, X-Frame-Options, CSP |

---

## Permissions Required (Android)

| Permission | Why |
|-----------|-----|
| `ACCESS_FINE_LOCATION` | Capture GPS for alert |
| `ACCESS_BACKGROUND_LOCATION` | Track during pocket mode |
| `CAMERA` | Intruder photo capture |
| `SEND_SMS` | Emergency SMS to contact |
| `CALL_PHONE` | Emergency call feature |
| `FOREGROUND_SERVICE` | Keep sensor monitoring alive |
| `WAKE_LOCK` | Prevent CPU sleep during monitoring |
| `POST_NOTIFICATIONS` | Show alerts/notifications |
| `USE_FULL_SCREEN_INTENT` | Show over lock screen |
| `SCHEDULE_EXACT_ALARM` | Daily auto-activation |

---

*End of documentation. Written by RishiPlaysCodes.*

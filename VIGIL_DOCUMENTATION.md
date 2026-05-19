# VIGIL - Complete Professional Documentation
## AI-Powered Personal Safety & Anti-Theft Application

**Version:** 2.0 (Production-Grade)  
**Author:** RishiPlaysCodes  
**Last Updated:** May 2026  
**Tech Stack:** Flutter + Kotlin + Django REST Framework

---

# TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [Complete Architecture](#2-complete-architecture)
3. [File-by-File Explanation](#3-file-by-file-explanation)
4. [Code Deep Dive](#4-code-deep-dive)
5. [Feature Implementation](#5-feature-implementation)
6. [Commands Documentation](#6-commands-documentation)
7. [Git Documentation](#7-git-documentation)
8. [Learning Roadmap](#8-learning-roadmap)
9. [Use Cases](#9-use-cases)
10. [Developer Guide](#10-developer-guide)
11. [Diagrams](#11-diagrams)
12. [Professional README](#12-professional-readme)

---

# 1. PROJECT OVERVIEW

## 1.1 What This App Does

Vigil ek AI-powered personal safety aur anti-theft mobile application hai jo real-time mein detect karta hai ki tumhara phone pocket/bag se suspiciously nikaala gaya hai ya nahi. Agar genuine theft/snatch detect hota hai, toh app automatically:

1. **Screen wake** karta hai (even when phone locked/sleeping)
2. **Face detection** se owner verify karta hai
3. **Multi-layer authentication** maangta hai (fingerprint/voice/PIN)
4. Agar verify nahi hua → **Full emergency mode** activate hota hai
5. **Loud alarm** + **SOS flashlight** + **Max brightness**
6. **Front camera photos** continuously capture karta hai (intruder evidence)
7. **Live location** with readable address emergency contacts ko share hota hai
8. **SMS + Email** with Google Maps tracking link family ko jaata hai

## 1.2 Main Objective

> **Phone chori hone se pehle hi detect karo, aur chori ke baad maximum evidence collect karke family ko alert karo.**

## 1.3 Real-World Use Case

- Student metro/bus mein travel kar raha hai
- Phone pocket mein hai, Vigil ka Pocket Mode ON hai
- Koi chor phone snatch karta hai
- App detect karta hai (jerk + rotation + proximity change + light change)
- Screen automatically ON hoti hai, face detect hota hai
- Chor ka face match nahi hota → countdown starts
- Countdown khatam → LOUD ALARM + camera captures + location share
- Parents ko SMS jaata hai: "VIGIL EMERGENCY - Rishi may be in danger! Maps link: ..."

## 1.4 Target Users

| User Type | Use Case |
|-----------|----------|
| College Students | Metro/bus commute pe phone safety |
| Parents | Bacchon ki safety monitoring |
| Women | Personal safety + SOS trigger |
| Business Travelers | Expensive phone protection |
| Anyone in crowded areas | Markets, concerts, stations |

## 1.5 Main Problem It Solves

| Problem | Vigil's Solution |
|---------|-----------------|
| Phone chori hone pe kuch nahi hota | Instant alarm + evidence capture |
| Police ko location nahi pata | Live tracking link with address |
| Chor ka face pata nahi | Front camera auto-capture |
| Normal apps bas "Find My Phone" hain (reactive) | Vigil is PROACTIVE — detects DURING theft |
| Motion alarms har movement pe bajte hain | AI sensor fusion — only triggers on REAL extraction |
| "I am safe" button insecure hai | Multi-layer biometric auth required |

## 1.6 Why Each Major Feature Exists

| Feature | Kyun Zaruri Hai |
|---------|----------------|
| AI Sensor Fusion Engine | Sirf motion se nahi — combined signals (jerk+rotation+proximity+light) se detect karo. Bus brake pe alarm nahi bajna chahiye. |
| Face Auto-Verification | Owner phone nikale toh alarm nahi bajana — silently cancel karo |
| Voice Password | Fingerprint agar kaam na kare (wet hands, gloves) toh backup |
| Emergency Protocol | Maximum deterrence — thief ko scare karo + evidence collect karo |
| Real-time Tracking | Family ko sirf coordinates nahi, readable address + Maps link chahiye |
| Guardian Character System | App ko emotional + engaging banao — user daily use kare |
| Safe Zones + Trusted Bluetooth | Ghar pe ya connected smartwatch ke paas = less sensitive |

---

# 2. COMPLETE ARCHITECTURE

## 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    VIGIL APP ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              FLUTTER UI LAYER (Dart)                  │    │
│  │  screens/ → widgets/ → theme/ → models/              │    │
│  └────────────────────────┬────────────────────────────┘    │
│                           │                                  │
│  ┌────────────────────────▼────────────────────────────┐    │
│  │           SERVICE LAYER (Dart Singletons)            │    │
│  │  AlertCoordinatorV2 (brain)                          │    │
│  │  ├── SensorManagerV2 → AISensorFusionEngine         │    │
│  │  ├── BehavioralContextAnalyzer                       │    │
│  │  ├── FaceVerificationService                         │    │
│  │  ├── MultiLayerAuthService                           │    │
│  │  ├── EmergencyProtocolService                        │    │
│  │  ├── RealtimeTrackingService                         │    │
│  │  ├── AlarmService                                    │    │
│  │  ├── CameraService                                   │    │
│  │  ├── LocationService                                 │    │
│  │  ├── NotificationService                             │    │
│  │  ├── ApiService                                      │    │
│  │  ├── GuardianCharacterService                        │    │
│  │  └── WakeIntentService                               │    │
│  └────────────────────────┬────────────────────────────┘    │
│                           │ Platform Channels                │
│  ┌────────────────────────▼────────────────────────────┐    │
│  │         NATIVE ANDROID LAYER (Kotlin)                │    │
│  │  MainActivity.kt (channel hub)                       │    │
│  │  ├── SensorService (proximity/light/accel/gyro)      │    │
│  │  ├── AlarmServiceHelper (wake/alarm/volume/vibrate)  │    │
│  │  ├── CameraHelper (Camera2 API capture)              │    │
│  │  ├── LocationHelper (FusedLocationProvider)          │    │
│  │  ├── NotificationHelper (channels/actions)           │    │
│  │  ├── VigilForegroundService (background survival)    │    │
│  │  ├── BootReceiver (restart after reboot)             │    │
│  │  └── NotificationActionReceiver                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTP REST API (JSON)
┌──────────────────────────────▼──────────────────────────────┐
│                   DJANGO BACKEND                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  vigil_backend/settings.py (config + security)        │   │
│  │  vigil_backend/urls.py (root router)                  │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  accounts/ → User model, JWT auth, profile, settings  │   │
│  │  alerts/   → Alert model, evidence, trail, notify     │   │
│  │  contacts/ → Emergency contact CRUD                   │   │
│  │  location/ → Location tracking, live sessions         │   │
│  │  dashboard/→ Analytics + AI performance stats         │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                    │
│  ┌───────────────────────▼──────────────────────────────┐   │
│  │  Database: SQLite (dev) / PostgreSQL (production)     │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                    │
│  ┌───────────────────────▼──────────────────────────────┐   │
│  │  External Services: MSG91/Twilio (SMS), SMTP (Email)  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 2.2 Frontend Architecture (Flutter + Kotlin)

Flutter app ka structure 5 layers mein divided hai:

### Layer 1: UI (Screens + Widgets + Theme)
```
lib/
├── screens/       → 17 screen files (splash, login, dashboard, pocket mode, etc.)
├── widgets/       → 4 reusable UI components (NeoGlassCard, NeonPulse, etc.)
├── theme/         → 2 theme files (VigilThemeV2 = active, VigilTheme = legacy)
├── models/        → 3 data models (User, Alert, Contact)
└── utils/         → NavigationService (global navigator key)
```

### Layer 2: Services (Business Logic)
```
lib/services/
├── alert_coordinator_v2.dart    → THE BRAIN — orchestrates entire safety flow
├── ai_sensor_fusion_engine.dart → Bayesian multi-sensor AI detection
├── sensor_manager_v2.dart       → Connects native sensors to AI engine
├── behavioral_context_analyzer.dart → Safe zones, trusted devices, activity
├── face_verification_service.dart   → ML Kit face matching
├── multi_layer_auth_service.dart    → 4-layer auth stack
├── emergency_protocol_service.dart  → Full emergency mode (photos/alarm/SOS)
├── realtime_tracking_service.dart   → Live GPS + address + Maps links
├── alarm_service.dart              → Wake screen + alarm sound + vibration
├── camera_service.dart             → Front camera intruder photo
├── location_service.dart           → GPS tracking with offline buffer
├── notification_service.dart       → Persistent + alert notifications
├── api_service.dart                → HTTP client for Django backend
├── guardian_character_service.dart  → AI companion characters
└── wake_intent_service.dart        → Native wake intent bridge
```

### Layer 3: Native Android (Kotlin)
```
android/app/src/main/kotlin/com/vigil/app/
├── MainActivity.kt              → Flutter host + ALL platform channel handlers
├── SensorService.kt             → Proximity/Light/Accelerometer/Gyroscope EventChannels
├── AlarmServiceHelper.kt        → MediaPlayer alarm + WakeLock + launchWakeActivity
├── CameraHelper.kt              → Camera2 API silent front-camera capture
├── LocationHelper.kt            → FusedLocationProviderClient
├── NotificationHelper.kt        → Channels + action buttons + broadcast
├── VigilForegroundService.kt    → Keeps sensors alive in background
├── BootReceiver.kt              → Restart service after device reboot
└── NotificationActionReceiver.kt → Handles "Pause 5 min" / "Stop" taps
```

### Layer 4: Android Config
```
android/app/src/main/
├── AndroidManifest.xml     → 20+ permissions declared
├── res/values/styles.xml   → Launch theme
├── res/drawable/launch_background.xml → Navy splash
android/app/
├── build.gradle            → compileSdk 34, minSdk 24, dependencies
android/
├── build.gradle            → Kotlin + Gradle plugins
├── settings.gradle         → Flutter plugin loader
├── gradle.properties       → JVM args + AndroidX
```

### Layer 5: Flutter Config
```
frontend/vigil_app/
├── pubspec.yaml            → All dependencies (30+ packages)
├── analysis_options.yaml   → Strict linting rules
├── assets/fonts/           → Poppins font placeholder
├── assets/images/          → Image assets
└── assets/sounds/          → Alarm sound assets
```

## 2.3 Backend Architecture (Django)

```
backend/
├── manage.py                    → Django CLI entry point
├── requirements.txt             → Python dependencies (14 packages)
├── .env.example                 → Environment variable template
├── vigil_backend/
│   ├── __init__.py
│   ├── settings.py              → MASTER CONFIG (security, JWT, CORS, SMS, email)
│   ├── urls.py                  → Root URL router
│   └── wsgi.py                  → WSGI deployment entry point
├── accounts/                    → User management app
│   ├── models.py                → VigilUser (extended AbstractUser with 30+ fields)
│   ├── serializers.py           → Register, Login, Profile, Settings serializers
│   ├── views.py                 → Register, Login, Profile, Settings endpoints
│   ├── urls.py                  → /api/auth/* routes
│   └── admin.py                 → Django admin panel config
├── alerts/                      → Alert management app
│   ├── models.py                → Alert + AlertEvidence + AlertLocationTrail
│   ├── serializers.py           → Full alert serializer with evidence + trail
│   ├── views.py                 → CRUD + acknowledge + face_verified + emergency + stats
│   ├── services.py              → SMS/Email notification with retry logic
│   ├── urls.py                  → /api/alerts/* routes
│   └── admin.py                 → Admin panel for alerts
├── contacts/                    → Emergency contacts app
│   ├── models.py                → EmergencyContact model
│   ├── serializers.py           → Contact CRUD serializer
│   ├── views.py                 → ViewSet for contacts
│   └── urls.py                  → /api/contacts/* routes
├── location/                    → Location tracking app
│   ├── models.py                → UserLocation + LiveTrackingSession
│   ├── serializers.py           → Location + Route + Session serializers
│   ├── views.py                 → Update + History + Route + Live tracking + PUBLIC endpoint
│   └── urls.py                  → /api/location/* routes
└── dashboard/                   → Analytics app
    ├── views.py                 → Dashboard with AI performance metrics
    └── urls.py                  → /api/dashboard/ route
```

## 2.4 Database Schema (Key Models)

### VigilUser (accounts)
```
id (UUID) | username | email | phone_number | profile_image |
pocket_mode_enabled | grace_period_seconds | high_security_mode |
ai_sensitivity | extraction_confidence_threshold |
face_enrolled | fingerprint_enabled | voice_password_enabled |
pin_enabled | required_auth_methods |
safe_zones (JSON) | trusted_devices (JSON) |
guardian_character | custom_ringtone |
total_alerts | false_alarms | days_protected |
schedule_enabled | schedule_start_time | schedule_end_time |
created_at | updated_at
```

### Alert (alerts)
```
id (UUID) | user (FK) | status | trigger_type |
threat_confidence | extraction_score | movement_context | ai_reason |
latitude | longitude | address | speed_at_trigger |
sensor_snapshot (JSON) | proximity_value | light_value |
accel_magnitude | gyro_magnitude | jerk_value |
face_verification_result | face_confidence | auth_method_used |
emergency_activated | photos_captured | photos_uploaded |
sms_sent | email_sent | sms_retry_count | contacts_notified (JSON) |
triggered_at | acknowledged_at | resolved_at
```

### AlertEvidence (alerts)
```
id (UUID) | alert (FK) | evidence_type | file | thumbnail |
metadata (JSON) | captured_at | uploaded_at
```

### UserLocation (location)
```
id (UUID) | user (FK) | latitude | longitude | accuracy |
altitude | speed | bearing | battery_level | is_moving |
address | speed_classification | tracking_mode | timestamp
```

### LiveTrackingSession (location)
```
id (UUID) | user (FK) | share_token (unique) | is_active |
started_at | ended_at | triggered_by | shared_with (JSON)
```

### EmergencyContact (contacts)
```
id | user (FK) | name | phone_number | email |
relationship | is_primary | notify_by_sms | notify_by_email |
notify_by_call | created_at | updated_at
```

## 2.5 API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/auth/register/` | Create account |
| POST | `/api/auth/login/` | Login → JWT tokens |
| POST | `/api/auth/token/refresh/` | Refresh access token |
| GET/PUT | `/api/auth/profile/` | Get/update profile |
| PATCH | `/api/auth/settings/` | Update settings |
| GET/POST | `/api/contacts/` | List/create contacts |
| DELETE | `/api/contacts/{id}/` | Delete contact |
| GET/POST | `/api/alerts/` | List/create alerts |
| POST | `/api/alerts/{id}/acknowledge/` | Owner verified (cancel) |
| POST | `/api/alerts/{id}/face_verified/` | Face auto-cancel |
| POST | `/api/alerts/{id}/activate_emergency/` | Escalate to emergency |
| POST | `/api/alerts/{id}/mark_false_alarm/` | Mark false alarm (AI learning) |
| POST | `/api/alerts/{id}/upload_evidence/` | Upload photo/video |
| POST | `/api/alerts/{id}/add_location_trail/` | Add trail point |
| GET | `/api/alerts/{id}/trail/` | Get location trail |
| GET | `/api/alerts/active/` | Active alerts |
| GET | `/api/alerts/history/` | Past alerts |
| GET | `/api/alerts/stats/` | AI performance stats |
| POST | `/api/location/update/` | Single location update |
| POST | `/api/location/bulk/` | Bulk location sync |
| GET | `/api/location/latest/` | Latest location |
| GET | `/api/location/history/` | Location history |
| GET | `/api/location/route/` | Route polyline |
| GET/POST/DELETE | `/api/location/tracking/` | Live session management |
| GET | `/api/location/track/{token}/` | **PUBLIC** — contacts view live tracking |
| GET | `/api/dashboard/` | Dashboard with AI stats |

## 2.6 Authentication Flow

```
User opens app → Splash → Login screen
    ↓
POST /api/auth/login/ {username, password}
    ↓
Backend validates → Returns {user, tokens: {access, refresh}}
    ↓
Flutter stores access_token in ApiService._accessToken (memory)
    ↓
All subsequent requests include: Authorization: Bearer {access_token}
    ↓
When access_token expires (12h) → ApiService auto-calls /token/refresh/
    ↓
If refresh also expired (14 days) → User redirected to login
```

## 2.7 AI Detection Flow (The Core Intelligence)

```
┌─────────────────────────────────────────────────────┐
│  NATIVE SENSORS (Kotlin SensorService.kt)            │
│  Proximity → EventChannel → Flutter                  │
│  Light     → EventChannel → Flutter                  │
│  Accelerometer → EventChannel → Flutter              │
│  Gyroscope → EventChannel → Flutter                  │
└───────────────────────┬─────────────────────────────┘
                        │ Raw sensor data streams
┌───────────────────────▼─────────────────────────────┐
│  SensorManagerV2 (Dart)                              │
│  Receives all 4 streams, computes orientation,       │
│  feeds to AI Fusion Engine + Context Analyzer        │
└───────────────────────┬─────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────┐
│  AISensorFusionEngine (runs at 10Hz)                 │
│                                                      │
│  Step 1: classifyMovement()                          │
│    → stationary / walking / running / vehicle        │
│    → Uses: zero-crossing frequency, std dev, peak    │
│                                                      │
│  Step 2: computePocketConfidence()                   │
│    → Bayesian weighted fusion of 5 signals:          │
│    proximity (30%) + light (25%) + motion (20%)      │
│    + gyro (15%) + orientation (10%)                  │
│    → Result: 0.0 to 1.0 pocket probability           │
│                                                      │
│  Step 3: computeExtractionScore()                    │
│    → Checks: jerk > 15 m/s³                          │
│    → Checks: rotation > 3 rad/s                      │
│    → Checks: proximity near→far transition           │
│    → Checks: light dark→bright transition            │
│    → Applies movement context modifiers:             │
│      walking: score × 0.4                            │
│      running: score × 0.3                            │
│      vehicle: score × 0.35                           │
│    → Checks pocket duration > 2s                     │
│    → Cooldown: no re-trigger within 5s               │
│                                                      │
│  Step 4: computeThreatConfidence()                   │
│    → Combines extraction + pocket evidence           │
│    → Only > 0.6 triggers alert                       │
│                                                      │
│  Step 5: updateStateMachine()                        │
│    → inPocket → normalUse → suspiciousExtraction     │
│    → Fires onExtractionDetected callback             │
└───────────────────────┬─────────────────────────────┘
                        │ onExtractionDetected()
┌───────────────────────▼─────────────────────────────┐
│  AlertCoordinatorV2                                   │
│  1. Captures intruder photo immediately              │
│  2. Calls native launchSafetyActivity('lock-screen') │
│  3. Native wakes screen + shows over lock screen     │
│  4. Flutter navigates to /lock-screen-safety         │
│  5. Face verification runs automatically (2s)        │
│  6. If owner face → silent cancel                    │
│  7. If not → grace countdown + multi-layer auth      │
│  8. If countdown expires → full emergency mode       │
└─────────────────────────────────────────────────────┘
```




---

# 3. FILE-BY-FILE EXPLANATION

## 3.1 Flutter Services (The Brain)

### `lib/services/alert_coordinator_v2.dart` — THE CENTRAL BRAIN
- **Purpose:** Orchestrates the ENTIRE safety flow from detection to emergency
- **Why it exists:** Without a central coordinator, sensors, alarm, camera, location would all work independently and never create a cohesive safety response
- **Key Logic:**
  - `enableProtection()` → starts sensors + location + foreground notification
  - `_onExtractionDetected()` → THE critical trigger point. Captures photo, wakes screen via native, starts face verification
  - `_startGraceCountdown()` → configurable timer before full alarm
  - `_triggerFullEmergency()` → activates alarm + notifies contacts
  - `onOwnerVerified()` → cancels everything when auth succeeds
- **Depends on:** SensorManagerV2, AlarmService, CameraService, LocationService, NotificationService, ApiService, WakeIntentService
- **Called by:** PocketModeScreenV2 (user activates), LockScreenSafetyV2 (auth result)

### `lib/services/ai_sensor_fusion_engine.dart` — AI DETECTION CORE
- **Purpose:** Takes raw sensor data and determines if phone is being stolen
- **Why it exists:** Simple threshold detection (old system) triggers on bus movement. This uses Bayesian probability + movement classification + jerk analysis
- **Key Logic:**
  - `feedAccelerometer/feedGyroscope/feedProximity/feedLight()` → receives sensor streams
  - `_runFusionAnalysis()` → runs at 10Hz (every 100ms). Calls classify → pocket confidence → extraction score → threat → state machine
  - `_classifyMovement()` → uses zero-crossing frequency + std deviation to classify stationary/walking/running/vehicle
  - `_computeExtractionScore()` → THE key function. Checks jerk (>15 m/s³), rotation (>3 rad/s), proximity transition, light transition. Then DISCOUNTS for walking/vehicle context
  - `_isSuspiciousRemoval()` → needs 2+ signals out of 4 to trigger
- **Depends on:** Nothing (pure computation)
- **Called by:** SensorManagerV2 (feeds data), AlertCoordinatorV2 (listens to events)

### `lib/services/sensor_manager_v2.dart` — SENSOR BRIDGE
- **Purpose:** Connects native Kotlin sensors to the AI engine
- **Why it exists:** Native Android sensors speak Kotlin via EventChannels. This Dart file receives those streams and feeds them to the AI engine in the right format
- **Key Logic:**
  - `startListening()` → subscribes to 4 native EventChannels (proximity, light, accelerometer, gyroscope)
  - Each stream listener: receives data → feeds to AISensorFusionEngine → also feeds to BehavioralContextAnalyzer
  - Computes orientation (pitch/roll) from accelerometer for fusion engine
- **Depends on:** AISensorFusionEngine, BehavioralContextAnalyzer, native Kotlin SensorService
- **Called by:** AlertCoordinatorV2

### `lib/services/face_verification_service.dart` — AUTO FACE CHECK
- **Purpose:** When extraction detected, automatically tries to recognize owner's face
- **Why it exists:** If the owner takes out their own phone, the alarm should NOT sound. Face recognition silently cancels it.
- **Key Logic:**
  - `enrollFace()` → captures 5 frames at different angles during setup
  - `startVerification()` → opens camera, captures frame, compares against enrolled embedding
  - Returns `FaceVerificationResult` with status: ownerRecognized / unknownFace / noFaceDetected / timeout
  - `shouldAutoCancel` → true if owner's face detected → AlertCoordinatorV2 silently cancels
- **Depends on:** Native platform channel `com.vigil.app/face_verification`
- **Called by:** LockScreenSafetyV2 screen

### `lib/services/multi_layer_auth_service.dart` — SECURE AUTH STACK
- **Purpose:** Replaces insecure "I am safe" button with proper biometric verification
- **Why it exists:** Anyone can tap a button. Only the OWNER can provide fingerprint + voice + PIN.
- **Key Logic:**
  - `startAuthentication()` → tries face first (auto), then waits for user input
  - `verifyFingerprint()` → calls native biometric prompt
  - `verifyVoicePassword()` → checks BOTH phrase content AND voiceprint match
  - `verifyPin()` → hash comparison
  - `requiredMethodCount` → user can require 1, 2, or 3 methods to pass
- **Depends on:** FaceVerificationService, native biometric/voice channels
- **Called by:** LockScreenSafetyV2, EmergencyActiveScreen

### `lib/services/emergency_protocol_service.dart` — NUCLEAR OPTION
- **Purpose:** When auth fails, activates maximum deterrence + evidence collection
- **Key Logic:**
  - `activate()` → simultaneously starts: continuous photo capture (every 3s), max brightness, max volume, SOS flashlight, high-freq location
  - `_startPhotoCaptureLoop()` → Timer.periodic captures + buffers evidence
  - `_startSOSFlashlight()` → Morse code SOS pattern via native flashlight
  - `_syncEvidenceToBackend()` → uploads photos to server
  - `deactivate()` → stops all, restores brightness, final sync

### `lib/services/realtime_tracking_service.dart` — LIVE GPS
- **Purpose:** Professional location tracking with addresses + maps links
- **Key Logic:**
  - 3 modes: normal (30s), highAccuracy (10s), emergency (3s)
  - `_resolveCurrentAddress()` → reverse geocoding via native
  - `generateLiveTrackingLink()` → Google Maps URL
  - `generateEmergencyMessage()` → SMS-ready format with address + speed + link
  - Speed classification: stationary/walking/running/cycling/driving
  - Route history with haversine distance calculation
  - Offline buffer with automatic sync

### `lib/services/api_service.dart` — HTTP CLIENT
- **Purpose:** All communication with Django backend
- **Key Logic:**
  - Singleton with `_accessToken` / `_refreshToken`
  - Auto token refresh on 401 responses
  - Methods for: login, register, CRUD contacts, create/acknowledge alerts, upload photos, bulk location sync, dashboard
  - All methods return null on failure (graceful degradation)

### `lib/services/guardian_character_service.dart` — AI COMPANION
- **Purpose:** Customizable AI safety character that guides users
- **5 Preset Guardians:**
  - NEXUS (Cyber Guardian) — cold logic, authoritative
  - ARIA (Holo Companion) — warm, friendly
  - PHANTOM (Phantom Shield) — stealth, mysterious
  - BLAZE (Neon Sentinel) — aggressive warrior
  - ORACLE (Crystal Oracle) — serene, predictive
- **Context-aware messages** for each state (idle, monitoring, extraction, emergency, safe)

### `lib/services/wake_intent_service.dart` — NATIVE BRIDGE
- **Purpose:** Receives wake intents from Kotlin when AI detects extraction while phone is locked
- **Flow:** Native sets showWhenLocked → sends route via MethodChannel → this service navigates Flutter to safety screen

## 3.2 Flutter Screens (The UI)

| Screen | Purpose | Key Feature |
|--------|---------|-------------|
| `splash_screen_v2.dart` | App launch animation | Orbiting rings + HoloText + particle stars |
| `onboarding_screen_v2.dart` | First-time feature walkthrough | 4 pages with NeonPulse icons |
| `login_screen_v2.dart` | User authentication | NeoGlassCard form + API login |
| `signup_screen_v2.dart` | Registration | 5-field form with validation |
| `dashboard_screen_v2.dart` | Home screen | Guardian avatar + AI stats + quick actions |
| `pocket_mode_screen_v2.dart` | Protection control | **ACTUALLY starts AI engine** + live debug display |
| `lock_screen_safety_v2.dart` | Emergency verification | 4-phase: face → auth countdown → emergency → confirmed safe |
| `emergency_active_screen.dart` | Active emergency UI | Photo counter + systems status + deactivate auth |
| `settings_screen_v2.dart` | All configuration | Auth enrollment + AI sensitivity + guardian |
| `guardian_selection_screen.dart` | Choose AI companion | 5 guardians with live preview |
| `face_enrollment_screen.dart` | Enroll face | Camera capture with instructions |
| `voice_password_screen.dart` | Set voice phrase | Recording UI with waveform animation |
| `emergency_contacts_screen_v2.dart` | Manage contacts | API-backed CRUD |
| `alert_history_screen_v2.dart` | Past alerts | Stats + confidence badges |

## 3.3 Native Kotlin (Android Platform)

| File | Purpose |
|------|---------|
| `MainActivity.kt` | Flutter host + ALL 10 platform channel registrations + wake intent handling |
| `SensorService.kt` | Registers proximity/light/accel/gyro SensorEventListeners, streams via EventChannel |
| `AlarmServiceHelper.kt` | WakeLock + MediaPlayer alarm + vibration + `launchWakeActivity()` for lock-screen safety |
| `CameraHelper.kt` | Camera2 API — opens front camera, captures JPEG, saves to private storage |
| `LocationHelper.kt` | FusedLocationProviderClient — configurable interval + distance filter |
| `NotificationHelper.kt` | Creates 4 notification channels + action buttons + broadcast receiver |
| `VigilForegroundService.kt` | START_STICKY service — keeps sensors alive when app backgrounded |
| `BootReceiver.kt` | Listens for BOOT_COMPLETED — restarts service if pocket mode was active |
| `NotificationActionReceiver.kt` | Handles "Pause 5 min" / "Stop" / "I Am Safe" button taps from notification |

## 3.4 Django Backend

| File | Purpose |
|------|---------|
| `settings.py` | Rate limiting (20/min anon, 120/min auth), JWT config (12h access), CORS, security headers, SMS/Email config, logging |
| `accounts/models.py` | VigilUser with 30+ fields: AI settings, auth methods, safe zones, trusted devices, stats |
| `alerts/models.py` | Alert + AlertEvidence + AlertLocationTrail — full AI context + evidence chain |
| `alerts/services.py` | Background thread SMS/Email with 3-retry logic + LiveTrackingSession creation |
| `alerts/views.py` | ViewSet with 12 action endpoints + rate limiting per endpoint |
| `location/models.py` | UserLocation (with speed/bearing/address) + LiveTrackingSession (shareable link) |
| `location/views.py` | Bulk sync + route polyline + PUBLIC tracking endpoint (no auth — for contacts) |
| `dashboard/views.py` | AI performance metrics (accuracy, false alarm rate, face auto-cancels) |

---

# 4. CODE DEEP DIVE — Key Functions Explained

## 4.1 The Most Important Function: `_computeExtractionScore()`

Located in: `lib/services/ai_sensor_fusion_engine.dart`

```dart
double _computeExtractionScore() {
  // ONLY runs if phone was in pocket
  if (_accelBuffer.length < 20 || !_isInPocket) return 0.0;
  
  double score = 0.0;

  // CHECK 1: Jerk (rate of acceleration change)
  // Jerk > 15 m/s³ = someone YANKED the phone out quickly
  // Normal movement has jerk < 5 m/s³
  final maxJerk = recentJerks.reduce(max);
  if (maxJerk > 15.0) score += 0.30;   // Strong signal
  
  // CHECK 2: Rotation spike (gyroscope)
  // Phone flips/rotates during a grab = > 3 rad/s
  // Normal pocket movement = < 0.5 rad/s
  final maxRotation = recentGyro.map((r) => r.magnitude).reduce(max);
  if (maxRotation > 3.0) score += 0.25;
  
  // CHECK 3: Proximity changed from NEAR to FAR
  // Near = in pocket (covered), Far = exposed (taken out)
  if (oldProximity < 1.0 && newProximity >= 1.0) score += 0.25;
  
  // CHECK 4: Light changed from DARK to BRIGHT
  // Dark pocket < 10 lux, Exposed > 50 lux
  if (oldLight < 10.0 && lightDelta > 40.0) score += 0.20;
  
  // === THE CRITICAL FALSE-POSITIVE PREVENTION ===
  // If user is walking, running, or in vehicle → HEAVILY discount
  if (_isWalking) score *= 0.4;    // Walking creates motion — discount 60%
  if (_isRunning) score *= 0.3;    // Running even more
  if (_isInVehicle) score *= 0.35; // Bus brakes cause spikes
  
  // Phone must have been in pocket for at least 2 seconds
  if (inPocketDuration < 2s) score *= 0.1;
  
  // Don't re-trigger within 5 seconds of last detection
  if (timeSinceLast < 5s) score *= 0.2;
  
  return score.clamp(0.0, 1.0);
}
```

**Yeh function kyun important hai:** Yeh decide karta hai ki alarm bajega ya nahi. Agar score > 0.6 hai (after all discounts), tabhi extraction maana jaata hai. Matlab:
- Bus mein phone hile → score shayad 0.15 (walking discount) → NO ALARM
- Chor ne jerk se phone nikala + rotate hua + light change + proximity change → score 0.85 → ALARM TRIGGERED

---

# 5. FEATURE IMPLEMENTATION

## 5.1 Pocket Mode (The Core Feature)

### Objective
Detect when phone is genuinely stolen from pocket vs normal use.

### User Flow
1. User opens app → goes to Pocket Mode screen
2. Taps "ACTIVATE PROTECTION"
3. Puts phone in pocket
4. App shows "AI MONITORING ACTIVE" with live sensor bars
5. If phone moved normally → nothing happens
6. If phone snatched → screen wakes → face check → auth → emergency

### Backend Flow
1. Alert created: `POST /api/alerts/` with AI confidence data
2. Contact notification: background thread sends SMS with tracking link
3. Evidence upload: `POST /api/alerts/{id}/upload_evidence/`
4. Location trail: continuous `POST /api/alerts/{id}/add_location_trail/`

### Files Involved
- `pocket_mode_screen_v2.dart` (UI)
- `alert_coordinator_v2.dart` (orchestration)
- `ai_sensor_fusion_engine.dart` (detection)
- `sensor_manager_v2.dart` (sensor bridge)
- `SensorService.kt` (native sensors)
- `VigilForegroundService.kt` (background survival)

### Edge Cases Handled
- Phone not in pocket long enough (< 2s) → don't trigger
- Walking/running/vehicle → heavy discount on extraction score
- Cooldown prevents rapid re-triggers (5s minimum gap)
- Offline → alerts queued for later sync

## 5.2 Multi-Layer Authentication

### Objective
Prevent intruder from disabling alarm by just tapping a button.

### User Flow
1. Extraction detected → safety screen appears
2. Face verification runs automatically (2 seconds)
3. If face matches owner → silent cancel (user doesn't even see countdown)
4. If face fails → countdown starts + auth options shown:
   - Fingerprint button
   - Voice button (say custom phrase like "VIGIL CHUP")
   - PIN text field
5. Must pass `requiredMethodCount` methods (configurable: 1, 2, or 3)
6. If countdown expires without auth → full emergency mode

### Security Design
- Face alone can cancel (it's automatic + fast)
- Fingerprint is biometric (unforgeable)
- Voice password = phrase text + voiceprint matching (intruder can't use even if they know the phrase — wrong voice)
- PIN is backup (weakest, but always available)

---

# 6. COMMANDS DOCUMENTATION

## 6.1 Backend Setup (Django)

```bash
# Navigate to backend
cd VIGIL/backend

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate
# Activate (Linux/Mac)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env
# Edit .env: set DJANGO_SECRET_KEY, DEBUG=True

# Run migrations (creates database tables)
python manage.py migrate

# Create admin superuser
python manage.py createsuperuser

# Start development server
python manage.py runserver 0.0.0.0:8000

# Access admin panel
# Open: http://localhost:8000/admin/
```

## 6.2 Frontend Setup (Flutter)

```bash
# Navigate to frontend
cd VIGIL/frontend/vigil_app

# Get all dependencies
flutter pub get

# Check Flutter setup
flutter doctor

# List connected devices
flutter devices

# Run on connected device
flutter run

# Run in debug mode with verbose logs
flutter run --verbose

# Run in release mode (faster, no debug)
flutter run --release

# Build APK for distribution
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Hot reload (while app running): press 'r'
# Hot restart: press 'R'
# Quit: press 'q'
# View logs: flutter logs
```

## 6.3 API URL Configuration

Edit `lib/services/api_service.dart`:
```dart
// For real Android phone (connected to same WiFi as PC):
static const String _baseUrl = 'http://192.168.1.X:8000/api';
// Replace X with your PC's IP (find via: ipconfig on Windows)

// For Android emulator:
static const String _baseUrl = 'http://10.0.2.2:8000/api';
```

## 6.4 Font Setup

Download Poppins from https://fonts.google.com/specimen/Poppins  
Place in `frontend/vigil_app/assets/fonts/`:
- Poppins-Regular.ttf
- Poppins-Medium.ttf
- Poppins-SemiBold.ttf
- Poppins-Bold.ttf
- Poppins-ExtraBold.ttf

---

# 7. GIT DOCUMENTATION

## 7.1 Repository Structure

```
Branch: vigil-full-project (all V2 code)
Branch: main (original/empty)
```

## 7.2 Key Commands

```bash
# Clone
git clone https://github.com/RishiPlaysCodes/VIGIL.git
cd VIGIL

# Switch to full project branch
git checkout vigil-full-project

# Check status
git status

# See commit history
git log --oneline -20

# Create new feature branch
git checkout -b feature/new-feature-name

# Stage + commit
git add -A
git commit -m "feat: description of what was added"

# Push
git push origin feature/new-feature-name

# Pull latest changes
git pull origin vigil-full-project
```

## 7.3 Commit Message Convention

```
feat: new feature added
fix: bug fix
refactor: code restructure without behavior change
docs: documentation only
style: UI/formatting changes
perf: performance improvement
```

---

# 8. LEARNING ROADMAP

## 8.1 To Understand This Project, Study In This Order:

| # | Topic | Why Needed | Where Used | Study Time |
|---|-------|-----------|-----------|-----------|
| 1 | Dart Language | Flutter is built on Dart | All .dart files | 2 weeks |
| 2 | Flutter Basics | UI framework | screens/, widgets/ | 3 weeks |
| 3 | Flutter State Management | How data flows in UI | setState, Singletons | 1 week |
| 4 | Platform Channels | Flutter ↔ Kotlin bridge | MethodChannel, EventChannel | 1 week |
| 5 | Kotlin Basics | Android native code | android/kotlin/ files | 2 weeks |
| 6 | Android Sensors | Proximity, light, accel, gyro | SensorService.kt | 1 week |
| 7 | Android Services | Background execution | VigilForegroundService.kt | 1 week |
| 8 | Camera2 API | Photo capture | CameraHelper.kt | 1 week |
| 9 | Python + Django | Backend server | backend/ | 3 weeks |
| 10 | Django REST Framework | API creation | serializers, views | 2 weeks |
| 11 | JWT Authentication | Token-based auth | SimpleJWT | 3 days |
| 12 | Signal Processing | Sensor data analysis | AI fusion engine | 2 weeks |
| 13 | Bayesian Probability | AI confidence scoring | computePocketConfidence() | 1 week |
| 14 | Git + GitHub | Version control | All code | 1 week |

---

# 9. USE CASES

## Use Case 1: Student in Metro
1. Student enables Pocket Mode before boarding metro
2. Phone goes in front pocket
3. AI recognizes "in pocket" state (proximity near + light dark + low motion)
4. Metro moves, student stands → AI classifies as "vehicle" → no alarm
5. Thief reaches into pocket, snatches phone with quick jerk
6. AI detects: jerk > 15 + rotation > 3 + proximity change + light change
7. Movement context = "suspicious" (not walking/vehicle pattern)
8. Extraction score = 0.82 (above 0.6 threshold)
9. Screen wakes over lock screen
10. Front camera activates → unknown face detected
11. Countdown: 3... 2... 1...
12. FULL ALARM: loud siren + max brightness + SOS flash
13. SMS sent to parents: "VIGIL EMERGENCY - Rishi may be in danger! Live Track: https://..."
14. Continuous photos of thief's face uploaded to server

## Use Case 2: Owner Takes Out Phone Normally
1. Pocket Mode active, phone in pocket
2. Owner reaches in pocket, takes phone out normally
3. AI detects: light change + proximity change
4. BUT: jerk is low (< 5), no sudden rotation, movement pattern = "normal use"
5. Extraction score = 0.15 (well below 0.6 threshold)
6. NO alarm triggered
7. Status changes to "Phone in hand — monitoring"

---

# 10. DEVELOPER GUIDE

## 10.1 How to Add a New Screen

1. Create file: `lib/screens/my_new_screen.dart`
2. Import theme: `import '../theme/vigil_theme_v2.dart';`
3. Use `NeoGlassCard` widgets for premium look
4. Register route in `lib/main.dart` → routes map
5. Navigate: `Navigator.pushNamed(context, '/my-new-route')`

## 10.2 How to Add a New API Endpoint

1. Backend: Add view in appropriate app's `views.py`
2. Backend: Add URL in app's `urls.py`
3. Backend: Add serializer if needed
4. Frontend: Add method in `lib/services/api_service.dart`
5. Call from screen or service

## 10.3 How to Add a New Sensor

1. Kotlin: Add sensor in `SensorService.kt` (register listener + EventChannel stream handler)
2. Kotlin: Register EventChannel in `MainActivity.kt`
3. Dart: Subscribe in `sensor_manager_v2.dart`
4. Dart: Feed to `ai_sensor_fusion_engine.dart`

---

# 11. DIAGRAMS

## 11.1 Complete Request Flow

```
User taps "Activate Protection"
         │
         ▼
PocketModeScreenV2._toggleProtection()
         │
         ▼
AlertCoordinatorV2.enableProtection()
         │
         ├──→ SensorManagerV2.startListening()
         │         │
         │         ├──→ Native: SensorService starts listeners
         │         └──→ AISensorFusionEngine.start()
         │
         ├──→ LocationService.startTracking()
         │         └──→ Native: LocationHelper.startUpdates()
         │
         └──→ NotificationService.showPocketModeNotification()
                   └──→ Native: NotificationHelper.showNotification()
```

## 11.2 Extraction → Emergency Flow

```
AISensorFusionEngine._runFusionAnalysis()   [runs every 100ms]
         │
         │ extraction score > 0.6 && isInPocket == true
         ▼
onExtractionDetected() callback fires
         │
         ▼
AlertCoordinatorV2._onExtractionDetected()
         │
         ├──→ CameraService.captureIntruderPhoto()  [immediate evidence]
         │
         ├──→ Native: AlarmServiceHelper.launchWakeActivity('lock-screen')
         │         │
         │         ├──→ PowerManager.FULL_WAKE_LOCK  [screen turns ON]
         │         ├──→ Intent: FLAG_ACTIVITY_NEW_TASK + EXTRA_LAUNCH_ROUTE
         │         └──→ MainActivity opens with showWhenLocked=true
         │
         ├──→ WakeIntentService receives 'onWakeIntent' from native
         │         └──→ NavigationService.pushNamed('/lock-screen-safety')
         │
         ▼
LockScreenSafetyV2 appears OVER the lock screen
         │
         ├──→ Phase 1: FaceVerificationService.startVerification() [2s]
         │         ├──→ Owner face detected → onOwnerVerified() → SILENT CANCEL
         │         └──→ Unknown/no face → proceed to Phase 2
         │
         ├──→ Phase 2: Grace countdown (3/5/10/20 seconds)
         │         ├──→ User taps Fingerprint → MultiLayerAuthService.verifyFingerprint()
         │         ├──→ User taps Voice → verifyVoicePassword()
         │         ├──→ User enters PIN → verifyPin()
         │         ├──→ Auth succeeds → onOwnerVerified() → CANCEL
         │         └──→ Countdown expires → Phase 3
         │
         └──→ Phase 3: Navigator.pushReplacementNamed('/emergency-active')
                   │
                   ├──→ EmergencyProtocolService.activate()
                   │         ├──→ Photo capture every 3s
                   │         ├──→ Max brightness + max volume
                   │         ├──→ SOS flashlight blink
                   │         └──→ Evidence sync to backend
                   │
                   ├──→ RealtimeTrackingService.activateEmergencyMode()
                   │         └──→ GPS every 3s + reverse geocoding
                   │
                   ├──→ AlarmService.triggerFullAlarm()
                   │         └──→ Native: MediaPlayer + vibration
                   │
                   └──→ ApiService.createAlert() → Backend → SMS/Email to contacts
```

---

# 12. PROFESSIONAL README

## VIGIL — AI-Powered Personal Safety

> Detects phone theft in real-time using multi-sensor AI fusion. Captures evidence, alerts family, tracks location — all before you even realize your phone is gone.

### Features
- AI Sensor Fusion (accel + gyro + proximity + light + orientation)
- Bayesian extraction detection with movement classification
- Auto face verification (silent cancel for owner)
- Multi-layer auth: Face + Fingerprint + Voice Password + PIN
- Full emergency protocol: alarm + SOS flash + photos + tracking
- Live location sharing with clickable Google Maps links
- Customizable AI Guardian companions (5 characters)
- Premium glassmorphism dark UI with neon glow effects
- Offline-resilient with automatic evidence sync
- Background persistence via foreground service + boot receiver

### Tech Stack
| Layer | Technology |
|-------|-----------|
| Mobile UI | Flutter 3.2+ (Dart) |
| Native Android | Kotlin (Camera2, FusedLocation, Sensors) |
| Backend API | Django 4.2 + Django REST Framework |
| Auth | JWT (SimpleJWT) with token rotation |
| Database | SQLite (dev) / PostgreSQL (prod) |
| SMS | MSG91 / Twilio |
| Email | SMTP (Gmail/any provider) |

### Installation
```bash
git clone https://github.com/RishiPlaysCodes/VIGIL.git
cd VIGIL && git checkout vigil-full-project

# Backend
cd backend && python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate && python manage.py runserver 0.0.0.0:8000

# Frontend (new terminal)
cd frontend/vigil_app && flutter pub get && flutter run
```

### Disclaimer
This application is designed for **personal safety and anti-theft protection only**. It should be used responsibly and in compliance with local laws regarding surveillance, recording, and location tracking. Always obtain consent where legally required.

---

*END OF DOCUMENTATION*

*Total project size: 100+ files, 15,000+ lines of production-grade code across Flutter (Dart), Kotlin, and Python (Django).*

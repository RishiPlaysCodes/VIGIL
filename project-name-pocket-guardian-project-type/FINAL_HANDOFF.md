# Pocket Guardian — Final Handoff

## Completed in code

- polished multi-screen Flutter UI
- auth, token-protected APIs, contacts, alerts, dashboard
- Pocket Mode, countdown, alarm flow, biometric verification
- battery/security profiles
- location sharing modes
- daily scheduling preferences and reboot-aware alarm receiver setup
- background execution support hooks
- live location sync
- intruder photo capture + upload
- guardian dashboard with location links and photo previews
- email notifications with photo attachments
- provider-ready SMS interface
- environment-based backend settings

## External setup still required

These are not missing code tasks; they need credentials, hardware, or store-specific setup:

1. Real SMTP account values in backend environment variables
2. Real SMS provider implementation and credentials
3. Firebase project setup and device registration for push notifications
4. Physical Android device testing for:
   - alarm timing
   - reboot behavior
   - OEM battery restrictions
   - custom ringtone playback
   - camera and GPS permissions
5. Final Android launcher icon / Play Store signing assets

## Recommended production checks

- Test on at least 2 Android brands
- Verify alarms after reboot and battery saver mode
- Verify guardian email receives attached photo
- Verify location updates under each user-selected sharing mode
- Verify false positives during walking, sitting, and public transport

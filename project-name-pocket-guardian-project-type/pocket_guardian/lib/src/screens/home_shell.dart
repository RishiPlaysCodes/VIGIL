import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart' as bg;
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'contacts_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.userId,
    required this.username,
    required this.token,
  });

  final int userId;
  final String username;
  final String token;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  final _api = ApiService();
  final _auth = LocalAuthentication();
  final _audioPlayer = AudioPlayer();
  static const _nativeChannel = MethodChannel('pocket_guardian/native');
  final _contactNameController = TextEditingController(text: 'Maa');
  final _contactPhoneController = TextEditingController(text: '+91 98765 43210');
  final _contactEmailController = TextEditingController(text: 'maa@example.com');
  final _pinController = TextEditingController();
  final List<AlertRecord> _history = [];

  SharedPreferences? _preferences;
  Timer? _countdownTimer;
  Timer? _autoActivationTimer;
  Timer? _contactSyncDebounce;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<UserAccelerometerEvent>? _motionSubscription;
  DateTime? _lastStrongMovementAt;

  int _selectedIndex = 0;
  bool _pocketModeEnabled = false;
  bool _isCountingDown = false;
  bool _alarmActive = false;
  bool _screenWakeDetected = false;
  int _secondsRemaining = 10;
  int? _autoActivationMinutes;
  String _statusMessage = 'Pocket Mode is off';
  String _lastReason = '';
  String _lastKnownLocation = 'Location not captured yet';
  String _intruderPhotoStatus = 'No photo captured yet';
  String? _intruderPhotoPath;
  SecurityLevel _securityLevel = SecurityLevel.balanced;
  LocationMode _locationMode = LocationMode.alertOnly;
  VerificationMode _verificationMode = VerificationMode.pinOnly;
  String _customRingtoneLabel = 'Default alarm';
  String _lockScreenImageLabel = 'Default shield';
  SafetyAvatar _safetyAvatar = SafetyAvatar.guardian;
  int _removalGraceSeconds = 3;
  DailySchedule _dailySchedule = const DailySchedule(
    startHour: 8,
    startMinute: 0,
    endHour: 9,
    endMinute: 0,
    enabled: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _api.token = widget.token;
    _loadSavedData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _autoActivationTimer?.cancel();
    _contactSyncDebounce?.cancel();
    _motionSubscription?.cancel();
    _locationSubscription?.cancel();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _consumeScheduledPocketModeRequest();
      _consumePendingIntruderCapture();
    }
  }

  Future<void> _loadSavedData() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('api_base_url', _api.baseUrl);
    final historyJson = preferences.getStringList('alert_history') ?? [];
    if (!mounted) {
      return;
    }
    setState(() {
      _preferences = preferences;
      _contactNameController.text = preferences.getString('contact_name') ?? 'Maa';
      _contactPhoneController.text =
          preferences.getString('contact_phone') ?? '+91 98765 43210';
      _contactEmailController.text =
          preferences.getString('contact_email') ?? 'maa@example.com';
      _securityLevel = SecurityLevel.values[
          preferences.getInt('security_level') ?? SecurityLevel.balanced.index];
      _locationMode = LocationMode.values[
          preferences.getInt('location_mode') ?? LocationMode.alertOnly.index];
      _verificationMode = VerificationMode.values[
          preferences.getInt('verification_mode') ?? VerificationMode.pinOnly.index];
      _customRingtoneLabel =
          preferences.getString('custom_ringtone_label') ?? 'Default alarm';
      _lockScreenImageLabel =
          preferences.getString('lock_screen_image_label') ?? 'Default shield';
      _safetyAvatar = SafetyAvatar.values[
          preferences.getInt('safety_avatar') ?? SafetyAvatar.guardian.index];
      _removalGraceSeconds = preferences.getInt('removal_grace_seconds') ?? 3;
      _dailySchedule = DailySchedule(
        startHour: preferences.getInt('daily_schedule_start_hour') ??
            preferences.getInt('daily_schedule_hour') ??
            8,
        startMinute: preferences.getInt('daily_schedule_start_minute') ??
            preferences.getInt('daily_schedule_minute') ??
            0,
        endHour: preferences.getInt('daily_schedule_end_hour') ?? 9,
        endMinute: preferences.getInt('daily_schedule_end_minute') ?? 0,
        enabled: preferences.getBool('daily_schedule_enabled') ?? false,
      );
      _history
        ..clear()
        ..addAll(
          historyJson.map(
            (item) => AlertRecord.fromJson(jsonDecode(item) as Map<String, dynamic>),
          ),
        );
    });
    await _consumeScheduledPocketModeRequest(preferences: preferences);
    await _consumePendingIntruderCapture(preferences: preferences);
  }

  Future<void> _consumeScheduledPocketModeRequest({
    SharedPreferences? preferences,
  }) async {
    final store = preferences ?? await SharedPreferences.getInstance();
    final scheduledRequest =
        store.getBool('scheduled_pocket_mode_requested') ?? false;
    final scheduledOffRequest =
        store.getBool('scheduled_pocket_mode_off_requested') ?? false;
    if (scheduledRequest) {
      await store.setBool('scheduled_pocket_mode_requested', false);
      togglePocketMode(true);
      if (mounted) {
        setState(() {
          _statusMessage = 'Pocket Mode auto-activated by daily schedule.';
        });
      }
    }
    if (scheduledOffRequest) {
      await store.setBool('scheduled_pocket_mode_off_requested', false);
      togglePocketMode(false);
      if (mounted) {
        setState(() {
          _statusMessage = 'Pocket Mode auto-disabled after travel window.';
        });
      }
    }
  }

  Future<void> _consumePendingIntruderCapture({
    SharedPreferences? preferences,
  }) async {
    final store = preferences ?? await SharedPreferences.getInstance();
    final pending = store.getBool('pending_intruder_capture') ?? false;
    if (!pending) {
      return;
    }
    await store.setBool('pending_intruder_capture', false);
    final nativePhotoPath = store.getString('native_intruder_photo_path');
    if (nativePhotoPath != null) {
      _intruderPhotoPath = nativePhotoPath;
      if (mounted) {
        setState(() => _intruderPhotoStatus =
            'Captured: ${nativePhotoPath.split('\\').last}');
      }
      final nativeAlertId = store.getInt('native_alert_id');
      if (nativeAlertId != null) {
        await _api.uploadAlertPhoto(
          userId: widget.userId,
          alertId: nativeAlertId,
          filePath: nativePhotoPath,
        );
        await store.remove('native_alert_id');
      }
      await store.remove('native_intruder_photo_path');
      return;
    }
    final photoStatus = await _captureIntruderPhoto();
    if (mounted) {
      setState(() => _intruderPhotoStatus = photoStatus);
    }
  }

  Future<void> saveContact() async {
    await _preferences?.setString('contact_name', _contactNameController.text.trim());
    await _preferences?.setString('contact_phone', _contactPhoneController.text.trim());
    await _preferences?.setString('contact_email', _contactEmailController.text.trim());
    _contactSyncDebounce?.cancel();
    _contactSyncDebounce = Timer(const Duration(milliseconds: 700), () async {
      await _syncContactToBackend();
    });
  }

  Future<void> _syncContactToBackend() async {
    try {
      await _api.syncContact(
        userId: widget.userId,
        name: _contactNameController.text.trim(),
        phone: _contactPhoneController.text.trim(),
        email: _contactEmailController.text.trim(),
      );
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    final encoded = _history.map((item) => jsonEncode(item.toJson())).toList();
    await _preferences?.setStringList('alert_history', encoded);
  }

  void togglePocketMode(bool value) {
    setState(() {
      _pocketModeEnabled = value;
      _screenWakeDetected = false;
      _isCountingDown = false;
      _alarmActive = false;
      _secondsRemaining = 10;
      _statusMessage = value
          ? 'Pocket Mode armed. Monitoring for suspicious activity.'
          : 'Pocket Mode is off';
    });
    _countdownTimer?.cancel();
    if (value) {
      _autoActivationTimer?.cancel();
      _autoActivationMinutes = null;
      _enableBackgroundMode();
      _startMotionMonitoring();
      _startLocationSharingIfNeeded();
      unawaited(_requestLocationPermission());
      unawaited(_captureAndSyncCurrentLocation());
      _nativeChannel.invokeMethod('startPocketGuardService');
      _nativeChannel.invokeMethod('requestEmergencyPermissions');
    } else {
      _disableBackgroundMode();
      _stopMotionMonitoring();
      _nativeChannel.invokeMethod('stopPocketGuardService');
    }
  }

  Future<void> _enableBackgroundMode() async {
    const config = bg.FlutterBackgroundAndroidConfig(
      notificationTitle: 'Pocket Guardian active',
      notificationText: 'Pocket Mode is monitoring your device.',
      notificationImportance: bg.AndroidNotificationImportance.normal,
      notificationIcon: bg.AndroidResource(
        name: 'ic_launcher',
        defType: 'mipmap',
      ),
    );
    final initialized = await bg.FlutterBackground.initialize(
      androidConfig: config,
    );
    if (initialized) {
      await bg.FlutterBackground.enableBackgroundExecution();
    }
  }

  Future<void> _disableBackgroundMode() async {
    if (bg.FlutterBackground.isBackgroundExecutionEnabled) {
      await bg.FlutterBackground.disableBackgroundExecution();
    }
  }

  void registerMovement({required bool strongMovement}) {
    if (!_pocketModeEnabled || _alarmActive || _isCountingDown) {
      return;
    }
    if (!strongMovement && !_screenWakeDetected) {
      setState(() => _statusMessage = 'Small movement ignored.');
      return;
    }
    final reason = strongMovement && _screenWakeDetected
        ? 'Phone moved and screen woke up'
        : strongMovement
            ? 'Continuous movement detected'
            : 'Screen wake detected';
    _startCountdown(reason);
  }

  void detectScreenWake() {
    if (!_pocketModeEnabled || _alarmActive) {
      return;
    }
    setState(() {
      _screenWakeDetected = true;
      _statusMessage = 'Screen wake detected. Waiting for movement signal.';
    });
  }

  void _startCountdown(String reason) {
    _countdownTimer?.cancel();
    setState(() {
      _lastReason = reason;
      _secondsRemaining = 10;
      _isCountingDown = true;
      _statusMessage = '$reason. Confirm within 10 seconds.';
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _triggerAlarm();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> cancelWithPin() async {
    if (_verificationMode == VerificationMode.biometricAndPin) {
      final authenticated = await _tryBiometricVerification();
      if (!authenticated) {
        await _triggerAlarm();
        return;
      }
    }
    if (_pinController.text.trim() != '1234') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong PIN. Use 1234 in demo mode.')),
        );
      }
      return;
    }
    _countdownTimer?.cancel();
    final record = AlertRecord(
      time: DateTime.now(),
      reason: _lastReason,
      status: 'Cancelled',
    );
    setState(() {
      _isCountingDown = false;
      _screenWakeDetected = false;
      _secondsRemaining = 10;
      _statusMessage = 'Verified. Alert cancelled safely.';
      _history.insert(0, record);
    });
    await _saveHistory();
    await _syncAlert('cancelled');
    _pinController.clear();
  }

  Future<void> _triggerAlarm() async {
    setState(() {
      _isCountingDown = false;
      _alarmActive = true;
      _statusMessage = 'Alarm active — capturing evidence.';
      _history.insert(
        0,
        AlertRecord(
          time: DateTime.now(),
          reason: _lastReason,
          status: 'Alert sent',
        ),
      );
    });
    await _saveHistory();
    unawaited(_playAlarmFeedback());
    final location = await _captureCurrentLocation();
    final photoStatus = await _captureIntruderPhoto();
    if (!mounted) {
      return;
    }
    setState(() {
      _lastKnownLocation = location;
      _intruderPhotoStatus = photoStatus;
      _statusMessage = 'Alarm active — emergency alert sent.';
    });
    final alertId = await _syncAlert('triggered');
    await _sendEmergencySms();
    if (_intruderPhotoPath != null) {
      await _api.uploadAlertPhoto(
        userId: widget.userId,
        alertId: alertId,
        filePath: _intruderPhotoPath!,
      );
    }
  }

  void resetAlarm() {
    _nativeChannel.invokeMethod('stopAlarm');
    setState(() {
      _alarmActive = false;
      _screenWakeDetected = false;
      _secondsRemaining = 10;
      _statusMessage =
          _pocketModeEnabled ? 'Pocket Mode armed again.' : 'Pocket Mode is off';
    });
  }

  void scheduleAutoActivation(int minutes) {
    _autoActivationTimer?.cancel();
    setState(() {
      _autoActivationMinutes = minutes;
      _statusMessage = 'Pocket Mode will auto-activate in $minutes minute${minutes == 1 ? '' : 's'}.';
    });
    _autoActivationTimer = Timer(Duration(minutes: minutes), () {
      if (!mounted) {
        return;
      }
      togglePocketMode(true);
      setState(() => _statusMessage = 'Pocket Mode auto-activated for travel.');
    });
  }

  void cancelAutoActivation() {
    _autoActivationTimer?.cancel();
    setState(() {
      _autoActivationMinutes = null;
      _statusMessage =
          _pocketModeEnabled ? 'Pocket Mode armed.' : 'Pocket Mode is off';
    });
  }

  Future<int> _syncAlert(String status) async {
    final response = await _api.syncAlert(
      userId: widget.userId,
      reason: _lastReason,
      status: status,
      occurredAt: DateTime.now(),
      latitude: _extractCoordinate(0),
      longitude: _extractCoordinate(1),
      photoPath: _intruderPhotoStatus,
    );
    return response['id'] as int;
  }

  Future<void> _playAlarmFeedback() async {
    await HapticFeedback.heavyImpact();
    if (_customRingtoneLabel != 'Default alarm') {
      final storedPath = _preferences?.getString('custom_ringtone_path');
      if (storedPath != null) {
        await _audioPlayer.setSourceDeviceFile(storedPath);
        await _audioPlayer.resume();
        return;
      }
    }
    await _nativeChannel.invokeMethod('playAlarm');
  }

  Future<void> _sendEmergencySms() async {
    final phone = _contactPhoneController.text.trim();
    final message =
        'Pocket Guardian alert: suspicious phone movement/access detected. '
        'Location: $_lastKnownLocation';
    await _nativeChannel.invokeMethod(
      'sendSms',
      {'phone': phone, 'message': message},
    );
  }

  Future<void> _startLocationSharingIfNeeded() async {
    if (_locationMode == LocationMode.alertOnly) {
      return;
    }
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    await _locationSubscription?.cancel();
    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen((position) {
      setState(() {
        _lastKnownLocation =
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });
      _preferences?.setString('last_known_location', _lastKnownLocation);
      _api.syncLocation(
        userId: widget.userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
  }

  Future<void> _scheduleDailyAutoEnableIfNeeded() async {
    if (!_dailySchedule.enabled) {
      return;
    }
    final now = DateTime.now();
    var first = DateTime(
      now.year,
      now.month,
      now.day,
      _dailySchedule.startHour,
      _dailySchedule.startMinute,
    );
    if (first.isBefore(now)) {
      first = first.add(const Duration(days: 1));
    }
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      8001,
      _scheduledPocketModeCallback,
      startAt: first,
      exact: true,
      wakeup: true,
    );
    var end = DateTime(
      now.year,
      now.month,
      now.day,
      _dailySchedule.endHour,
      _dailySchedule.endMinute,
    );
    if (!end.isAfter(first)) {
      end = end.add(const Duration(days: 1));
    }
    if (end.isBefore(now)) {
      end = end.add(const Duration(days: 1));
    }
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      8002,
      _scheduledPocketModeOffCallback,
      startAt: end,
      exact: true,
      wakeup: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _scheduledPocketModeCallback() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('scheduled_pocket_mode_requested', true);
  }

  @pragma('vm:entry-point')
  static Future<void> _scheduledPocketModeOffCallback() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('scheduled_pocket_mode_off_requested', true);
  }
  double? _extractCoordinate(int index) {
    final parts = _lastKnownLocation.split(',');
    return parts.length == 2 ? double.tryParse(parts[index].trim()) : null;
  }

  void _startMotionMonitoring() {
    _motionSubscription?.cancel();
    _motionSubscription = userAccelerometerEventStream().listen((event) {
      final magnitude = event.x * event.x + event.y * event.y + event.z * event.z;
      final threshold = switch (_securityLevel) {
        SecurityLevel.saver => 16,
        SecurityLevel.balanced => 10,
        SecurityLevel.highSecurity => 6,
      };
      if (magnitude < threshold) {
        return;
      }
      final now = DateTime.now();
      final previous = _lastStrongMovementAt;
      _lastStrongMovementAt = now;
      if (previous == null || now.difference(previous) > const Duration(seconds: 2)) {
        return;
      }
      registerMovement(strongMovement: true);
    });
  }

  void _stopMotionMonitoring() {
    _motionSubscription?.cancel();
    _motionSubscription = null;
    _lastStrongMovementAt = null;
  }

  Future<bool> _tryBiometricVerification() async {
    try {
      final canAuthenticate =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuthenticate) {
        return false;
      }
      return await _auth.authenticate(
        localizedReason: 'Verify that you are the owner of this phone',
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> updateSecurityLevel(SecurityLevel value) async {
    setState(() => _securityLevel = value);
    await _preferences?.setInt('security_level', value.index);
  }

  Future<void> updateLocationMode(LocationMode value) async {
    setState(() => _locationMode = value);
    await _preferences?.setInt('location_mode', value.index);
    if (!_pocketModeEnabled) {
      return;
    }
    if (value == LocationMode.alertOnly) {
      await _locationSubscription?.cancel();
      _locationSubscription = null;
    } else {
      await _startLocationSharingIfNeeded();
      await _captureAndSyncCurrentLocation();
    }
  }

  Future<void> updateVerificationMode(VerificationMode value) async {
    setState(() => _verificationMode = value);
    await _preferences?.setInt('verification_mode', value.index);
  }

  Future<void> updateCustomRingtoneLabel(String value) async {
    final parts = value.split('|');
    setState(() => _customRingtoneLabel = parts.first);
    await _preferences?.setString('custom_ringtone_label', parts.first);
    if (parts.length > 1) {
      await _preferences?.setString('custom_ringtone_path', parts.last);
    }
  }

  Future<void> previewRingtone() async {
    await _audioPlayer.stop();
    await _playAlarmFeedback();
  }

  Future<void> resetRingtone() async {
    await _audioPlayer.stop();
    setState(() => _customRingtoneLabel = 'Default alarm');
    await _preferences?.remove('custom_ringtone_path');
    await _preferences?.setString('custom_ringtone_label', 'Default alarm');
  }

  Future<void> updateLockScreenImage(String value) async {
    final parts = value.split('|');
    setState(() => _lockScreenImageLabel = parts.first);
    await _preferences?.setString('lock_screen_image_label', parts.first);
    if (parts.length > 1) {
      await _preferences?.setString('lock_screen_image_path', parts.last);
    }
  }

  Future<void> updateSafetyAvatar(SafetyAvatar value) async {
    setState(() => _safetyAvatar = value);
    await _preferences?.setInt('safety_avatar', value.index);
  }

  Future<void> updateRemovalGraceSeconds(int value) async {
    setState(() => _removalGraceSeconds = value);
    await _preferences?.setInt('removal_grace_seconds', value);
  }

  Future<void> updateDailySchedule(DailySchedule value) async {
    setState(() => _dailySchedule = value);
    await _preferences?.setInt('daily_schedule_start_hour', value.startHour);
    await _preferences?.setInt('daily_schedule_start_minute', value.startMinute);
    await _preferences?.setInt('daily_schedule_end_hour', value.endHour);
    await _preferences?.setInt('daily_schedule_end_minute', value.endMinute);
    await _preferences?.setBool('daily_schedule_enabled', value.enabled);
    await _scheduleDailyAutoEnableIfNeeded();
  }

  Future<String> _captureCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Location services disabled';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return 'Location permission denied';
      }
      final position = await Geolocator.getCurrentPosition();
      final location =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      await _preferences?.setString('last_known_location', location);
      return location;
    } catch (_) {
      return 'Location unavailable';
    }
  }

  Future<void> _requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _captureAndSyncCurrentLocation() async {
    final location = await _captureCurrentLocation();
    final latitude = _extractCoordinateFrom(location, 0);
    final longitude = _extractCoordinateFrom(location, 1);
    if (latitude == null || longitude == null) {
      return;
    }
    setState(() => _lastKnownLocation = location);
    await _api.syncLocation(
      userId: widget.userId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  double? _extractCoordinateFrom(String value, int index) {
    final parts = value.split(',');
    return parts.length == 2 ? double.tryParse(parts[index].trim()) : null;
  }

  Future<String> _captureIntruderPhoto() async {
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return 'No camera available';
      }
      final front = cameras.where((item) => item.lensDirection == CameraLensDirection.front);
      final selected = front.isNotEmpty ? front.first : cameras.first;
      controller = CameraController(selected, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      final photo = await controller.takePicture();
      _intruderPhotoPath = photo.path;
      return 'Captured: ${photo.path.split('\\').last}';
    } on CameraException catch (error) {
      return 'Camera unavailable: ${error.code}';
    } catch (_) {
      return 'Photo capture unavailable';
    } finally {
      await controller?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        pocketModeEnabled: _pocketModeEnabled,
        isCountingDown: _isCountingDown,
        alarmActive: _alarmActive,
        secondsRemaining: _secondsRemaining,
        autoActivationMinutes: _autoActivationMinutes,
        statusMessage: _statusMessage,
        lastKnownLocation: _lastKnownLocation,
        intruderPhotoStatus: _intruderPhotoStatus,
        pinController: _pinController,
        onTogglePocketMode: togglePocketMode,
        onSmallShake: () => registerMovement(strongMovement: false),
        onStrongMovement: () => registerMovement(strongMovement: true),
        onScreenWake: detectScreenWake,
        onCancelWithPin: cancelWithPin,
        onResetAlarm: resetAlarm,
        onScheduleAutoActivation: scheduleAutoActivation,
        onCancelAutoActivation: cancelAutoActivation,
      ),
      HistoryScreen(history: _history),
      ContactsScreen(
        nameController: _contactNameController,
        phoneController: _contactPhoneController,
        emailController: _contactEmailController,
        onChanged: saveContact,
      ),
      SettingsScreen(
        username: widget.username,
        securityLevel: _securityLevel,
        locationMode: _locationMode,
        verificationMode: _verificationMode,
        customRingtoneLabel: _customRingtoneLabel,
        lockScreenImageLabel: _lockScreenImageLabel,
        safetyAvatar: _safetyAvatar,
        removalGraceSeconds: _removalGraceSeconds,
        dailySchedule: _dailySchedule,
        onSecurityLevelChanged: updateSecurityLevel,
        onLocationModeChanged: updateLocationMode,
        onVerificationModeChanged: updateVerificationMode,
        onCustomRingtoneChanged: updateCustomRingtoneLabel,
        onPreviewRingtone: previewRingtone,
        onResetRingtone: resetRingtone,
        onLockScreenImageChanged: updateLockScreenImage,
        onSafetyAvatarChanged: updateSafetyAvatar,
        onRemovalGraceChanged: updateRemovalGraceSeconds,
        onDailyScheduleChanged: updateDailySchedule,
        onRequestLocationPermission: _requestLocationPermission,
        onLogout: () async {
          await _preferences?.remove('backend_user_id');
          await _preferences?.remove('username');
          await _preferences?.remove('api_token');
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
            (_) => false,
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Pocket Guardian')),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.contacts_outlined), label: 'Contacts'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

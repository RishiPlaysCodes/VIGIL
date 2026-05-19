/// User model for Vigil app
class VigilUser {
  final int id;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final String safetyAvatar;
  final bool pocketModeEnabled;
  final int gracePeriodSeconds;
  final bool scheduleEnabled;
  final String? scheduleStartTime;
  final String? scheduleEndTime;
  final List<String> scheduleDays;
  final bool batterySaverMode;
  final bool highSecurityMode;
  final bool locationSharingEnabled;
  final bool continuousLocationSync;
  final String customRingtone;
  final String? lockScreenImage;
  final DateTime createdAt;

  VigilUser({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    this.safetyAvatar = 'default',
    this.pocketModeEnabled = false,
    this.gracePeriodSeconds = 3,
    this.scheduleEnabled = false,
    this.scheduleStartTime,
    this.scheduleEndTime,
    this.scheduleDays = const [],
    this.batterySaverMode = false,
    this.highSecurityMode = false,
    this.locationSharingEnabled = true,
    this.continuousLocationSync = true,
    this.customRingtone = 'default_alarm',
    this.lockScreenImage,
    required this.createdAt,
  });

  factory VigilUser.fromJson(Map<String, dynamic> json) {
    return VigilUser(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      profileImage: json['profile_image'],
      safetyAvatar: json['safety_avatar'] ?? 'default',
      pocketModeEnabled: json['pocket_mode_enabled'] ?? false,
      gracePeriodSeconds: json['grace_period_seconds'] ?? 3,
      scheduleEnabled: json['schedule_enabled'] ?? false,
      scheduleStartTime: json['schedule_start_time'],
      scheduleEndTime: json['schedule_end_time'],
      scheduleDays: List<String>.from(json['schedule_days'] ?? []),
      batterySaverMode: json['battery_saver_mode'] ?? false,
      highSecurityMode: json['high_security_mode'] ?? false,
      locationSharingEnabled: json['location_sharing_enabled'] ?? true,
      continuousLocationSync: json['continuous_location_sync'] ?? true,
      customRingtone: json['custom_ringtone'] ?? 'default_alarm',
      lockScreenImage: json['lock_screen_image'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'safety_avatar': safetyAvatar,
      'pocket_mode_enabled': pocketModeEnabled,
      'grace_period_seconds': gracePeriodSeconds,
      'schedule_enabled': scheduleEnabled,
      'schedule_start_time': scheduleStartTime,
      'schedule_end_time': scheduleEndTime,
      'schedule_days': scheduleDays,
      'battery_saver_mode': batterySaverMode,
      'high_security_mode': highSecurityMode,
      'location_sharing_enabled': locationSharingEnabled,
      'continuous_location_sync': continuousLocationSync,
      'custom_ringtone': customRingtone,
      'lock_screen_image': lockScreenImage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

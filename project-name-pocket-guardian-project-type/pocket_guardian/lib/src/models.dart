/// Data models for the Pocket Guardian app.
/// All models are immutable value types with proper serialization.

class AlertRecord {
  const AlertRecord({
    required this.time,
    required this.reason,
    required this.status,
    this.id,
    this.latitude,
    this.longitude,
  });

  final int? id;
  final DateTime time;
  final String reason;
  final String status;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'time': time.toIso8601String(),
        'reason': reason,
        'status': status,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  factory AlertRecord.fromJson(Map<String, dynamic> json) {
    return AlertRecord(
      id: json['id'] as int?,
      time: DateTime.parse(json['time'] as String),
      reason: json['reason'] as String,
      status: json['status'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  AlertRecord copyWith({
    int? id,
    DateTime? time,
    String? reason,
    String? status,
    double? latitude,
    double? longitude,
  }) {
    return AlertRecord(
      id: id ?? this.id,
      time: time ?? this.time,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertRecord &&
          runtimeType == other.runtimeType &&
          time == other.time &&
          reason == other.reason &&
          status == other.status;

  @override
  int get hashCode => Object.hash(time, reason, status);
}

enum SecurityLevel { saver, balanced, highSecurity }

extension SecurityLevelLabel on SecurityLevel {
  String get label => switch (this) {
        SecurityLevel.saver => 'Battery Saver',
        SecurityLevel.balanced => 'Balanced',
        SecurityLevel.highSecurity => 'High Security',
      };

  String get description => switch (this) {
        SecurityLevel.saver => 'Minimal sensor usage, longer battery life',
        SecurityLevel.balanced => 'Moderate sensitivity, good battery balance',
        SecurityLevel.highSecurity => 'Maximum sensitivity, higher battery usage',
      };
}

enum LocationMode { alertOnly, travelWindow, whilePocketModeOn }

extension LocationModeLabel on LocationMode {
  String get label => switch (this) {
        LocationMode.alertOnly => 'Only on alert',
        LocationMode.travelWindow => 'During travel schedule',
        LocationMode.whilePocketModeOn => 'While Pocket Mode is ON',
      };
}

enum VerificationMode { pinOnly, biometricAndPin }

extension VerificationModeLabel on VerificationMode {
  String get label => switch (this) {
        VerificationMode.pinOnly => 'PIN only',
        VerificationMode.biometricAndPin => 'Biometric + PIN',
      };
}

enum SafetyAvatar { guardian, fox, dragon, custom }

extension SafetyAvatarLabel on SafetyAvatar {
  String get label => switch (this) {
        SafetyAvatar.guardian => 'Guardian',
        SafetyAvatar.fox => 'Fox',
        SafetyAvatar.dragon => 'Dragon',
        SafetyAvatar.custom => 'My image',
      };
}

class DailySchedule {
  const DailySchedule({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.enabled,
  });

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool enabled;

  String get startLabel =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  String get endLabel =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  String get windowLabel => '$startLabel – $endLabel';

  DailySchedule copyWith({
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? enabled,
  }) {
    return DailySchedule(
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySchedule &&
          runtimeType == other.runtimeType &&
          startHour == other.startHour &&
          startMinute == other.startMinute &&
          endHour == other.endHour &&
          endMinute == other.endMinute &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(startHour, startMinute, endHour, endMinute, enabled);
}

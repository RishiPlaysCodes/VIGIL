class AlertRecord {
  const AlertRecord({
    required this.time,
    required this.reason,
    required this.status,
  });

  final DateTime time;
  final String reason;
  final String status;

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'reason': reason,
        'status': status,
      };

  factory AlertRecord.fromJson(Map<String, dynamic> json) {
    return AlertRecord(
      time: DateTime.parse(json['time'] as String),
      reason: json['reason'] as String,
      status: json['status'] as String,
    );
  }
}

enum SecurityLevel { saver, balanced, highSecurity }

enum LocationMode { alertOnly, travelWindow, whilePocketModeOn }

enum VerificationMode { pinOnly, biometricAndPin }

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
}

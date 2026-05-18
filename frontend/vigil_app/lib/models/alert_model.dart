/// Alert model for Vigil app
class Alert {
  final int id;
  final String status;
  final String triggerType;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? intruderPhoto;
  final double? proximityValue;
  final double? lightValue;
  final bool smsSent;
  final bool emailSent;
  final List<Map<String, dynamic>> contactsNotified;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? notes;

  Alert({
    required this.id,
    required this.status,
    required this.triggerType,
    this.latitude,
    this.longitude,
    this.address,
    this.intruderPhoto,
    this.proximityValue,
    this.lightValue,
    this.smsSent = false,
    this.emailSent = false,
    this.contactsNotified = const [],
    required this.triggeredAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.notes,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      status: json['status'],
      triggerType: json['trigger_type'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      address: json['address'],
      intruderPhoto: json['intruder_photo'],
      proximityValue: (json['proximity_value'] as num?)?.toDouble(),
      lightValue: (json['light_value'] as num?)?.toDouble(),
      smsSent: json['sms_sent'] ?? false,
      emailSent: json['email_sent'] ?? false,
      contactsNotified:
          List<Map<String, dynamic>>.from(json['contacts_notified'] ?? []),
      triggeredAt: DateTime.parse(json['triggered_at']),
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'])
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      notes: json['notes'],
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'triggered':
        return 'Active';
      case 'acknowledged':
        return 'Acknowledged';
      case 'cancelled':
        return 'Cancelled';
      case 'resolved':
        return 'Resolved';
      case 'false_alarm':
        return 'False Alarm';
      default:
        return status;
    }
  }

  String get triggerDisplay {
    switch (triggerType) {
      case 'pocket_removal':
        return 'Pocket Removal';
      case 'manual':
        return 'Manual';
      case 'schedule':
        return 'Scheduled';
      case 'shake':
        return 'Shake';
      default:
        return triggerType;
    }
  }

  String? get mapLink {
    if (latitude != null && longitude != null) {
      return 'https://maps.google.com/?q=$latitude,$longitude';
    }
    return null;
  }
}

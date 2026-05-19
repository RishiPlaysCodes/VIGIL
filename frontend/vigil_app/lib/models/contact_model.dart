/// Emergency contact model
class EmergencyContact {
  final int? id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String relationship;
  final bool isPrimary;
  final bool notifyBySms;
  final bool notifyByEmail;
  final bool notifyByCall;
  final DateTime? createdAt;

  EmergencyContact({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.relationship = 'other',
    this.isPrimary = false,
    this.notifyBySms = true,
    this.notifyByEmail = true,
    this.notifyByCall = false,
    this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      relationship: json['relationship'] ?? 'other',
      isPrimary: json['is_primary'] ?? false,
      notifyBySms: json['notify_by_sms'] ?? true,
      notifyByEmail: json['notify_by_email'] ?? true,
      notifyByCall: json['notify_by_call'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'relationship': relationship,
      'is_primary': isPrimary,
      'notify_by_sms': notifyBySms,
      'notify_by_email': notifyByEmail,
      'notify_by_call': notifyByCall,
    };
  }

  String get relationshipDisplay {
    switch (relationship) {
      case 'parent':
        return 'Parent';
      case 'guardian':
        return 'Guardian';
      case 'spouse':
        return 'Spouse';
      case 'sibling':
        return 'Sibling';
      case 'friend':
        return 'Friend';
      default:
        return 'Other';
    }
  }
}

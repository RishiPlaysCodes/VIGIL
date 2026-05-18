import 'package:flutter/material.dart';

/// AI Safety Character (Guardian) System for Vigil.
///
/// Users can select or customize their own guardian assistant that:
/// - Guides users during emergencies with contextual messages
/// - Animates during verification flows
/// - Appears throughout the UI as a companion
/// - Enhances the emotional identity and branding of the app
/// - Provides personality-driven safety tips and feedback
///
/// Available Guardian Types:
/// 1. Cyber Guardian — Futuristic AI sentinel, cold logic, maximum protection
/// 2. Holo Companion — Friendly holographic assistant, warm and reassuring
/// 3. Phantom Shield — Stealth-mode protector, minimal but powerful
/// 4. Neon Sentinel — High-tech warrior, aggressive defense posture
/// 5. Crystal Oracle — Mystical protector, predictive and calm
/// 6. Custom — User-defined name and appearance settings
class GuardianCharacterService {
  static final GuardianCharacterService _instance = GuardianCharacterService._internal();
  factory GuardianCharacterService() => _instance;
  GuardianCharacterService._internal();

  // Current active guardian
  GuardianCharacter _activeGuardian = GuardianCharacter.cyberGuardian();

  // Getters
  GuardianCharacter get activeGuardian => _activeGuardian;
  String get name => _activeGuardian.name;
  GuardianType get type => _activeGuardian.type;

  /// Set the active guardian
  void setGuardian(GuardianCharacter guardian) {
    _activeGuardian = guardian;
  }

  /// Set guardian by type
  void setGuardianByType(GuardianType type) {
    _activeGuardian = _getGuardianByType(type);
  }

  /// Get all available guardians
  List<GuardianCharacter> getAllGuardians() {
    return [
      GuardianCharacter.cyberGuardian(),
      GuardianCharacter.holoCompanion(),
      GuardianCharacter.phantomShield(),
      GuardianCharacter.neonSentinel(),
      GuardianCharacter.crystalOracle(),
    ];
  }

  /// Get contextual message from guardian based on current state
  GuardianMessage getMessage(GuardianContext context) {
    return _activeGuardian.getContextualMessage(context);
  }

  /// Get animation state for current UI context
  GuardianAnimationState getAnimationState(GuardianContext context) {
    switch (context) {
      case GuardianContext.idle:
        return GuardianAnimationState.breathing;
      case GuardianContext.monitoring:
        return GuardianAnimationState.scanning;
      case GuardianContext.pocketDetected:
        return GuardianAnimationState.shielding;
      case GuardianContext.extractionDetected:
        return GuardianAnimationState.alert;
      case GuardianContext.verifying:
        return GuardianAnimationState.analyzing;
      case GuardianContext.emergency:
        return GuardianAnimationState.combat;
      case GuardianContext.safe:
        return GuardianAnimationState.relaxed;
      case GuardianContext.greeting:
        return GuardianAnimationState.waving;
    }
  }

  GuardianCharacter _getGuardianByType(GuardianType type) {
    switch (type) {
      case GuardianType.cyberGuardian:
        return GuardianCharacter.cyberGuardian();
      case GuardianType.holoCompanion:
        return GuardianCharacter.holoCompanion();
      case GuardianType.phantomShield:
        return GuardianCharacter.phantomShield();
      case GuardianType.neonSentinel:
        return GuardianCharacter.neonSentinel();
      case GuardianType.crystalOracle:
        return GuardianCharacter.crystalOracle();
      case GuardianType.custom:
        return _activeGuardian; // Keep current custom
    }
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

enum GuardianType {
  cyberGuardian,
  holoCompanion,
  phantomShield,
  neonSentinel,
  crystalOracle,
  custom,
}

enum GuardianContext {
  idle,
  monitoring,
  pocketDetected,
  extractionDetected,
  verifying,
  emergency,
  safe,
  greeting,
}

enum GuardianAnimationState {
  breathing,
  scanning,
  shielding,
  alert,
  analyzing,
  combat,
  relaxed,
  waving,
}

class GuardianCharacter {
  final String name;
  final GuardianType type;
  final String title;
  final String description;
  final GuardianAppearance appearance;
  final GuardianPersonality personality;
  final Map<GuardianContext, String> messages;

  GuardianCharacter({
    required this.name,
    required this.type,
    required this.title,
    required this.description,
    required this.appearance,
    required this.personality,
    required this.messages,
  });

  /// Get contextual message
  GuardianMessage getContextualMessage(GuardianContext context) {
    final text = messages[context] ?? personality.defaultMessage;
    return GuardianMessage(
      text: text,
      tone: personality.tone,
      urgency: _getUrgency(context),
    );
  }

  MessageUrgency _getUrgency(GuardianContext context) {
    switch (context) {
      case GuardianContext.emergency:
        return MessageUrgency.critical;
      case GuardianContext.extractionDetected:
      case GuardianContext.verifying:
        return MessageUrgency.high;
      case GuardianContext.monitoring:
      case GuardianContext.pocketDetected:
        return MessageUrgency.normal;
      default:
        return MessageUrgency.low;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PRESET GUARDIANS
  // ═══════════════════════════════════════════════════════════

  factory GuardianCharacter.cyberGuardian() {
    return GuardianCharacter(
      name: 'NEXUS',
      type: GuardianType.cyberGuardian,
      title: 'Cyber Guardian',
      description: 'A cold-logic AI sentinel. Maximum protection, zero compromise.',
      appearance: GuardianAppearance(
        primaryColor: const Color(0xFF00F5FF),
        secondaryColor: const Color(0xFF0EA5E9),
        accentColor: const Color(0xFF8B5CF6),
        iconData: Icons.security_rounded,
        glowIntensity: 0.8,
        particleStyle: 'circuits',
      ),
      personality: GuardianPersonality(
        tone: 'authoritative',
        defaultMessage: 'Systems operational. Vigilance maintained.',
        voiceStyle: 'synthetic',
      ),
      messages: {
        GuardianContext.idle: 'Systems idle. Ready for deployment.',
        GuardianContext.monitoring: 'All sensors active. Perimeter secured.',
        GuardianContext.pocketDetected: 'Device secured. Monitoring active.',
        GuardianContext.extractionDetected: 'ALERT: Unauthorized extraction detected. Initiating verification protocol.',
        GuardianContext.verifying: 'Identity verification in progress. Stand by.',
        GuardianContext.emergency: 'EMERGENCY PROTOCOL ENGAGED. All countermeasures active.',
        GuardianContext.safe: 'Identity confirmed. Threat neutralized. Resuming standby.',
        GuardianContext.greeting: 'NEXUS online. Your protection is my directive.',
      },
    );
  }

  factory GuardianCharacter.holoCompanion() {
    return GuardianCharacter(
      name: 'ARIA',
      type: GuardianType.holoCompanion,
      title: 'Holo Companion',
      description: 'A warm, friendly holographic assistant. Always by your side.',
      appearance: GuardianAppearance(
        primaryColor: const Color(0xFF2DD4BF),
        secondaryColor: const Color(0xFF34D399),
        accentColor: const Color(0xFFFBBF24),
        iconData: Icons.auto_awesome_rounded,
        glowIntensity: 0.6,
        particleStyle: 'sparkles',
      ),
      personality: GuardianPersonality(
        tone: 'friendly',
        defaultMessage: 'I\'m here for you. Everything is okay.',
        voiceStyle: 'warm',
      ),
      messages: {
        GuardianContext.idle: 'Relaxing together. I\'m always watching over you.',
        GuardianContext.monitoring: 'I\'ve got my eye on things. You\'re safe with me!',
        GuardianContext.pocketDetected: 'Phone is cozy and secure. I\'ll keep watch.',
        GuardianContext.extractionDetected: 'Hold on — something doesn\'t feel right. Let me check...',
        GuardianContext.verifying: 'Quick check! Just confirming it\'s really you.',
        GuardianContext.emergency: 'Don\'t worry! I\'m sending help right now. Stay calm.',
        GuardianContext.safe: 'It\'s you! False alarm. Everything is perfectly fine.',
        GuardianContext.greeting: 'Hey there! Aria here, ready to keep you safe today.',
      },
    );
  }

  factory GuardianCharacter.phantomShield() {
    return GuardianCharacter(
      name: 'PHANTOM',
      type: GuardianType.phantomShield,
      title: 'Phantom Shield',
      description: 'Invisible but invincible. Silent stealth protection.',
      appearance: GuardianAppearance(
        primaryColor: const Color(0xFF64748B),
        secondaryColor: const Color(0xFF475569),
        accentColor: const Color(0xFFF8FAFC),
        iconData: Icons.visibility_off_rounded,
        glowIntensity: 0.3,
        particleStyle: 'mist',
      ),
      personality: GuardianPersonality(
        tone: 'mysterious',
        defaultMessage: '...',
        voiceStyle: 'whisper',
      ),
      messages: {
        GuardianContext.idle: '',
        GuardianContext.monitoring: 'In the shadows. Watching.',
        GuardianContext.pocketDetected: 'Cloaked.',
        GuardianContext.extractionDetected: 'Movement detected. Analyzing.',
        GuardianContext.verifying: 'Confirm.',
        GuardianContext.emergency: 'Threat active. Countermeasures deployed.',
        GuardianContext.safe: 'Clear. Resuming stealth.',
        GuardianContext.greeting: 'Phantom active.',
      },
    );
  }

  factory GuardianCharacter.neonSentinel() {
    return GuardianCharacter(
      name: 'BLAZE',
      type: GuardianType.neonSentinel,
      title: 'Neon Sentinel',
      description: 'High-energy warrior. Aggressive defense, maximum deterrence.',
      appearance: GuardianAppearance(
        primaryColor: const Color(0xFFF43F5E),
        secondaryColor: const Color(0xFFD946EF),
        accentColor: const Color(0xFFFBBF24),
        iconData: Icons.local_fire_department_rounded,
        glowIntensity: 1.0,
        particleStyle: 'flames',
      ),
      personality: GuardianPersonality(
        tone: 'aggressive',
        defaultMessage: 'Ready to fight. Try me.',
        voiceStyle: 'bold',
      ),
      messages: {
        GuardianContext.idle: 'Standing guard. No one gets through.',
        GuardianContext.monitoring: 'Perimeter locked. All threats will be crushed.',
        GuardianContext.pocketDetected: 'Locked and loaded. Phone is mine to protect.',
        GuardianContext.extractionDetected: 'HEY! Back off! Verifying target...',
        GuardianContext.verifying: 'PROVE IT. Show me who you are.',
        GuardianContext.emergency: 'INTRUDER! ALARM ACTIVATED! You messed with the wrong phone!',
        GuardianContext.safe: 'Stand down. Owner confirmed. As you were.',
        GuardianContext.greeting: 'BLAZE reporting for duty. Let\'s keep it safe out there.',
      },
    );
  }

  factory GuardianCharacter.crystalOracle() {
    return GuardianCharacter(
      name: 'ORACLE',
      type: GuardianType.crystalOracle,
      title: 'Crystal Oracle',
      description: 'Predictive and serene. Sees threats before they happen.',
      appearance: GuardianAppearance(
        primaryColor: const Color(0xFF8B5CF6),
        secondaryColor: const Color(0xFFC084FC),
        accentColor: const Color(0xFF67E8F9),
        iconData: Icons.remove_red_eye_rounded,
        glowIntensity: 0.7,
        particleStyle: 'crystals',
      ),
      personality: GuardianPersonality(
        tone: 'serene',
        defaultMessage: 'The future is clear. You are protected.',
        voiceStyle: 'calm',
      ),
      messages: {
        GuardianContext.idle: 'The currents are calm. All is well.',
        GuardianContext.monitoring: 'I see all paths ahead. You walk safely.',
        GuardianContext.pocketDetected: 'Your device rests in the protective field.',
        GuardianContext.extractionDetected: 'A disturbance... I foresee a threat approaching.',
        GuardianContext.verifying: 'Show me your essence. Let me read your identity.',
        GuardianContext.emergency: 'Danger is present. I am channeling protection to your guardians.',
        GuardianContext.safe: 'The vision clears. You are the rightful keeper. Peace restored.',
        GuardianContext.greeting: 'I am Oracle. Through me, no harm shall find you unseen.',
      },
    );
  }
}

class GuardianAppearance {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final IconData iconData;
  final double glowIntensity;
  final String particleStyle;

  GuardianAppearance({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.iconData,
    required this.glowIntensity,
    required this.particleStyle,
  });
}

class GuardianPersonality {
  final String tone;
  final String defaultMessage;
  final String voiceStyle;

  GuardianPersonality({
    required this.tone,
    required this.defaultMessage,
    required this.voiceStyle,
  });
}

class GuardianMessage {
  final String text;
  final String tone;
  final MessageUrgency urgency;

  GuardianMessage({
    required this.text,
    required this.tone,
    required this.urgency,
  });
}

enum MessageUrgency {
  low,
  normal,
  high,
  critical,
}

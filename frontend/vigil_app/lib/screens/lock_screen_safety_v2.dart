import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';
import '../widgets/guardian_avatar_widget.dart';
import '../services/alert_coordinator_v2.dart';
import '../services/face_verification_service.dart';
import '../services/multi_layer_auth_service.dart';
import '../services/guardian_character_service.dart';

/// Lock Screen Safety V2 — the critical screen that opens when AI detects
/// suspicious extraction. Runs face verification → multi-layer auth → emergency.
class LockScreenSafetyV2 extends StatefulWidget {
  const LockScreenSafetyV2({super.key});

  @override
  State<LockScreenSafetyV2> createState() => _LockScreenSafetyV2State();
}

class _LockScreenSafetyV2State extends State<LockScreenSafetyV2>
    with TickerProviderStateMixin {
  final AlertCoordinatorV2 _coordinator = AlertCoordinatorV2();
  final FaceVerificationService _face = FaceVerificationService();
  final MultiLayerAuthService _auth = MultiLayerAuthService();
  final GuardianCharacterService _guardian = GuardianCharacterService();

  // Phase state
  _SafetyPhase _phase = _SafetyPhase.faceVerification;

  // Countdown
  int _countdown = 0;
  Timer? _countdownTimer;

  // PIN input
  final _pinController = TextEditingController();
  String _authStatusMsg = '';

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _countdown = _coordinator.gracePeriodSeconds;

    // Start with face verification
    _startFaceVerification();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _startFaceVerification() async {
    setState(() => _phase = _SafetyPhase.faceVerification);

    // Try face verification (auto-cancel if owner)
    try {
      final result = await _face.startVerification();
      if (!mounted) return;

      if (result.shouldAutoCancel) {
        _onSafeConfirmed(AuthMethod.face);
        return;
      }
    } catch (_) {
      // Face service not enrolled or unavailable — fall through to manual auth
    }

    // Move to manual auth + countdown
    _startManualAuth();
  }

  void _startManualAuth() {
    setState(() => _phase = _SafetyPhase.manualAuth);

    // Begin grace countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _onCountdownExpired();
      }
    });
  }

  void _onCountdownExpired() {
    if (!mounted) return;
    setState(() => _phase = _SafetyPhase.emergencyTriggered);
    _countdownTimer?.cancel();

    // Navigate to emergency active screen after brief animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/emergency-active');
      }
    });
  }

  Future<void> _tryFingerprint() async {
    final result = await _auth.verifyFingerprint();
    if (!mounted) return;
    if (result.success) {
      _onSafeConfirmed(AuthMethod.fingerprint);
    } else {
      setState(() => _authStatusMsg = result.message);
    }
  }

  Future<void> _tryVoicePassword() async {
    setState(() => _authStatusMsg = 'Listening...');
    final result = await _auth.verifyVoicePassword();
    if (!mounted) return;
    if (result.success) {
      _onSafeConfirmed(AuthMethod.voicePassword);
    } else {
      setState(() => _authStatusMsg = result.message);
    }
  }

  void _tryPin() {
    if (_pinController.text.isEmpty) return;
    final result = _auth.verifyPin(_pinController.text);
    if (!mounted) return;
    if (result.success) {
      _onSafeConfirmed(AuthMethod.pin);
    } else {
      setState(() {
        _authStatusMsg = result.message;
        _pinController.clear();
      });
    }
  }

  void _onSafeConfirmed(AuthMethod method) {
    _countdownTimer?.cancel();
    _coordinator.onOwnerVerified();
    setState(() => _phase = _SafetyPhase.confirmedSafe);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final guardianCtx = _phase == _SafetyPhase.emergencyTriggered
        ? GuardianContext.emergency
        : _phase == _SafetyPhase.confirmedSafe
            ? GuardianContext.safe
            : GuardianContext.verifying;

    final isUrgent = _phase == _SafetyPhase.manualAuth ||
        _phase == _SafetyPhase.emergencyTriggered;

    return WillPopScope(
      onWillPop: () async => false, // Cannot back out — must authenticate
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: _phase == _SafetyPhase.emergencyTriggered
                ? VigilThemeV2.emergencyGradient
                : isUrgent
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2D0A1F),
                          Color(0xFF1A0612),
                          Color(0xFF050714),
                        ],
                      )
                    : VigilThemeV2.backgroundGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Top warning header
                  if (_phase != _SafetyPhase.confirmedSafe)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 0.7 + 0.3 * _pulseController.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: VigilThemeV2.roseEmergency.withOpacity(0.15),
                              border: Border.all(
                                color: VigilThemeV2.roseEmergency.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_rounded,
                                    color: VigilThemeV2.roseEmergency, size: 16),
                                SizedBox(width: 8),
                                Text('EXTRACTION DETECTED',
                                    style: TextStyle(
                                      color: VigilThemeV2.roseEmergency,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 30),

                  // Guardian avatar
                  GuardianAvatarWidget(
                    guardian: _guardian.activeGuardian,
                    context: guardianCtx,
                    size: 110,
                    showMessage: true,
                  ),

                  const SizedBox(height: 30),

                  // Phase content
                  Expanded(child: _buildPhaseContent()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case _SafetyPhase.faceVerification:
        return _buildFaceVerificationPhase();
      case _SafetyPhase.manualAuth:
        return _buildManualAuthPhase();
      case _SafetyPhase.emergencyTriggered:
        return _buildEmergencyTriggeredPhase();
      case _SafetyPhase.confirmedSafe:
        return _buildConfirmedSafePhase();
    }
  }

  Widget _buildFaceVerificationPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('SCANNING YOUR FACE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: VigilThemeV2.textPrimary,
              letterSpacing: 3,
            )),
        const SizedBox(height: 8),
        Text('Look at the camera to confirm identity',
            style: VigilThemeV2.bodySM,
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        const SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5, color: VigilThemeV2.violetNeon,
          ),
        ),
        const SizedBox(height: 16),
        Text('Auto-cancelling alert if owner detected...',
            style: VigilThemeV2.caption),
      ],
    );
  }

  Widget _buildManualAuthPhase() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Big countdown
          NeoGlassCard(
            padding: const EdgeInsets.all(20),
            showHoloBorder: true,
            glowColor: VigilThemeV2.roseEmergency,
            animateGlow: true,
            child: Column(
              children: [
                Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: VigilThemeV2.roseEmergency,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('SECONDS TO VERIFY',
                    style: TextStyle(
                      fontSize: 11,
                      color: VigilThemeV2.roseEmergency,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Auth methods row
          Row(
            children: [
              Expanded(
                child: _authButton('Fingerprint', Icons.fingerprint_rounded,
                    VigilThemeV2.tealGlow, _tryFingerprint),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _authButton('Voice', Icons.mic_rounded,
                    VigilThemeV2.violetNeon, _tryVoicePassword),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // PIN field
          NeoGlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.pin_rounded,
                    color: VigilThemeV2.amberAlert, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: VigilThemeV2.textPrimary,
                        letterSpacing: 4),
                    decoration: const InputDecoration(
                      hintText: 'Enter PIN',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _tryPin(),
                  ),
                ),
                IconButton(
                  onPressed: _tryPin,
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: VigilThemeV2.amberAlert),
                ),
              ],
            ),
          ),

          if (_authStatusMsg.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_authStatusMsg,
                style: const TextStyle(
                  fontSize: 12,
                  color: VigilThemeV2.roseEmergency,
                ),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _authButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return NeoGlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      glowColor: color,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              )),
        ],
      ),
    );
  }

  Widget _buildEmergencyTriggeredPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.crisis_alert_rounded,
            size: 72, color: VigilThemeV2.roseEmergency),
        const SizedBox(height: 16),
        const HoloText(
          text: 'EMERGENCY MODE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        const Text('Activating emergency protocol...',
            style: TextStyle(color: VigilThemeV2.textPrimary, fontSize: 14)),
      ],
    );
  }

  Widget _buildConfirmedSafePhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: VigilThemeV2.shieldGradient,
            boxShadow: VigilThemeV2.neonGlow(VigilThemeV2.emeraldPulse, intensity: 0.5),
          ),
          child: const Icon(Icons.verified_rounded,
              size: 56, color: VigilThemeV2.spaceBlack),
        ),
        const SizedBox(height: 20),
        const Text('IDENTITY VERIFIED',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: VigilThemeV2.emeraldPulse,
              letterSpacing: 3,
            )),
        const SizedBox(height: 8),
        const Text('Welcome back. Returning to safety.',
            style: TextStyle(color: VigilThemeV2.textSecondary, fontSize: 14)),
      ],
    );
  }
}

enum _SafetyPhase {
  faceVerification,
  manualAuth,
  emergencyTriggered,
  confirmedSafe,
}

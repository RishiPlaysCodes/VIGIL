import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';
import '../widgets/guardian_avatar_widget.dart';
import '../services/alert_coordinator_v2.dart';
import '../services/emergency_protocol_service.dart';
import '../services/realtime_tracking_service.dart';
import '../services/multi_layer_auth_service.dart';
import '../services/guardian_character_service.dart';

/// Emergency Active Screen — full emergency protocol UI.
/// Shows photo counter, SOS flashlight, live tracking, contact alerts,
/// and requires multi-layer authentication to deactivate.
class EmergencyActiveScreen extends StatefulWidget {
  const EmergencyActiveScreen({super.key});

  @override
  State<EmergencyActiveScreen> createState() => _EmergencyActiveScreenState();
}

class _EmergencyActiveScreenState extends State<EmergencyActiveScreen>
    with TickerProviderStateMixin {
  final EmergencyProtocolService _emergency = EmergencyProtocolService();
  final RealtimeTrackingService _tracking = RealtimeTrackingService();
  final AlertCoordinatorV2 _coordinator = AlertCoordinatorV2();
  final MultiLayerAuthService _auth = MultiLayerAuthService();
  final GuardianCharacterService _guardian = GuardianCharacterService();

  late AnimationController _alarmController;
  late AnimationController _flashController;

  EmergencyStatus? _status;
  Timer? _refreshTimer;
  String? _liveAddress;
  String? _liveLink;

  @override
  void initState() {
    super.initState();
    _alarmController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..repeat(reverse: true);

    // Activate emergency protocol now (assumes alert is active)
    _activateProtocol();

    // Listen to status updates
    _emergency.onStatusUpdate = (s) {
      if (mounted) setState(() => _status = s);
    };

    // Listen to tracking updates
    _tracking.onAddressUpdate = (addr) {
      if (mounted) {
        setState(() {
          _liveAddress = addr;
          _liveLink = _tracking.generateLiveTrackingLink();
        });
      }
    };

    // Refresh status every 500ms
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _status = _emergency.getStatus();
          _liveAddress = _tracking.currentAddress;
          _liveLink = _tracking.generateLiveTrackingLink();
        });
      }
    });
  }

  Future<void> _activateProtocol() async {
    // Switch tracking to emergency mode (3-second updates)
    _tracking.activateEmergencyMode();

    // Activate emergency protocol with all systems
    await _emergency.activate(
      alertId: DateTime.now().millisecondsSinceEpoch,
      enableVideo: false,
      enableFlashlight: true,
      enableMaxBrightness: true,
    );
  }

  @override
  void dispose() {
    _alarmController.dispose();
    _flashController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _attemptDeactivate() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VigilThemeV2.cardBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DeactivateAuthSheet(authService: _auth),
    );

    if (result == true && mounted) {
      await _emergency.deactivate();
      _tracking.deactivateEmergencyMode();
      _coordinator.onOwnerVerified();
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status ?? _emergency.getStatus();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _alarmController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      const Color(0xFF2D0612),
                      const Color(0xFF7F1D1D),
                      _alarmController.value,
                    )!,
                    const Color(0xFF1A0408),
                    const Color(0xFF050308),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildEmergencyHeader(),
                      const SizedBox(height: 20),
                      GuardianAvatarWidget(
                        guardian: _guardian.activeGuardian,
                        context: GuardianContext.emergency,
                        size: 100,
                        showMessage: true,
                      ),
                      const SizedBox(height: 20),
                      _buildEvidenceRow(status),
                      const SizedBox(height: 12),
                      _buildSystemsRow(status),
                      const SizedBox(height: 12),
                      _buildLocationCard(),
                      const SizedBox(height: 12),
                      _buildContactsCard(),
                      const SizedBox(height: 24),
                      _buildDeactivateButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color.lerp(
                  VigilThemeV2.roseEmergency,
                  VigilThemeV2.crimsonDanger,
                  _flashController.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: VigilThemeV2.roseEmergency.withOpacity(0.6),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.crisis_alert_rounded,
                      color: VigilThemeV2.textPrimary, size: 18),
                  SizedBox(width: 8),
                  Text('EMERGENCY ACTIVE',
                      style: TextStyle(
                        color: VigilThemeV2.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      )),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const HoloText(
          text: 'PROTOCOL ENGAGED',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'All defenses active. Contacts notified.',
          style: VigilThemeV2.bodySM.copyWith(color: VigilThemeV2.textPrimary),
        ),
      ],
    );
  }

  Widget _buildEvidenceRow(EmergencyStatus status) {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            'Photos',
            status.photosCaptured.toString(),
            'Captured',
            Icons.camera_alt_rounded,
            VigilThemeV2.violetNeon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statTile(
            'Uploaded',
            status.photosUploaded.toString(),
            'To server',
            Icons.cloud_upload_rounded,
            VigilThemeV2.tealGlow,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statTile(
            'Updates',
            status.locationUpdates.toString(),
            'Location',
            Icons.location_on_rounded,
            VigilThemeV2.amberAlert,
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, String sub, IconData icon, Color color) {
    return NeoGlassCard(
      padding: const EdgeInsets.all(12),
      glowColor: color,
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              )),
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                color: VigilThemeV2.textPrimary,
                fontWeight: FontWeight.w600,
              )),
          Text(sub,
              style: VigilThemeV2.caption.copyWith(fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildSystemsRow(EmergencyStatus status) {
    return NeoGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIVE SYSTEMS', style: VigilThemeV2.labelBrand),
          const SizedBox(height: 10),
          Row(
            children: [
              _systemBadge('Alarm', true, Icons.volume_up_rounded),
              _systemBadge('Camera', status.photosCaptured > 0, Icons.videocam_rounded),
              _systemBadge('SOS', status.flashlightActive, Icons.flash_on_rounded),
              _systemBadge('GPS', true, Icons.gps_fixed_rounded),
              _systemBadge('Bright', status.maxBrightnessActive,
                  Icons.brightness_high_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _systemBadge(String label, bool active, IconData icon) {
    final color = active ? VigilThemeV2.emeraldPulse : VigilThemeV2.textMuted;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.4), width: 1),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return NeoGlassCard(
      padding: const EdgeInsets.all(14),
      glowColor: VigilThemeV2.amberAlert,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.location_searching_rounded,
                color: VigilThemeV2.amberAlert, size: 18),
            const SizedBox(width: 8),
            Text('LIVE LOCATION', style: VigilThemeV2.labelBrand.copyWith(
                color: VigilThemeV2.amberAlert)),
          ]),
          const SizedBox(height: 10),
          Text(
            _liveAddress ?? 'Resolving address...',
            style: const TextStyle(
              color: VigilThemeV2.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _liveLink ?? 'Generating tracking link...',
            style: VigilThemeV2.caption.copyWith(
              color: VigilThemeV2.tealGlow,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContactsCard() {
    return NeoGlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: VigilThemeV2.shieldGradient,
            ),
            child: const Icon(Icons.contacts_rounded,
                color: VigilThemeV2.spaceBlack, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONTACTS NOTIFIED',
                    style: TextStyle(
                      fontSize: 11,
                      color: VigilThemeV2.emeraldPulse,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    )),
                SizedBox(height: 4),
                Text('SMS + Email + Live Track sent',
                    style: TextStyle(
                      fontSize: 12,
                      color: VigilThemeV2.textPrimary,
                    )),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: VigilThemeV2.emeraldPulse, size: 22),
        ],
      ),
    );
  }

  Widget _buildDeactivateButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _attemptDeactivate,
        style: ElevatedButton.styleFrom(
          backgroundColor: VigilThemeV2.textPrimary,
          foregroundColor: VigilThemeV2.crimsonDanger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.lock_open_rounded, size: 22),
        label: const Text(
          'AUTHENTICATE TO STOP',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet shown to authenticate before deactivating emergency.
class _DeactivateAuthSheet extends StatefulWidget {
  final MultiLayerAuthService authService;
  const _DeactivateAuthSheet({required this.authService});

  @override
  State<_DeactivateAuthSheet> createState() => _DeactivateAuthSheetState();
}

class _DeactivateAuthSheetState extends State<_DeactivateAuthSheet> {
  final _pinController = TextEditingController();
  String _msg = '';
  bool _loading = false;

  Future<void> _runFingerprint() async {
    setState(() => _loading = true);
    final r = await widget.authService.verifyFingerprint();
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _msg = r.message);
    }
  }

  Future<void> _runVoice() async {
    setState(() {
      _loading = true;
      _msg = 'Listening for your phrase...';
    });
    final r = await widget.authService.verifyVoicePassword();
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _msg = r.message);
    }
  }

  void _runPin() {
    if (_pinController.text.isEmpty) return;
    final r = widget.authService.verifyPin(_pinController.text);
    if (r.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _msg = r.message;
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: VigilThemeV2.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const HoloText(
            text: 'AUTHENTICATE',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                letterSpacing: 3),
          ),
          const SizedBox(height: 6),
          Text('Verify your identity to stop emergency',
              style: VigilThemeV2.caption),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: NeoGlassCard(
                  padding: const EdgeInsets.all(14),
                  onTap: _loading ? null : _runFingerprint,
                  glowColor: VigilThemeV2.tealGlow,
                  child: const Column(children: [
                    Icon(Icons.fingerprint_rounded,
                        color: VigilThemeV2.tealGlow, size: 32),
                    SizedBox(height: 6),
                    Text('Fingerprint',
                        style: TextStyle(
                          color: VigilThemeV2.tealGlow,
                          fontWeight: FontWeight.w700, fontSize: 12,
                        )),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NeoGlassCard(
                  padding: const EdgeInsets.all(14),
                  onTap: _loading ? null : _runVoice,
                  glowColor: VigilThemeV2.violetNeon,
                  child: const Column(children: [
                    Icon(Icons.mic_rounded,
                        color: VigilThemeV2.violetNeon, size: 32),
                    SizedBox(height: 6),
                    Text('Voice',
                        style: TextStyle(
                          color: VigilThemeV2.violetNeon,
                          fontWeight: FontWeight.w700, fontSize: 12,
                        )),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NeoGlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.pin_rounded,
                    color: VigilThemeV2.amberAlert, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: VigilThemeV2.textPrimary, letterSpacing: 4),
                    decoration: const InputDecoration(
                      hintText: 'Enter PIN',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _runPin(),
                  ),
                ),
                IconButton(
                  onPressed: _runPin,
                  icon: const Icon(Icons.check_circle_rounded,
                      color: VigilThemeV2.amberAlert),
                ),
              ],
            ),
          ),
          if (_msg.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_msg,
                style: VigilThemeV2.caption.copyWith(
                  color: VigilThemeV2.roseEmergency,
                ),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';
import '../services/alert_coordinator_v2.dart';
import '../services/ai_sensor_fusion_engine.dart';
import '../services/sensor_manager_v2.dart';
import '../utils/navigation_service.dart';

/// Pocket Mode V2 — actually starts the AI safety engine and displays
/// live sensor confidence, threat scoring, and movement classification.
class PocketModeScreenV2 extends StatefulWidget {
  const PocketModeScreenV2({super.key});

  @override
  State<PocketModeScreenV2> createState() => _PocketModeScreenV2State();
}

class _PocketModeScreenV2State extends State<PocketModeScreenV2>
    with SingleTickerProviderStateMixin {
  final AlertCoordinatorV2 _coordinator = AlertCoordinatorV2();
  final AISensorFusionEngine _fusion = AISensorFusionEngine();
  final SensorManagerV2 _sensors = SensorManagerV2();

  bool _isActive = false;
  int _gracePeriod = 3;
  bool _highSecurity = false;
  bool _batterySaver = false;

  // Live AI debug data
  SensorFusionDebug? _debug;
  Timer? _refreshTimer;

  late AnimationController _pulseController;

  final List<int> _graceOptions = [3, 5, 10, 20];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _isActive = _coordinator.isProtectionActive;
    _gracePeriod = _coordinator.gracePeriodSeconds;

    // Subscribe to AI fusion debug stream for live sensor visualization
    _fusion.onDebugUpdate = (debug) {
      if (mounted) setState(() => _debug = debug);
    };

    // Wire emergency screen launch
    _coordinator.onShowSafetyScreen = () {
      NavigationService.pushNamed('/lock-screen-safety');
    };
    _coordinator.onAlarmStarted = () {
      NavigationService.pushNamed('/emergency-active');
    };

    // Refresh status periodically
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleProtection() async {
    if (_isActive) {
      _coordinator.disableProtection();
      _pulseController.stop();
    } else {
      await _coordinator.enableProtection(
        gracePeriodSeconds: _gracePeriod,
        highSecurity: _highSecurity,
        batterySaver: _batterySaver,
      );
      _pulseController.repeat(reverse: true);
    }
    setState(() => _isActive = _coordinator.isProtectionActive);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POCKET MODE',
            style: TextStyle(letterSpacing: 3, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: VigilThemeV2.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildMainToggle(),
              const SizedBox(height: 24),

              if (_isActive) _buildLiveAIDisplay(),

              const SizedBox(height: 16),
              _buildGracePeriodCard(),
              const SizedBox(height: 12),
              _buildModeToggle(
                'High Security Mode',
                'Maximum sensor sensitivity, stricter triggers',
                Icons.security_rounded,
                VigilThemeV2.roseEmergency,
                _highSecurity,
                (v) => setState(() => _highSecurity = v),
              ),
              const SizedBox(height: 12),
              _buildModeToggle(
                'Battery Saver Mode',
                'Lower polling rate to save battery',
                Icons.battery_saver_rounded,
                VigilThemeV2.emeraldPulse,
                _batterySaver,
                (v) => setState(() => _batterySaver = v),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _toggleProtection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isActive
                        ? VigilThemeV2.roseEmergency
                        : VigilThemeV2.neonCyan,
                  ),
                  child: Text(
                    _isActive ? 'STOP PROTECTION' : 'ACTIVATE PROTECTION',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: 2),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainToggle() {
    return Center(
      child: Column(
        children: [
          NeonPulse(
            size: 160,
            color: _isActive ? VigilThemeV2.emeraldPulse : VigilThemeV2.textMuted,
            animate: _isActive,
            child: Icon(
              _isActive ? Icons.shield_rounded : Icons.shield_outlined,
              size: 70,
              color: VigilThemeV2.spaceBlack,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isActive ? 'AI MONITORING ACTIVE' : 'PROTECTION OFF',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _isActive ? VigilThemeV2.emeraldPulse : VigilThemeV2.textMuted,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isActive
                ? 'Multi-sensor fusion in real-time'
                : 'Tap below to activate safety',
            style: VigilThemeV2.bodySM,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAIDisplay() {
    final readings = _sensors.getCurrentReadings();
    final pocketConf = _debug?.pocketConfidence ?? 0;
    final threat = _debug?.threatConfidence ?? 0;
    final extraction = _debug?.extractionScore ?? 0;
    final inPocket = _debug?.isInPocket ?? false;
    final movement = _debug?.movementClass ?? MovementClassification.stationary;

    return NeoGlassCard(
      padding: const EdgeInsets.all(18),
      showHoloBorder: true,
      glowColor: VigilThemeV2.violetNeon,
      animateGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_alt_rounded,
                  color: VigilThemeV2.violetNeon, size: 18),
              const SizedBox(width: 8),
              Text('LIVE AI ANALYSIS', style: VigilThemeV2.labelBrand),
              const Spacer(),
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: VigilThemeV2.emeraldPulse,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pocket state
          _liveRow('Phone State', inPocket ? 'IN POCKET' : 'OUT OF POCKET',
              inPocket ? VigilThemeV2.emeraldPulse : VigilThemeV2.amberAlert),
          const SizedBox(height: 8),
          _liveRow('Activity', _movementName(movement), VigilThemeV2.tealGlow),
          const SizedBox(height: 14),

          // Confidence bars
          _confidenceBar('Pocket Confidence', pocketConf, VigilThemeV2.emeraldPulse),
          const SizedBox(height: 8),
          _confidenceBar('Extraction Score', extraction, VigilThemeV2.amberAlert),
          const SizedBox(height: 8),
          _confidenceBar('Threat Level', threat,
              threat > 0.6 ? VigilThemeV2.roseEmergency : VigilThemeV2.violetNeon),
          const SizedBox(height: 14),

          // Raw sensor values
          const Divider(color: VigilThemeV2.borderSubtle, height: 12),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sensorChip('Accel',
                  readings.accelMagnitude.toStringAsFixed(1),
                  VigilThemeV2.neonCyan),
              _sensorChip('Gyro',
                  readings.gyroMagnitude.toStringAsFixed(2),
                  VigilThemeV2.violetNeon),
              _sensorChip('Light',
                  readings.light < 0 ? '—' : readings.light.toStringAsFixed(0),
                  VigilThemeV2.amberAlert),
              _sensorChip('Prox',
                  readings.proximity < 0 ? '—' : readings.proximity.toStringAsFixed(1),
                  VigilThemeV2.tealGlow),
            ],
          ),
        ],
      ),
    );
  }

  String _movementName(MovementClassification c) {
    switch (c) {
      case MovementClassification.stationary: return 'Stationary';
      case MovementClassification.walking: return 'Walking';
      case MovementClassification.running: return 'Running';
      case MovementClassification.vehicle: return 'In Vehicle';
      case MovementClassification.activeUse: return 'Active Use';
      case MovementClassification.suspiciousMotion: return 'Suspicious!';
    }
  }

  Widget _liveRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: VigilThemeV2.textMuted,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ],
    );
  }

  Widget _confidenceBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: VigilThemeV2.textMuted)),
            Text('${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: VigilThemeV2.borderSubtle,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.4), blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sensorChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: VigilThemeV2.caption.copyWith(fontSize: 9)),
      ],
    );
  }

  Widget _buildGracePeriodCard() {
    return NeoGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.timer_rounded, color: VigilThemeV2.neonCyan, size: 18),
            SizedBox(width: 8),
            Text('GRACE PERIOD',
                style: TextStyle(
                  fontSize: 12,
                  color: VigilThemeV2.neonCyan,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                )),
          ]),
          const SizedBox(height: 6),
          Text('Time before alarm triggers after extraction',
              style: VigilThemeV2.caption),
          const SizedBox(height: 14),
          Row(
            children: _graceOptions.map((s) {
              final selected = _gracePeriod == s;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _gracePeriod = s);
                    _coordinator.setGracePeriod(s);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: selected ? VigilThemeV2.shieldGradient : null,
                      color: selected ? null : VigilThemeV2.surfaceDark,
                      border: Border.all(
                        color: selected
                            ? VigilThemeV2.neonCyan
                            : VigilThemeV2.borderSubtle,
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text('${s}s',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? VigilThemeV2.spaceBlack
                                : VigilThemeV2.textSecondary,
                          )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return NeoGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      glowColor: color,
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: VigilThemeV2.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: VigilThemeV2.caption.copyWith(fontSize: 10)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

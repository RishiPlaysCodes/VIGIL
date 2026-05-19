import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';
import '../widgets/guardian_avatar_widget.dart';
import '../services/alert_coordinator_v2.dart';
import '../services/guardian_character_service.dart';
import '../services/ai_sensor_fusion_engine.dart';

/// Premium V2 Dashboard — the home screen of the AI safety guardian.
/// Shows real protection state, AI guardian, threat metrics, quick actions.
class DashboardScreenV2 extends StatefulWidget {
  const DashboardScreenV2({super.key});

  @override
  State<DashboardScreenV2> createState() => _DashboardScreenV2State();
}

class _DashboardScreenV2State extends State<DashboardScreenV2> {
  final AlertCoordinatorV2 _coordinator = AlertCoordinatorV2();
  final GuardianCharacterService _guardianSvc = GuardianCharacterService();

  ProtectionState _state = ProtectionState.inactive;
  bool _isProtectionActive = false;

  @override
  void initState() {
    super.initState();
    // Listen to coordinator state changes
    _coordinator.onStateChange = (state) {
      if (mounted) setState(() => _state = state);
    };
    _state = _coordinator.state;
    _isProtectionActive = _coordinator.isProtectionActive;
  }

  GuardianContext _guardianContextFromState() {
    switch (_state) {
      case ProtectionState.inactive:
        return GuardianContext.idle;
      case ProtectionState.monitoring:
      case ProtectionState.paused:
        return _coordinator.fusionEngine.isInPocket
            ? GuardianContext.pocketDetected
            : GuardianContext.monitoring;
      case ProtectionState.faceVerification:
        return GuardianContext.verifying;
      case ProtectionState.graceCountdown:
        return GuardianContext.extractionDetected;
      case ProtectionState.alarm:
        return GuardianContext.emergency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardian = _guardianSvc.activeGuardian;
    final guardianCtx = _guardianContextFromState();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: VigilThemeV2.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(guardian, guardianCtx),
                const SizedBox(height: 24),

                // Main protection card with guardian
                _buildProtectionCard(guardian, guardianCtx),
                const SizedBox(height: 16),

                // AI status grid
                _buildAIStatusGrid(),
                const SizedBox(height: 16),

                // Quick actions
                Text('QUICK ACTIONS', style: VigilThemeV2.labelBrand),
                const SizedBox(height: 12),
                _buildQuickActions(),
                const SizedBox(height: 16),

                // Recent activity
                Text('RECENT ACTIVITY', style: VigilThemeV2.labelBrand),
                const SizedBox(height: 12),
                _buildRecentActivity(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(GuardianCharacter guardian, GuardianContext ctx) {
    return Row(
      children: [
        // Mini guardian indicator
        GuardianMiniIndicator(guardian: guardian, context: ctx, size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Guardian: ${guardian.name}',
                  style: TextStyle(
                    fontSize: 11,
                    color: guardian.appearance.primaryColor,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 2),
              const HoloText(
                text: 'VIGIL DASHBOARD',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          icon: const Icon(Icons.settings_rounded, color: VigilThemeV2.textSecondary),
        ),
      ],
    );
  }

  Widget _buildProtectionCard(GuardianCharacter guardian, GuardianContext ctx) {
    final isActive = _isProtectionActive;
    final glowColor = isActive ? VigilThemeV2.emeraldPulse : VigilThemeV2.textMuted;

    return NeoGlassCard(
      padding: const EdgeInsets.all(24),
      showHoloBorder: isActive,
      animateGlow: isActive,
      glowColor: glowColor,
      onTap: () => Navigator.pushNamed(context, '/pocket-mode'),
      child: Column(
        children: [
          GuardianAvatarWidget(
            guardian: guardian,
            context: ctx,
            size: 100,
            showMessage: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: glowColor.withOpacity(0.12),
              border: Border.all(color: glowColor.withOpacity(0.3), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: glowColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'PROTECTION ACTIVE' : 'PROTECTION OFF',
                  style: TextStyle(
                    fontSize: 11,
                    color: glowColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIStatusGrid() {
    final fusion = _coordinator.fusionEngine;
    final threat = fusion.threatConfidence;
    return Row(
      children: [
        Expanded(
          child: _miniStat(
            'AI Confidence',
            '${(threat * 100).toStringAsFixed(0)}%',
            Icons.psychology_alt_rounded,
            VigilThemeV2.violetNeon,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
            'In Pocket',
            fusion.isInPocket ? 'YES' : 'NO',
            Icons.security_rounded,
            fusion.isInPocket ? VigilThemeV2.emeraldPulse : VigilThemeV2.textMuted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
            'Activity',
            _movementLabel(fusion.movementClass),
            Icons.directions_run_rounded,
            VigilThemeV2.tealGlow,
          ),
        ),
      ],
    );
  }

  String _movementLabel(MovementClassification c) {
    switch (c) {
      case MovementClassification.stationary: return 'Still';
      case MovementClassification.walking: return 'Walk';
      case MovementClassification.running: return 'Run';
      case MovementClassification.vehicle: return 'Vehicle';
      case MovementClassification.activeUse: return 'In Use';
      case MovementClassification.suspiciousMotion: return 'Alert';
    }
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return NeoGlassCard(
      padding: const EdgeInsets.all(14),
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: VigilThemeV2.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _action('Pocket Mode', Icons.shield_rounded, VigilThemeV2.neonCyan,
                () => Navigator.pushNamed(context, '/pocket-mode'))),
            const SizedBox(width: 10),
            Expanded(child: _action('Contacts', Icons.contacts_rounded, VigilThemeV2.tealGlow,
                () => Navigator.pushNamed(context, '/emergency-contacts'))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _action('Guardian', Icons.auto_awesome_rounded, VigilThemeV2.violetNeon,
                () => Navigator.pushNamed(context, '/guardian-selection'))),
            const SizedBox(width: 10),
            Expanded(child: _action('Alert History', Icons.history_rounded, VigilThemeV2.amberAlert,
                () => Navigator.pushNamed(context, '/alert-history'))),
          ],
        ),
      ],
    );
  }

  Widget _action(String label, IconData icon, Color color, VoidCallback onTap) {
    return NeoGlassCard(
      padding: const EdgeInsets.all(18),
      glowColor: color,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: VigilThemeV2.textPrimary,
              )),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return NeoGlassCard(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.verified_user_rounded,
                size: 40,
                color: VigilThemeV2.emeraldPulse.withOpacity(0.6)),
            const SizedBox(height: 10),
            const Text('All Clear',
                style: TextStyle(
                  fontSize: 14,
                  color: VigilThemeV2.textSecondary,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 2),
            Text('No threats detected',
                style: VigilThemeV2.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF080C1A),
        border: Border(top: BorderSide(color: VigilThemeV2.borderSubtle, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 1: Navigator.pushNamed(context, '/pocket-mode'); break;
            case 2: Navigator.pushNamed(context, '/alert-history'); break;
            case 3: Navigator.pushNamed(context, '/settings'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shield_rounded), label: 'Protect'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

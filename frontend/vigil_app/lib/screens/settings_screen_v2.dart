import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';
import '../widgets/guardian_avatar_widget.dart';
import '../services/multi_layer_auth_service.dart';
import '../services/face_verification_service.dart';
import '../services/guardian_character_service.dart';
import '../services/sensor_manager_v2.dart';

/// Premium Settings V2 with biometric enrollment, guardian selection,
/// false-alarm sensitivity tuning, and full configuration.
class SettingsScreenV2 extends StatefulWidget {
  const SettingsScreenV2({super.key});

  @override
  State<SettingsScreenV2> createState() => _SettingsScreenV2State();
}

class _SettingsScreenV2State extends State<SettingsScreenV2> {
  final MultiLayerAuthService _auth = MultiLayerAuthService();
  final FaceVerificationService _face = FaceVerificationService();
  final GuardianCharacterService _guardian = GuardianCharacterService();
  final SensorManagerV2 _sensors = SensorManagerV2();

  // Settings state
  double _aiSensitivity = 0.6;
  bool _highSecurity = false;
  bool _batterySaver = false;
  bool _locationSharing = true;
  int _requiredAuthMethods = 1;
  String _selectedRingtone = 'Default Alarm';

  @override
  void initState() {
    super.initState();
    _auth.initialize();
    _face.initialize();
    _requiredAuthMethods = _auth.config.requiredMethodCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS',
            style: TextStyle(letterSpacing: 3, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: VigilThemeV2.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Active guardian header
            _buildGuardianHeader(),
            const SizedBox(height: 24),

            // Authentication section
            _section('AUTHENTICATION', VigilThemeV2.violetNeon),
            _navTile(
              'Face Recognition',
              _face.isEnrolled ? 'Enrolled' : 'Not enrolled — tap to setup',
              Icons.face_retouching_natural_rounded,
              VigilThemeV2.violetNeon,
              () => Navigator.pushNamed(context, '/face-enrollment'),
              trailing: _face.isEnrolled
                  ? const Icon(Icons.check_circle_rounded,
                      color: VigilThemeV2.emeraldPulse, size: 20)
                  : null,
            ),
            _switchTile(
              'Fingerprint',
              'Use biometric authentication',
              Icons.fingerprint_rounded,
              VigilThemeV2.tealGlow,
              _auth.config.fingerprintEnabled,
              (v) => setState(() => _auth.setFingerprintEnabled(v)),
            ),
            _navTile(
              'Voice Password',
              _auth.config.voicePasswordEnabled
                  ? 'Phrase enrolled'
                  : 'Set secret phrase like "VIGIL CHUP"',
              Icons.mic_rounded,
              VigilThemeV2.violetNeon,
              () => Navigator.pushNamed(context, '/voice-password'),
              trailing: _auth.config.voicePasswordEnabled
                  ? const Icon(Icons.check_circle_rounded,
                      color: VigilThemeV2.emeraldPulse, size: 20)
                  : null,
            ),
            _navTile(
              'PIN Code',
              _auth.config.pinEnabled ? 'Set' : 'Setup PIN backup',
              Icons.pin_rounded,
              VigilThemeV2.amberAlert,
              _showPinSetupDialog,
              trailing: _auth.config.pinEnabled
                  ? const Icon(Icons.check_circle_rounded,
                      color: VigilThemeV2.emeraldPulse, size: 20)
                  : null,
            ),
            _buildAuthMethodCount(),

            const SizedBox(height: 24),

            // AI Detection section
            _section('AI DETECTION', VigilThemeV2.neonCyan),
            _buildSensitivitySlider(),
            _switchTile(
              'High Security Mode',
              'More sensitive detection',
              Icons.security_rounded,
              VigilThemeV2.roseEmergency,
              _highSecurity,
              (v) {
                setState(() => _highSecurity = v);
                _sensors.setHighSecurityMode(v);
              },
            ),
            _switchTile(
              'Battery Saver Mode',
              'Reduce sensor polling rate',
              Icons.battery_saver_rounded,
              VigilThemeV2.emeraldPulse,
              _batterySaver,
              (v) {
                setState(() => _batterySaver = v);
                _sensors.setBatterySaverMode(v);
              },
            ),

            const SizedBox(height: 24),

            // Customization section
            _section('CUSTOMIZATION', VigilThemeV2.amberAlert),
            _navTile(
              'Guardian Character',
              '${_guardian.activeGuardian.name} — ${_guardian.activeGuardian.title}',
              Icons.auto_awesome_rounded,
              _guardian.activeGuardian.appearance.primaryColor,
              () => Navigator.pushNamed(context, '/guardian-selection')
                  .then((_) => setState(() {})),
            ),
            _navTile(
              'Alert Ringtone',
              _selectedRingtone,
              Icons.music_note_rounded,
              VigilThemeV2.amberAlert,
              _showRingtoneSelector,
            ),

            const SizedBox(height: 24),

            // Privacy & Location
            _section('PRIVACY & LOCATION', VigilThemeV2.tealGlow),
            _switchTile(
              'Location Sharing',
              'Share location during emergencies',
              Icons.location_on_rounded,
              VigilThemeV2.tealGlow,
              _locationSharing,
              (v) => setState(() => _locationSharing = v),
            ),
            _navTile(
              'Emergency Contacts',
              'Manage trusted contacts',
              Icons.contacts_rounded,
              VigilThemeV2.tealGlow,
              () => Navigator.pushNamed(context, '/emergency-contacts'),
            ),

            const SizedBox(height: 24),

            // Account
            _section('ACCOUNT', VigilThemeV2.textMuted),
            NeoGlassCard(
              padding: const EdgeInsets.symmetric(vertical: 14),
              glowColor: VigilThemeV2.roseEmergency,
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (r) => false),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: VigilThemeV2.roseEmergency, size: 18),
                    SizedBox(width: 10),
                    Text('Sign Out',
                        style: TextStyle(
                          color: VigilThemeV2.roseEmergency,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardianHeader() {
    return NeoGlassCard(
      padding: const EdgeInsets.all(20),
      showHoloBorder: true,
      glowColor: _guardian.activeGuardian.appearance.primaryColor,
      animateGlow: true,
      child: Row(
        children: [
          GuardianMiniIndicator(
            guardian: _guardian.activeGuardian,
            context: GuardianContext.greeting,
            size: 56,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_guardian.activeGuardian.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _guardian.activeGuardian.appearance.primaryColor,
                      letterSpacing: 2,
                    )),
                Text(_guardian.activeGuardian.title,
                    style: VigilThemeV2.caption),
                const SizedBox(height: 4),
                Text(
                  '"${_guardian.activeGuardian.personality.defaultMessage}"',
                  style: const TextStyle(
                    fontSize: 11,
                    color: VigilThemeV2.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
      child: Text(title,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          )),
    );
  }

  Widget _switchTile(String title, String subtitle, IconData icon, Color color,
      bool value, ValueChanged<bool> onChanged) {
    return NeoGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      glowColor: color,
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 18),
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

  Widget _navTile(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap,
      {Widget? trailing}) {
    return NeoGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      glowColor: color,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 18),
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
                Text(subtitle,
                    style: VigilThemeV2.caption.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) trailing,
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              color: VigilThemeV2.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildAuthMethodCount() {
    return NeoGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_rounded,
                  color: VigilThemeV2.violetNeon, size: 18),
              const SizedBox(width: 8),
              const Text('REQUIRED AUTH METHODS',
                  style: TextStyle(
                    fontSize: 11,
                    color: VigilThemeV2.violetNeon,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  )),
              const Spacer(),
              Text('$_requiredAuthMethods of 4',
                  style: const TextStyle(
                    color: VigilThemeV2.textPrimary,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Higher count = more secure (slower to disable in real emergency)',
            style: VigilThemeV2.caption.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 10),
          Row(
            children: [1, 2, 3].map((count) {
              final selected = _requiredAuthMethods == count;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _requiredAuthMethods = count);
                    _auth.setRequiredMethodCount(count);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: selected
                          ? const LinearGradient(colors: [
                              VigilThemeV2.violetNeon,
                              VigilThemeV2.fuchsiaPulse,
                            ])
                          : null,
                      color: selected ? null : VigilThemeV2.surfaceDark,
                      border: Border.all(
                        color: selected
                            ? VigilThemeV2.violetNeon
                            : VigilThemeV2.borderSubtle,
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text('$count',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
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

  Widget _buildSensitivitySlider() {
    return NeoGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded,
                  color: VigilThemeV2.neonCyan, size: 18),
              const SizedBox(width: 8),
              const Text('AI SENSITIVITY',
                  style: TextStyle(
                    fontSize: 11,
                    color: VigilThemeV2.neonCyan,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  )),
              const Spacer(),
              Text('${(_aiSensitivity * 100).toInt()}%',
                  style: const TextStyle(
                    color: VigilThemeV2.neonCyan,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _aiSensitivity < 0.4
                ? 'Low — Only triggers on very obvious theft'
                : _aiSensitivity < 0.7
                    ? 'Balanced — Recommended for most users'
                    : 'High — May increase false alarms',
            style: VigilThemeV2.caption.copyWith(fontSize: 10),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: VigilThemeV2.neonCyan,
              inactiveTrackColor: VigilThemeV2.borderSubtle,
              thumbColor: VigilThemeV2.neonCyan,
              overlayColor: VigilThemeV2.neonCyan.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _aiSensitivity,
              min: 0.2,
              max: 0.9,
              onChanged: (v) => setState(() => _aiSensitivity = v),
            ),
          ),
        ],
      ),
    );
  }

  void _showPinSetupDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: VigilThemeV2.cardBase,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HoloText(
              text: 'SET PIN',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                  letterSpacing: 3),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(
                color: VigilThemeV2.textPrimary,
                fontSize: 24,
                letterSpacing: 8,
              ),
              decoration: const InputDecoration(
                hintText: '4-6 digits',
                prefixIcon: Icon(Icons.pin_rounded),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.length >= 4) {
                    _auth.setPin(controller.text);
                    setState(() {});
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('SAVE PIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRingtoneSelector() {
    final ringtones = ['Default Alarm', 'Cyber Siren', 'Emergency', 'Loud Beep', 'Phantom Wail'];
    showModalBottomSheet(
      context: context,
      backgroundColor: VigilThemeV2.cardBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HoloText(
              text: 'SELECT TONE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  letterSpacing: 3),
            ),
            const SizedBox(height: 16),
            ...ringtones.map((r) => ListTile(
                  title: Text(r,
                      style: const TextStyle(color: VigilThemeV2.textPrimary)),
                  leading: Icon(
                    _selectedRingtone == r
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: VigilThemeV2.neonCyan,
                  ),
                  onTap: () {
                    setState(() => _selectedRingtone = r);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

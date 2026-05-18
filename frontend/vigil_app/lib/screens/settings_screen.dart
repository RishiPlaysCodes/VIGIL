import 'package:flutter/material.dart';
import '../theme/vigil_theme.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _batteryMode = false;
  bool _highSecurity = false;
  bool _locationSharing = true;
  bool _continuousSync = true;
  String _selectedRingtone = 'Default Alarm';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: VigilTheme.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection('Security Modes', [
              _buildSwitchTile(
                'High Security Mode',
                'Maximum sensor sensitivity, faster alerts',
                Icons.security_rounded,
                VigilTheme.alertRed,
                _highSecurity,
                (v) => setState(() => _highSecurity = v),
              ),
              _buildSwitchTile(
                'Battery Saver Mode',
                'Reduced sensor polling to save battery',
                Icons.battery_saver_rounded,
                VigilTheme.emerald,
                _batteryMode,
                (v) => setState(() => _batteryMode = v),
              ),
            ]),
            const SizedBox(height: 20),
            _buildSection('Location', [
              _buildSwitchTile(
                'Location Sharing',
                'Share location with trusted contacts during alerts',
                Icons.location_on_outlined,
                VigilTheme.cyan,
                _locationSharing,
                (v) => setState(() => _locationSharing = v),
              ),
              _buildSwitchTile(
                'Continuous Sync',
                'Keep location updated in background',
                Icons.sync_rounded,
                VigilTheme.teal,
                _continuousSync,
                (v) => setState(() => _continuousSync = v),
              ),
            ]),
            const SizedBox(height: 20),
            _buildSection('Alert Customization', [
              _buildNavTile(
                'Custom Ringtone',
                _selectedRingtone,
                Icons.music_note_rounded,
                VigilTheme.purple,
                () => _showRingtoneSelector(),
              ),
              _buildNavTile(
                'Safety Avatar',
                'Choose lock-screen image',
                Icons.face_rounded,
                VigilTheme.warningOrange,
                () {},
              ),
              _buildNavTile(
                'Lock Screen Safety Image',
                'Customize safety check screen',
                Icons.phone_locked_rounded,
                VigilTheme.cyan,
                () {},
              ),
            ]),
            const SizedBox(height: 20),
            _buildSection('Account', [
              _buildNavTile(
                'Emergency Contacts',
                'Manage trusted contacts',
                Icons.contacts_rounded,
                VigilTheme.teal,
                () => Navigator.pushNamed(context, '/emergency-contacts'),
              ),
              _buildNavTile(
                'Permissions',
                'Manage app permissions',
                Icons.admin_panel_settings_outlined,
                VigilTheme.warningOrange,
                () {},
              ),
              _buildNavTile(
                'About Vigil',
                'Version 1.0.0',
                Icons.info_outline_rounded,
                VigilTheme.textGrey,
                () {},
              ),
            ]),
            const SizedBox(height: 20),
            GlassCard(
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
              glowColor: VigilTheme.alertRed,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: VigilTheme.alertRed, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: VigilTheme.alertRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: VigilTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon,
      Color color, bool value, ValueChanged<bool> onChanged) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: VigilTheme.textWhite)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: VigilTheme.textGrey.withOpacity(0.8))),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildNavTile(
      String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: VigilTheme.textWhite)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: VigilTheme.textGrey.withOpacity(0.8))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: VigilTheme.textGrey, size: 20),
        ],
      ),
    );
  }

  void _showRingtoneSelector() {
    final ringtones = ['Default Alarm', 'Siren', 'Emergency', 'Loud Beep', 'Custom'];
    showModalBottomSheet(
      context: context,
      backgroundColor: VigilTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Ringtone',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: VigilTheme.textWhite)),
            const SizedBox(height: 16),
            ...ringtones.map((r) => ListTile(
                  title: Text(r, style: const TextStyle(color: VigilTheme.textWhite)),
                  leading: Icon(
                    _selectedRingtone == r
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: VigilTheme.cyan,
                  ),
                  onTap: () {
                    setState(() => _selectedRingtone = r);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.username,
    required this.securityLevel,
    required this.locationMode,
    required this.verificationMode,
    required this.customRingtoneLabel,
    required this.lockScreenImageLabel,
    required this.safetyAvatar,
    required this.removalGraceSeconds,
    required this.dailySchedule,
    required this.onSecurityLevelChanged,
    required this.onLocationModeChanged,
    required this.onVerificationModeChanged,
    required this.onCustomRingtoneChanged,
    required this.onPreviewRingtone,
    required this.onResetRingtone,
    required this.onLockScreenImageChanged,
    required this.onSafetyAvatarChanged,
    required this.onRemovalGraceChanged,
    required this.onDailyScheduleChanged,
    required this.onRequestLocationPermission,
    required this.onLogout,
  });

  final String username;
  final SecurityLevel securityLevel;
  final LocationMode locationMode;
  final VerificationMode verificationMode;
  final String customRingtoneLabel;
  final String lockScreenImageLabel;
  final SafetyAvatar safetyAvatar;
  final int removalGraceSeconds;
  final DailySchedule dailySchedule;
  final ValueChanged<SecurityLevel> onSecurityLevelChanged;
  final ValueChanged<LocationMode> onLocationModeChanged;
  final ValueChanged<VerificationMode> onVerificationModeChanged;
  final ValueChanged<String> onCustomRingtoneChanged;
  final Future<void> Function() onPreviewRingtone;
  final Future<void> Function() onResetRingtone;
  final ValueChanged<String> onLockScreenImageChanged;
  final ValueChanged<SafetyAvatar> onSafetyAvatarChanged;
  final ValueChanged<int> onRemovalGraceChanged;
  final ValueChanged<DailySchedule> onDailyScheduleChanged;
  final Future<void> Function() onRequestLocationPermission;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF111827), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protection Center',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tune security, battery, sharing, and alarms your way.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Profile',
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(child: Text(username)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Daily Schedule',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-enable Pocket Mode'),
                  subtitle: Text('Daily ${dailySchedule.windowLabel}'),
                  value: dailySchedule.enabled,
                  onChanged: (enabled) {
                    onDailyScheduleChanged(
                      DailySchedule(
                        startHour: dailySchedule.startHour,
                        startMinute: dailySchedule.startMinute,
                        endHour: dailySchedule.endHour,
                        endMinute: dailySchedule.endMinute,
                        enabled: enabled,
                      ),
                    );
                  },
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: dailySchedule.startHour,
                        minute: dailySchedule.startMinute,
                      ),
                    );
                    if (picked != null) {
                      onDailyScheduleChanged(
                        DailySchedule(
                          startHour: picked.hour,
                          startMinute: picked.minute,
                          endHour: dailySchedule.endHour,
                          endMinute: dailySchedule.endMinute,
                          enabled: dailySchedule.enabled,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.schedule),
                  label: const Text('Choose start time'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: dailySchedule.endHour,
                        minute: dailySchedule.endMinute,
                      ),
                    );
                    if (picked != null) {
                      onDailyScheduleChanged(
                        DailySchedule(
                          startHour: dailySchedule.startHour,
                          startMinute: dailySchedule.startMinute,
                          endHour: picked.hour,
                          endMinute: picked.minute,
                          enabled: dailySchedule.enabled,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.lock_clock_outlined),
                  label: const Text('Choose end time'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Protection Profile',
            child: Column(
              children: [
                DropdownButtonFormField<SecurityLevel>(
                  initialValue: securityLevel,
                  decoration: const InputDecoration(labelText: 'Battery / security mode'),
                  items: const [
                    DropdownMenuItem(
                      value: SecurityLevel.saver,
                      child: Text('Battery Saver'),
                    ),
                    DropdownMenuItem(
                      value: SecurityLevel.balanced,
                      child: Text('Balanced'),
                    ),
                    DropdownMenuItem(
                      value: SecurityLevel.highSecurity,
                      child: Text('High Security'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onSecurityLevelChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LocationMode>(
                  initialValue: locationMode,
                  decoration: const InputDecoration(labelText: 'Location sharing'),
                  items: const [
                    DropdownMenuItem(
                      value: LocationMode.alertOnly,
                      child: Text('Only on alert'),
                    ),
                    DropdownMenuItem(
                      value: LocationMode.travelWindow,
                      child: Text('During travel schedule'),
                    ),
                    DropdownMenuItem(
                      value: LocationMode.whilePocketModeOn,
                      child: Text('While Pocket Mode is ON'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onLocationModeChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onRequestLocationPermission,
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Enable location permission'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: removalGraceSeconds,
                  decoration: const InputDecoration(
                    labelText: 'Grace after phone leaves pocket',
                  ),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3 seconds')),
                    DropdownMenuItem(value: 5, child: Text('5 seconds')),
                    DropdownMenuItem(value: 10, child: Text('10 seconds')),
                    DropdownMenuItem(value: 20, child: Text('20 seconds')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onRemovalGraceChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<VerificationMode>(
                  initialValue: verificationMode,
                  decoration: const InputDecoration(labelText: 'Verification'),
                  items: const [
                    DropdownMenuItem(
                      value: VerificationMode.pinOnly,
                      child: Text('PIN only'),
                    ),
                    DropdownMenuItem(
                      value: VerificationMode.biometricAndPin,
                      child: Text('Biometric + PIN'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onVerificationModeChanged(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: 'Theme',
            child: Text(
              'Pocket Guardian automatically follows your phone theme, including dark mode.',
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Alarm Sound',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(customRingtoneLabel),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.audio,
                    );
                    final name = result?.files.single.name;
                    final path = result?.files.single.path;
                    if (name != null && path != null) {
                      onCustomRingtoneChanged('$name|$path');
                    }
                  },
                  icon: const Icon(Icons.music_note_outlined),
                  label: const Text('Choose custom ringtone'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPreviewRingtone,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Preview'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onResetRingtone,
                        icon: const Icon(Icons.restore),
                        label: const Text('Use default'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Lock Screen Image',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  children: SafetyAvatar.values
                      .map(
                        (avatar) => ChoiceChip(
                          label: Text(avatar.label),
                          selected: avatar == safetyAvatar,
                          onSelected: (_) => onSafetyAvatarChanged(avatar),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(lockScreenImageLabel),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.image,
                    );
                    final name = result?.files.single.name;
                    final path = result?.files.single.path;
                    if (name != null && path != null) {
                      onLockScreenImageChanged('$name|$path');
                      onSafetyAvatarChanged(SafetyAvatar.custom);
                    }
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Choose lock-screen image'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: 'Safety Notes',
            child: Text(
              'Camera, location, and background permissions require clear consent. '
              'Police are not auto-contacted in this MVP.',
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Account',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

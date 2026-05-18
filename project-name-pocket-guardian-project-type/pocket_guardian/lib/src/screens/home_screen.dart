import 'package:flutter/material.dart';

import '../widgets/section_card.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.pocketModeEnabled,
    required this.isCountingDown,
    required this.alarmActive,
    required this.secondsRemaining,
    required this.autoActivationMinutes,
    required this.statusMessage,
    required this.lastKnownLocation,
    required this.intruderPhotoStatus,
    required this.pinController,
    required this.onTogglePocketMode,
    required this.onSmallShake,
    required this.onStrongMovement,
    required this.onScreenWake,
    required this.onCancelWithPin,
    required this.onResetAlarm,
    required this.onScheduleAutoActivation,
    required this.onCancelAutoActivation,
  });

  final bool pocketModeEnabled;
  final bool isCountingDown;
  final bool alarmActive;
  final int secondsRemaining;
  final int? autoActivationMinutes;
  final String statusMessage;
  final String lastKnownLocation;
  final String intruderPhotoStatus;
  final TextEditingController pinController;
  final ValueChanged<bool> onTogglePocketMode;
  final VoidCallback onSmallShake;
  final VoidCallback onStrongMovement;
  final VoidCallback onScreenWake;
  final Future<void> Function() onCancelWithPin;
  final VoidCallback onResetAlarm;
  final ValueChanged<int> onScheduleAutoActivation;
  final VoidCallback onCancelAutoActivation;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.shield_moon_outlined,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pocket Guardian',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Smart protection for travel, theft, and emergencies',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: _StatusCard(
            pocketModeEnabled: pocketModeEnabled,
            isCountingDown: isCountingDown,
            alarmActive: alarmActive,
            secondsRemaining: secondsRemaining,
            statusMessage: statusMessage,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.timer_outlined,
                  label: 'Travel timer',
                  value: autoActivationMinutes == null
                      ? 'Off'
                      : '${autoActivationMinutes}m',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: lastKnownLocation == 'Location not captured yet'
                      ? 'Ready'
                      : 'Live',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Pocket Mode',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Pocket Mode'),
                  subtitle: const Text('Motion monitoring is active on device.'),
                  value: pocketModeEnabled,
                  onChanged: onTogglePocketMode,
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: pocketModeEnabled ? onSmallShake : null,
                      icon: const Icon(Icons.vibration),
                      label: const Text('Small shake'),
                    ),
                    OutlinedButton.icon(
                      onPressed: pocketModeEnabled ? onStrongMovement : null,
                      icon: const Icon(Icons.directions_walk),
                      label: const Text('Strong movement'),
                    ),
                    OutlinedButton.icon(
                      onPressed: pocketModeEnabled ? onScreenWake : null,
                      icon: const Icon(Icons.power_settings_new),
                      label: const Text('Screen wake'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Travel Timer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  autoActivationMinutes == null
                      ? 'Schedule automatic protection before your trip starts.'
                      : 'Auto-activation in $autoActivationMinutes minute${autoActivationMinutes == 1 ? '' : 's'}.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: () => onScheduleAutoActivation(1),
                      child: const Text('1 min'),
                    ),
                    OutlinedButton(
                      onPressed: () => onScheduleAutoActivation(5),
                      child: const Text('5 min'),
                    ),
                    OutlinedButton(
                      onPressed: () => onScheduleAutoActivation(15),
                      child: const Text('15 min'),
                    ),
                    if (autoActivationMinutes != null)
                      TextButton(
                        onPressed: onCancelAutoActivation,
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isCountingDown) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Confirm It Is You',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Enter your PIN before the countdown ends.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      hintText: 'Use 1234 in demo',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onCancelWithPin,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Cancel alert'),
                  ),
                ],
              ),
            ),
          ],
          if (alarmActive) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Emergency Alert',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Location: $lastKnownLocation\n'
                    'Photo: $intruderPhotoStatus',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onResetAlarm,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                    ),
                    icon: const Icon(Icons.notifications_off_outlined),
                    label: const Text('Stop alarm'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.pocketModeEnabled,
    required this.isCountingDown,
    required this.alarmActive,
    required this.secondsRemaining,
    required this.statusMessage,
  });

  final bool pocketModeEnabled;
  final bool isCountingDown;
  final bool alarmActive;
  final int secondsRemaining;
  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = alarmActive
        ? const Color(0xFFFEE2E2)
        : isCountingDown
            ? const Color(0xFFFEF3C7)
            : pocketModeEnabled
                ? const Color(0xFFCCFBF1)
                : const Color(0xFFE2E8F0);
    final icon = alarmActive
        ? Icons.warning_amber_rounded
        : isCountingDown
            ? Icons.timer_outlined
            : pocketModeEnabled
                ? Icons.shield_outlined
                : Icons.shield_moon_outlined;

    return Card(
      color: backgroundColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.white, child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarmActive
                        ? 'Alarm triggered'
                        : isCountingDown
                            ? 'Verification needed'
                            : pocketModeEnabled
                                ? 'Protection active'
                                : 'Protection inactive',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(statusMessage),
                ],
              ),
            ),
            if (isCountingDown)
              Text(
                '$secondsRemaining s',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
          ],
        ),
      ),
    );
  }
}

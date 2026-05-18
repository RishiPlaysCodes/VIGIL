import 'package:flutter/material.dart';
import '../theme/vigil_theme.dart';
import '../widgets/glass_card.dart';

class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
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
            _buildSummaryCards(),
            const SizedBox(height: 24),
            const Text(
              'Recent Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VigilTheme.textWhite,
              ),
            ),
            const SizedBox(height: 12),
            _buildAlertItem(
              'Pocket Removal Detected',
              'Cancelled by owner',
              '2 hours ago',
              Icons.check_circle,
              VigilTheme.emerald,
            ),
            _buildAlertItem(
              'Motion Alert Triggered',
              'False alarm - bus brake',
              'Yesterday',
              Icons.info_outline,
              VigilTheme.warningOrange,
            ),
            _buildAlertItem(
              'Emergency Alert Sent',
              'Location shared with contacts',
              '3 days ago',
              Icons.warning_amber_rounded,
              VigilTheme.alertRed,
            ),
            _buildAlertItem(
              'Pocket Removal Detected',
              'Cancelled by owner',
              '5 days ago',
              Icons.check_circle,
              VigilTheme.emerald,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            glowColor: VigilTheme.warningOrange,
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: VigilTheme.warningOrange, size: 28),
                const SizedBox(height: 8),
                const Text('4',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: VigilTheme.warningOrange)),
                Text('Total Alerts',
                    style: TextStyle(
                        fontSize: 11,
                        color: VigilTheme.textGrey.withOpacity(0.8))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            glowColor: VigilTheme.emerald,
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: VigilTheme.emerald, size: 28),
                const SizedBox(height: 8),
                const Text('3',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: VigilTheme.emerald)),
                Text('Resolved',
                    style: TextStyle(
                        fontSize: 11,
                        color: VigilTheme.textGrey.withOpacity(0.8))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            glowColor: VigilTheme.alertRed,
            child: Column(
              children: [
                const Icon(Icons.notifications_active_outlined,
                    color: VigilTheme.alertRed, size: 28),
                const SizedBox(height: 8),
                const Text('1',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: VigilTheme.alertRed)),
                Text('Sent',
                    style: TextStyle(
                        fontSize: 11,
                        color: VigilTheme.textGrey.withOpacity(0.8))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(
      String title, String subtitle, String time, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: VigilTheme.textWhite)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: VigilTheme.textGrey.withOpacity(0.8))),
              ],
            ),
          ),
          Text(time,
              style: TextStyle(
                  fontSize: 11, color: VigilTheme.textGrey.withOpacity(0.6))),
        ],
      ),
    );
  }
}

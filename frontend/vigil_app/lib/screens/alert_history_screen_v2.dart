import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';
import '../services/api_service.dart';

class AlertHistoryScreenV2 extends StatefulWidget {
  const AlertHistoryScreenV2({super.key});

  @override
  State<AlertHistoryScreenV2> createState() => _AlertHistoryScreenV2State();
}

class _AlertHistoryScreenV2State extends State<AlertHistoryScreenV2> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getAlertHistory();
      if (!mounted) return;
      setState(() {
        _alerts = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ALERT HISTORY',
            style: TextStyle(letterSpacing: 3, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: VigilThemeV2.backgroundGradient),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: VigilThemeV2.neonCyan))
            : RefreshIndicator(
                onRefresh: _loadAlerts,
                color: VigilThemeV2.neonCyan,
                backgroundColor: VigilThemeV2.cardBase,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    Text('RECENT ALERTS', style: VigilThemeV2.labelBrand),
                    const SizedBox(height: 12),
                    if (_alerts.isEmpty)
                      _emptyState()
                    else
                      ..._alerts.map((a) => _alertCard(a)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _alerts.length;
    final cancelled = _alerts.where((a) =>
        a['status'] == 'face_verified' || a['status'] == 'auth_cancelled').length;
    final emergency = _alerts.where((a) => a['emergency_activated'] == true).length;

    return Row(
      children: [
        Expanded(
          child: _statCard('Total', total.toString(),
              Icons.warning_amber_rounded, VigilThemeV2.amberAlert),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard('Verified', cancelled.toString(),
              Icons.verified_rounded, VigilThemeV2.emeraldPulse),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard('Emergency', emergency.toString(),
              Icons.crisis_alert_rounded, VigilThemeV2.roseEmergency),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return NeoGlassCard(
      padding: const EdgeInsets.all(14),
      glowColor: color,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              )),
          Text(label, style: VigilThemeV2.caption),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return NeoGlassCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.shield_rounded,
              size: 56,
              color: VigilThemeV2.emeraldPulse.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('All Clear',
              style: TextStyle(
                fontSize: 16,
                color: VigilThemeV2.textPrimary,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 4),
          Text('No alerts in history',
              style: VigilThemeV2.caption),
        ],
      ),
    );
  }

  Widget _alertCard(Map<String, dynamic> a) {
    final status = a['status'] ?? 'triggered';
    final triggerType = a['trigger_type'] ?? 'pocket_removal';
    final triggeredAt = a['triggered_at'] ?? '';
    final confidence = (a['threat_confidence'] as num?)?.toDouble() ?? 0;

    Color color;
    IconData icon;
    String statusText;

    switch (status) {
      case 'face_verified':
        color = VigilThemeV2.emeraldPulse;
        icon = Icons.face_retouching_natural_rounded;
        statusText = 'Auto-cancelled by face';
        break;
      case 'auth_cancelled':
        color = VigilThemeV2.tealGlow;
        icon = Icons.verified_user_rounded;
        statusText = 'Verified by ${a['auth_method_used'] ?? "auth"}';
        break;
      case 'false_alarm':
        color = VigilThemeV2.amberAlert;
        icon = Icons.info_outline_rounded;
        statusText = 'Marked false alarm';
        break;
      case 'emergency_active':
      case 'resolved':
        color = VigilThemeV2.roseEmergency;
        icon = Icons.crisis_alert_rounded;
        statusText = 'Emergency triggered';
        break;
      default:
        color = VigilThemeV2.textMuted;
        icon = Icons.warning_amber_rounded;
        statusText = status;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeoGlassCard(
        padding: const EdgeInsets.all(14),
        glowColor: color,
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color.withOpacity(0.15),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_triggerName(triggerType),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: VigilThemeV2.textPrimary,
                      )),
                  Text(statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(_relativeTime(triggeredAt),
                      style: VigilThemeV2.caption.copyWith(fontSize: 10)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: VigilThemeV2.violetNeon.withOpacity(0.12),
              ),
              child: Text('${(confidence * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: VigilThemeV2.violetNeon,
                    fontWeight: FontWeight.w800,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  String _triggerName(String t) {
    switch (t) {
      case 'ai_extraction': return 'AI Extraction Detected';
      case 'pocket_removal': return 'Pocket Removal';
      case 'manual_sos': return 'Manual SOS';
      case 'schedule': return 'Scheduled Check';
      case 'geofence': return 'Geofence Exit';
      default: return t;
    }
  }

  String _relativeTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return iso;
    }
  }
}

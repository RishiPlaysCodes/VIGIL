import 'package:flutter/material.dart';
import '../theme/vigil_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/vigil_button.dart';

class PocketModeScreen extends StatefulWidget {
  const PocketModeScreen({super.key});

  @override
  State<PocketModeScreen> createState() => _PocketModeScreenState();
}

class _PocketModeScreenState extends State<PocketModeScreen>
    with SingleTickerProviderStateMixin {
  bool _pocketModeActive = false;
  int _gracePeriod = 3;
  bool _scheduleEnabled = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<int> _graceOptions = [3, 5, 10, 20];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _togglePocketMode() {
    setState(() {
      _pocketModeActive = !_pocketModeActive;
      if (_pocketModeActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: VigilTheme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildMainToggle(),
              const SizedBox(height: 30),
              _buildGracePeriodSelector(),
              const SizedBox(height: 20),
              _buildScheduleCard(),
              const SizedBox(height: 20),
              _buildSensorInfo(),
              const SizedBox(height: 30),
              _buildActivateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainToggle() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pocketModeActive ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _togglePocketMode,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _pocketModeActive
                    ? VigilTheme.primaryGradient
                    : const LinearGradient(
                        colors: [Color(0xFF2A2F4A), Color(0xFF1A1F3A)]),
                boxShadow: [
                  if (_pocketModeActive)
                    BoxShadow(
                      color: VigilTheme.cyan.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _pocketModeActive
                        ? Icons.shield_rounded
                        : Icons.shield_outlined,
                    size: 50,
                    color: _pocketModeActive
                        ? VigilTheme.deepNavy
                        : VigilTheme.textGrey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pocketModeActive ? 'ACTIVE' : 'OFF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _pocketModeActive
                          ? VigilTheme.deepNavy
                          : VigilTheme.textGrey,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGracePeriodSelector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timer_outlined, color: VigilTheme.cyan, size: 22),
              SizedBox(width: 10),
              Text(
                'Grace Period',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VigilTheme.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Time before alarm triggers after phone leaves pocket',
            style: TextStyle(
              fontSize: 12,
              color: VigilTheme.textGrey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: _graceOptions.map((seconds) {
              final isSelected = _gracePeriod == seconds;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gracePeriod = seconds),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: isSelected ? VigilTheme.primaryGradient : null,
                      color: isSelected ? null : VigilTheme.divider,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: VigilTheme.cyan.withOpacity(0.3),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${seconds}s',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? VigilTheme.deepNavy
                              : VigilTheme.textGrey,
                        ),
                      ),
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

  Widget _buildScheduleCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule_rounded, color: VigilTheme.purple, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Daily Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VigilTheme.textWhite,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _scheduleEnabled,
                onChanged: (v) => setState(() => _scheduleEnabled = v),
              ),
            ],
          ),
          if (_scheduleEnabled) ...[
            const SizedBox(height: 12),
            Text(
              'Auto-activate during your travel window',
              style: TextStyle(
                fontSize: 12,
                color: VigilTheme.textGrey.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector('Start', '08:00 AM'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector('End', '09:30 AM'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label, String time) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: VigilTheme.divider,
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: VigilTheme.textGrey)),
          const SizedBox(height: 6),
          Text(
            time,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: VigilTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorInfo() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sensors_rounded, color: VigilTheme.emerald, size: 22),
              SizedBox(width: 10),
              Text(
                'Smart Detection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VigilTheme.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSensorRow(Icons.near_me, 'Proximity Sensor', true),
          _buildSensorRow(Icons.light_mode_outlined, 'Light Sensor', true),
          _buildSensorRow(Icons.vibration, 'Motion Sensor', true),
          const SizedBox(height: 8),
          Text(
            'All 3 sensors combine to detect pocket removal and reduce false alarms.',
            style: TextStyle(
              fontSize: 11,
              color: VigilTheme.textGrey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorRow(IconData icon, String name, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: active ? VigilTheme.emerald : VigilTheme.textGrey, size: 20),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(color: VigilTheme.textWhite, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: (active ? VigilTheme.emerald : VigilTheme.textGrey).withOpacity(0.15),
            ),
            child: Text(
              active ? 'Active' : 'Off',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: active ? VigilTheme.emerald : VigilTheme.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivateButton() {
    return VigilButton(
      text: _pocketModeActive ? 'Deactivate Pocket Mode' : 'Activate Pocket Mode',
      onPressed: _togglePocketMode,
      color: _pocketModeActive ? VigilTheme.alertRed : VigilTheme.cyan,
      icon: _pocketModeActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
    );
  }
}

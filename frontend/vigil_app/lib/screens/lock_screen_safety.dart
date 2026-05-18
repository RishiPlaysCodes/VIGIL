import 'package:flutter/material.dart';
import '../theme/vigil_theme.dart';
import '../widgets/vigil_button.dart';

/// The safety lock screen shown when phone is removed from pocket
/// and grace period expires. Asks "Are you safe?" and allows owner to cancel.
class LockScreenSafety extends StatefulWidget {
  const LockScreenSafety({super.key});

  @override
  State<LockScreenSafety> createState() => _LockScreenSafetyState();
}

class _LockScreenSafetyState extends State<LockScreenSafety>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  late Animation<double> _pulseAnimation;
  int _countdown = 10;
  bool _alarmTriggered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _countdownController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..addListener(() {
        final newCount = 10 - (_countdownController.value * 10).floor();
        if (newCount != _countdown) {
          setState(() => _countdown = newCount);
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _alarmTriggered = true);
        }
      });
    _countdownController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _cancelAlarm() {
    _countdownController.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _alarmTriggered
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2D0000), Color(0xFF0A0000)],
                )
              : VigilTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Shield / Warning
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _alarmTriggered
                              ? VigilTheme.alertGradient
                              : VigilTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: (_alarmTriggered
                                      ? VigilTheme.alertRed
                                      : VigilTheme.cyan)
                                  .withOpacity(0.5),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          _alarmTriggered
                              ? Icons.warning_rounded
                              : Icons.shield_rounded,
                          size: 60,
                          color: _alarmTriggered
                              ? Colors.white
                              : VigilTheme.deepNavy,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                // Safety Avatar placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VigilTheme.cyan.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.face_rounded,
                    size: 40,
                    color: VigilTheme.cyan,
                  ),
                ),
                const SizedBox(height: 30),
                // Main question
                Text(
                  _alarmTriggered ? 'ALARM ACTIVE' : 'Are You Safe?',
                  style: TextStyle(
                    fontSize: _alarmTriggered ? 28 : 32,
                    fontWeight: FontWeight.w800,
                    color: _alarmTriggered
                        ? VigilTheme.alertRed
                        : VigilTheme.textWhite,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _alarmTriggered
                      ? 'Emergency alert sent to your contacts.\nLocation is being shared.'
                      : 'Your phone was removed from your pocket.\nTap below to confirm you are safe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: VigilTheme.textGrey.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Countdown
                if (!_alarmTriggered) ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: VigilTheme.alertRed, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        '$_countdown',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: VigilTheme.alertRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Alarm in $_countdown seconds',
                    style: TextStyle(
                      fontSize: 13,
                      color: VigilTheme.alertRed.withOpacity(0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                // Cancel button
                VigilButton(
                  text: _alarmTriggered ? 'Stop Alarm - I Am Safe' : 'I Am Safe - Cancel',
                  onPressed: _cancelAlarm,
                  color: _alarmTriggered ? VigilTheme.emerald : VigilTheme.cyan,
                  icon: Icons.check_circle_rounded,
                ),
                if (_alarmTriggered) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Loud alarm is ringing. Location shared.',
                    style: TextStyle(
                      fontSize: 12,
                      color: VigilTheme.alertRed.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

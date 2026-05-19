import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';
import '../services/face_verification_service.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  final FaceVerificationService _face = FaceVerificationService();
  bool _enrolling = false;
  String _statusMsg = '';

  Future<void> _startEnrollment() async {
    setState(() {
      _enrolling = true;
      _statusMsg = 'Initializing camera...';
    });

    await _face.initialize();
    setState(() => _statusMsg = 'Capturing face from multiple angles...');

    final result = await _face.enrollFace();

    if (!mounted) return;
    setState(() {
      _enrolling = false;
      _statusMsg = result.message;
    });

    if (result.success) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FACE ENROLLMENT',
            style: TextStyle(letterSpacing: 3, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: VigilThemeV2.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 30),
                NeonPulse(
                  size: 140,
                  color: VigilThemeV2.violetNeon,
                  animate: _enrolling,
                  child: const Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 72,
                    color: VigilThemeV2.spaceBlack,
                  ),
                ),
                const SizedBox(height: 30),
                const HoloText(
                  text: 'TEACH YOUR GUARDIAN',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Look at the camera so Vigil can recognize you in emergencies',
                  textAlign: TextAlign.center,
                  style: VigilThemeV2.bodySM,
                ),
                const SizedBox(height: 30),

                NeoGlassCard(
                  padding: const EdgeInsets.all(18),
                  showHoloBorder: true,
                  glowColor: VigilThemeV2.violetNeon,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOW IT WORKS', style: VigilThemeV2.labelBrand.copyWith(
                          color: VigilThemeV2.violetNeon)),
                      const SizedBox(height: 12),
                      _step(1, 'Camera captures 5 frames at different angles'),
                      _step(2, 'AI builds a unique face signature on-device'),
                      _step(3, 'Liveness check ensures it\'s a real face'),
                      _step(4, 'Stored encrypted — never leaves your phone'),
                    ],
                  ),
                ),
                const Spacer(),
                if (_statusMsg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_statusMsg,
                        style: VigilThemeV2.caption,
                        textAlign: TextAlign.center),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _enrolling ? null : _startEnrollment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VigilThemeV2.violetNeon,
                    ),
                    child: _enrolling
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: VigilThemeV2.spaceBlack,
                            ))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded, size: 20),
                              SizedBox(width: 10),
                              Text('START ENROLLMENT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  )),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VigilThemeV2.violetNeon.withOpacity(0.15),
              border: Border.all(color: VigilThemeV2.violetNeon, width: 1),
            ),
            child: Center(
              child: Text('$num',
                  style: const TextStyle(
                    color: VigilThemeV2.violetNeon,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  )),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                  fontSize: 12,
                  color: VigilThemeV2.textSecondary,
                  height: 1.4,
                )),
          ),
        ],
      ),
    );
  }
}

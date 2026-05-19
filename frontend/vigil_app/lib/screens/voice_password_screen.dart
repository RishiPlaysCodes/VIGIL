import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';
import '../services/multi_layer_auth_service.dart';

class VoicePasswordScreen extends StatefulWidget {
  const VoicePasswordScreen({super.key});

  @override
  State<VoicePasswordScreen> createState() => _VoicePasswordScreenState();
}

class _VoicePasswordScreenState extends State<VoicePasswordScreen>
    with SingleTickerProviderStateMixin {
  final MultiLayerAuthService _auth = MultiLayerAuthService();
  final _phraseController = TextEditingController(text: 'VIGIL CHUP');
  bool _enrolling = false;
  String _status = '';
  int _recordingCount = 0;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _phraseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _startEnrollment() async {
    if (_phraseController.text.trim().isEmpty) return;
    setState(() {
      _enrolling = true;
      _recordingCount = 0;
      _status = 'Get ready... say your phrase 3 times';
    });
    _waveController.repeat(reverse: true);

    final result = await _auth.enrollVoicePassword(_phraseController.text.trim());

    if (!mounted) return;
    _waveController.stop();
    setState(() {
      _enrolling = false;
      _recordingCount = result.recordingsCompleted;
      _status = result.message;
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
        title: const Text('VOICE PASSWORD',
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
                const SizedBox(height: 24),

                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_enrolling) ...[
                          _buildWave(140 + 30 * _waveController.value,
                              VigilThemeV2.violetNeon.withOpacity(0.3)),
                          _buildWave(110 + 20 * _waveController.value,
                              VigilThemeV2.violetNeon.withOpacity(0.5)),
                        ],
                        const NeonPulse(
                          size: 100,
                          color: VigilThemeV2.violetNeon,
                          animate: false,
                          child: Icon(Icons.mic_rounded,
                              size: 50, color: VigilThemeV2.spaceBlack),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                const HoloText(
                  text: 'SECRET PHRASE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a unique phrase like "VIGIL CHUP". You\'ll say it to disable alerts.',
                  textAlign: TextAlign.center,
                  style: VigilThemeV2.bodySM,
                ),
                const SizedBox(height: 24),

                NeoGlassCard(
                  padding: const EdgeInsets.all(18),
                  glowColor: VigilThemeV2.violetNeon,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR PHRASE', style: VigilThemeV2.labelBrand.copyWith(
                          color: VigilThemeV2.violetNeon)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phraseController,
                        style: const TextStyle(
                          color: VigilThemeV2.textPrimary,
                          fontSize: 18,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g., VIGIL CHUP',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                NeoGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security_rounded,
                              color: VigilThemeV2.tealGlow, size: 16),
                          const SizedBox(width: 8),
                          Text('SECURITY',
                              style: VigilThemeV2.labelBrand.copyWith(
                                color: VigilThemeV2.tealGlow,
                                fontSize: 11,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vigil checks BOTH the phrase AND your unique voiceprint. An intruder who knows the phrase still can\'t disable alarms — their voice won\'t match.',
                        style: TextStyle(
                          fontSize: 12,
                          color: VigilThemeV2.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_enrolling || _status.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Recordings: $_recordingCount / 3',
                      style: VigilThemeV2.caption.copyWith(
                          color: VigilThemeV2.violetNeon)),
                  const SizedBox(height: 4),
                  Text(_status,
                      textAlign: TextAlign.center,
                      style: VigilThemeV2.caption),
                ],

                const Spacer(),
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
                              Icon(Icons.mic_rounded, size: 20),
                              SizedBox(width: 10),
                              Text('RECORD VOICE',
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

  Widget _buildWave(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

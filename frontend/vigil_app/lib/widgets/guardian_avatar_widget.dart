import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../services/guardian_character_service.dart';

/// Animated Guardian Avatar Widget.
///
/// Renders the AI safety character with:
/// - Animated breathing/pulsing effect
/// - Context-aware animations (scanning, alert, combat)
/// - Particle effects based on guardian style
/// - Glow intensity matching guardian personality
/// - Message bubble with contextual text
class GuardianAvatarWidget extends StatefulWidget {
  final GuardianCharacter guardian;
  final GuardianContext context;
  final double size;
  final bool showMessage;
  final bool showParticles;

  const GuardianAvatarWidget({
    super.key,
    required this.guardian,
    this.context = GuardianContext.idle,
    this.size = 120,
    this.showMessage = true,
    this.showParticles = true,
  });

  @override
  State<GuardianAvatarWidget> createState() => _GuardianAvatarWidgetState();
}

class _GuardianAvatarWidgetState extends State<GuardianAvatarWidget>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _rotateController;
  late AnimationController _glowController;
  late Animation<double> _breatheAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _updateAnimationSpeed();
  }

  void _updateAnimationSpeed() {
    // Adjust animation speed based on context
    switch (widget.context) {
      case GuardianContext.emergency:
        _breatheController.duration = const Duration(milliseconds: 500);
        _glowController.duration = const Duration(milliseconds: 800);
        break;
      case GuardianContext.extractionDetected:
      case GuardianContext.verifying:
        _breatheController.duration = const Duration(milliseconds: 1000);
        break;
      case GuardianContext.monitoring:
        _breatheController.duration = const Duration(seconds: 2);
        break;
      default:
        _breatheController.duration = const Duration(seconds: 3);
    }
  }

  @override
  void didUpdateWidget(covariant GuardianAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.context != widget.context) {
      _updateAnimationSpeed();
    }
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = widget.guardian.appearance;
    final isEmergency = widget.context == GuardianContext.emergency;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        AnimatedBuilder(
          animation: Listenable.merge([_breatheController, _glowController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _breatheAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      appearance.primaryColor,
                      appearance.secondaryColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isEmergency
                              ? VigilThemeV2.roseEmergency
                              : appearance.primaryColor)
                          .withOpacity(_glowAnimation.value *
                              appearance.glowIntensity),
                      blurRadius: 30,
                      spreadRadius: -5,
                    ),
                    BoxShadow(
                      color: appearance.primaryColor.withOpacity(0.2),
                      blurRadius: 50,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating outer ring
                    if (widget.context != GuardianContext.idle)
                      AnimatedBuilder(
                        animation: _rotateController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateAnimation.value,
                            child: Container(
                              width: widget.size - 8,
                              height: widget.size - 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: appearance.accentColor.withOpacity(0.3),
                                  width: 1.5,
                                  strokeAlign: BorderSide.strokeAlignInside,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    // Center icon
                    Icon(
                      appearance.iconData,
                      size: widget.size * 0.4,
                      color: VigilThemeV2.spaceBlack,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Guardian name
        const SizedBox(height: 12),
        Text(
          widget.guardian.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: appearance.primaryColor,
            letterSpacing: 2,
          ),
        ),
        Text(
          widget.guardian.title,
          style: VigilThemeV2.caption.copyWith(fontSize: 11),
        ),

        // Message bubble
        if (widget.showMessage) ...[
          const SizedBox(height: 16),
          _buildMessageBubble(),
        ],
      ],
    );
  }

  Widget _buildMessageBubble() {
    final message = widget.guardian.getContextualMessage(widget.context);
    if (message.text.isEmpty) return const SizedBox.shrink();

    final appearance = widget.guardian.appearance;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: VigilThemeV2.surfaceDark,
        border: Border.all(
          color: appearance.primaryColor.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Text(
        message.text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: VigilThemeV2.textSecondary,
          height: 1.4,
          fontStyle: widget.guardian.personality.tone == 'mysterious'
              ? FontStyle.italic
              : FontStyle.normal,
        ),
      ),
    );
  }
}

/// Compact guardian indicator for headers/status bars
class GuardianMiniIndicator extends StatelessWidget {
  final GuardianCharacter guardian;
  final GuardianContext context;
  final double size;

  const GuardianMiniIndicator({
    super.key,
    required this.guardian,
    this.context = GuardianContext.monitoring,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context2) {
    final isActive = context != GuardianContext.idle;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            guardian.appearance.primaryColor,
            guardian.appearance.secondaryColor,
          ],
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: guardian.appearance.primaryColor.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: -3,
                ),
              ]
            : null,
      ),
      child: Icon(
        guardian.appearance.iconData,
        size: size * 0.5,
        color: VigilThemeV2.spaceBlack,
      ),
    );
  }
}

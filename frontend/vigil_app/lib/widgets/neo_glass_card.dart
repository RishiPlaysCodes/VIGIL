import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';

/// Premium Neo-Glassmorphism Card with holographic effects.
/// 
/// Features:
/// - Multi-layer glass effect with depth
/// - Animated holographic border shimmer
/// - Configurable neon glow color
/// - Inner shadow for 3D depth illusion
/// - Responsive tap animations
/// - Frosted glass backdrop blur
class NeoGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? glowColor;
  final double blurAmount;
  final bool showHoloBorder;
  final bool animateGlow;
  final VoidCallback? onTap;
  final double elevation;

  const NeoGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 18,
    this.glowColor,
    this.blurAmount = 12,
    this.showHoloBorder = false,
    this.animateGlow = false,
    this.onTap,
    this.elevation = 1.0,
  });

  @override
  State<NeoGlassCard> createState() => _NeoGlassCardState();
}

class _NeoGlassCardState extends State<NeoGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.05, end: 0.2).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.animateGlow) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? VigilThemeV2.neonCyan;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap?.call();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  // Outer glow
                  BoxShadow(
                    color: glow.withOpacity(
                      widget.animateGlow ? _glowAnimation.value : 0.08,
                    ),
                    blurRadius: 24,
                    spreadRadius: -8,
                    offset: const Offset(0, 4),
                  ),
                  // Deep shadow for elevation
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35 * widget.elevation),
                    blurRadius: 20 * widget.elevation,
                    offset: Offset(0, 6 * widget.elevation),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.blurAmount,
                    sigmaY: widget.blurAmount,
                  ),
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      // Glass fill
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          VigilThemeV2.cardBase.withOpacity(0.85),
                          VigilThemeV2.cardBase.withOpacity(0.6),
                        ],
                      ),
                      // Border
                      border: Border.all(
                        color: widget.showHoloBorder
                            ? glow.withOpacity(0.3)
                            : VigilThemeV2.borderSubtle.withOpacity(0.5),
                        width: widget.showHoloBorder ? 1.2 : 0.5,
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animated neon pulse indicator (used for protection status)
class NeonPulse extends StatefulWidget {
  final double size;
  final Color color;
  final Widget? child;
  final bool animate;

  const NeonPulse({
    super.key,
    this.size = 80,
    this.color = VigilThemeV2.neonCyan,
    this.child,
    this.animate = true,
  });

  @override
  State<NeonPulse> createState() => _NeonPulseState();
}

class _NeonPulseState extends State<NeonPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          if (widget.animate)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withOpacity(_opacityAnimation.value),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          // Core circle
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color,
                  widget.color.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: widget.child ?? Icon(
              Icons.shield_rounded,
              size: widget.size * 0.45,
              color: VigilThemeV2.spaceBlack,
            ),
          ),
        ],
      ),
    );
  }
}

/// Holographic shimmer text effect
class HoloText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool animate;

  const HoloText({
    super.key,
    required this.text,
    this.style,
    this.animate = true,
  });

  @override
  State<HoloText> createState() => _HoloTextState();
}

class _HoloTextState extends State<HoloText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Text(widget.text, style: widget.style);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(1.0 + 2.0 * _controller.value, 0),
              colors: const [
                VigilThemeV2.neonCyan,
                VigilThemeV2.violetNeon,
                VigilThemeV2.fuchsiaPulse,
                VigilThemeV2.neonCyan,
              ],
              stops: const [0.0, 0.33, 0.66, 1.0],
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: (widget.style ?? VigilThemeV2.headingXL).copyWith(
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

/// Floating action panel with neon border
class FloatingPanel extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderRadius;

  const FloatingPanel({
    super.key,
    required this.child,
    this.borderColor = VigilThemeV2.neonCyan,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: VigilThemeV2.surfaceDark,
        border: Border.all(
          color: borderColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: VigilThemeV2.elevatedShadow,
      ),
      child: child,
    );
  }
}

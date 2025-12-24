import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A beautiful water orb floating AI button with underwater light effects
/// Features flowing internal lights that move like underwater caustics
class MwanachuomindFloatingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isVisible;

  const MwanachuomindFloatingButton({
    super.key,
    required this.onPressed,
    this.isVisible = true,
  });

  @override
  State<MwanachuomindFloatingButton> createState() =>
      _MwanachuomindFloatingButtonState();
}

class _MwanachuomindFloatingButtonState
    extends State<MwanachuomindFloatingButton>
    with TickerProviderStateMixin {
  late AnimationController _flowController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  // Harmonious water colors
  static const Color _deepWater = Color(0xFF065F20);
  static const Color _water = Color(0xFF078829);
  static const Color _lightWater = Color(0xFF6BD89F);
  static const Color _caustic1 = Color(0xFFB6FCDA);
  static const Color _caustic2 = Color(0xFF95F9C3);
  static const Color _caustic3 = Color(0xFF0EA5A0);
  static const Color _shimmer = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();

    // Continuous flow for underwater lights
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Gentle breathing pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Press scale
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _flowController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([
        _flowController,
        _pulseAnimation,
        _scaleAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onPressed();
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Deep ambient glow
                  BoxShadow(
                    color: _water.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  // Caustic shimmer glow
                  BoxShadow(
                    color: _caustic1.withValues(
                      alpha:
                          0.3 *
                          (0.5 +
                              0.5 *
                                  math.sin(
                                    _flowController.value * 2 * math.pi,
                                  )),
                    ),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  children: [
                    // Base water gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.85,
                          colors: [_lightWater, _water, _deepWater],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                    // Underwater caustic light 1
                    _buildCausticLight(
                      offset: _flowController.value,
                      color: _caustic1,
                      size: 28,
                      baseX: 0.3,
                      baseY: 0.2,
                      speedX: 1.0,
                      speedY: 0.7,
                    ),
                    // Underwater caustic light 2
                    _buildCausticLight(
                      offset: _flowController.value + 0.33,
                      color: _caustic2,
                      size: 24,
                      baseX: 0.7,
                      baseY: 0.6,
                      speedX: 0.8,
                      speedY: 1.2,
                    ),
                    // Underwater caustic light 3
                    _buildCausticLight(
                      offset: _flowController.value + 0.66,
                      color: _caustic3,
                      size: 20,
                      baseX: 0.5,
                      baseY: 0.8,
                      speedX: 1.3,
                      speedY: 0.6,
                    ),
                    // Small shimmer particles
                    ..._buildShimmerParticles(),
                    // Glass reflection overlay
                    Positioned(
                      top: 6,
                      left: 10,
                      child: Container(
                        width: 24,
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _shimmer.withValues(alpha: 0.5),
                              _shimmer.withValues(alpha: 0.1),
                              _shimmer.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Inner shadow for depth
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [
                            Colors.transparent,
                            _deepWater.withValues(alpha: 0.3),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                    // Edge rim light
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _caustic1.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // AI Icon with subtle movement
                    Center(
                      child: Transform.translate(
                        offset: Offset(
                          2 * math.sin(_flowController.value * 2 * math.pi),
                          1.5 *
                              math.cos(
                                _flowController.value * 2 * math.pi * 0.7,
                              ),
                        ),
                        child: Icon(
                          Icons.psychology,
                          color: _shimmer.withValues(alpha: 0.95),
                          size: 32,
                          shadows: [
                            Shadow(
                              color: _deepWater.withValues(alpha: 0.6),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                            Shadow(
                              color: _caustic1.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCausticLight({
    required double offset,
    required Color color,
    required double size,
    required double baseX,
    required double baseY,
    required double speedX,
    required double speedY,
  }) {
    final t = (offset % 1.0) * 2 * math.pi;
    final x = baseX + 0.15 * math.sin(t * speedX);
    final y = baseY + 0.15 * math.cos(t * speedY);
    final opacity = 0.3 + 0.4 * (0.5 + 0.5 * math.sin(t * 1.5));

    return Positioned.fill(
      child: Align(
        alignment: Alignment(x * 2 - 1, y * 2 - 1),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity * 0.5),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildShimmerParticles() {
    final particles = <Widget>[];
    final random = math.Random(42); // Fixed seed for consistent positions

    for (int i = 0; i < 5; i++) {
      final baseX = random.nextDouble();
      final baseY = random.nextDouble();
      final speed = 0.5 + random.nextDouble() * 0.5;
      final phase = random.nextDouble() * 2 * math.pi;

      final t = (_flowController.value * 2 * math.pi * speed) + phase;
      final x = baseX + 0.05 * math.sin(t);
      final y = baseY + 0.05 * math.cos(t * 1.3);
      final opacity = 0.2 + 0.5 * (0.5 + 0.5 * math.sin(t * 2));

      particles.add(
        Positioned(
          left: x * 72 - 2,
          top: y * 72 - 2,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _shimmer.withValues(alpha: opacity),
              boxShadow: [
                BoxShadow(
                  color: _caustic1.withValues(alpha: opacity * 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return particles;
  }
}

/// Mini version for other use cases
class MwanachuomindMiniButton extends StatefulWidget {
  final VoidCallback onPressed;

  const MwanachuomindMiniButton({super.key, required this.onPressed});

  @override
  State<MwanachuomindMiniButton> createState() =>
      _MwanachuomindMiniButtonState();
}

class _MwanachuomindMiniButtonState extends State<MwanachuomindMiniButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _flowController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flowController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onPressed();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFB6FCDA),
                  const Color(0xFF6BD89F),
                  const Color(0xFF078829),
                ],
                stops: const [0.0, 0.5, 1.0],
                center: Alignment(
                  0.3 * math.sin(_flowController.value * 2 * math.pi),
                  0.3 * math.cos(_flowController.value * 2 * math.pi),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF078829).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 24),
          ),
        );
      },
    );
  }
}

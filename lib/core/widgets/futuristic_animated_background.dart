import 'package:flutter/material.dart';

class FuturisticAnimatedBackground extends StatefulWidget {
  final Widget child;

  const FuturisticAnimatedBackground({super.key, required this.child});

  @override
  State<FuturisticAnimatedBackground> createState() =>
      _FuturisticAnimatedBackgroundState();
}

class _FuturisticAnimatedBackgroundState
    extends State<FuturisticAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Curated futuristic colors
  final List<Color> _colors = [
    const Color(0xFFE0F2F1), // Very light teal
    const Color(0xFFF3E5F5), // Very light purple
    const Color(0xFFE8EAF6), // Very light indigo
    const Color(0xFFE1F5FE), // Very light blue
    const Color(0xFFE0F7FA), // Very light cyan
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(_colors[0], _colors[1], _animation.value)!,
                Color.lerp(_colors[2], _colors[3], _animation.value)!,
                Color.lerp(_colors[4], _colors[0], _animation.value)!,
              ],
              stops: [
                0.0 + (0.1 * _animation.value),
                0.5,
                1.0 - (0.1 * _animation.value),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Subtle glowing blobs
              Positioned(
                top: -100 + (50 * _animation.value),
                left: -50 + (100 * _animation.value),
                child: _GlowBlob(
                  color: const Color(0xFF64B5F6).withValues(alpha: 0.2),
                  size: 300,
                ),
              ),
              Positioned(
                bottom: -50 + (100 * (1 - _animation.value)),
                right: -100 + (50 * _animation.value),
                child: _GlowBlob(
                  color: const Color(0xFFBA68C8).withValues(alpha: 0.15),
                  size: 400,
                ),
              ),
              Positioned(
                top: 200 + (100 * _animation.value),
                right: 50 - (50 * _animation.value),
                child: _GlowBlob(
                  color: const Color(0xFF4DB6AC).withValues(alpha: 0.1),
                  size: 250,
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedPromotionText extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final int maxLines;
  final Duration delay;
  final bool shouldAnimate;
  final Color? textColor;

  const AnimatedPromotionText({
    super.key,
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    required this.maxLines,
    this.delay = Duration.zero,
    this.shouldAnimate = true,
    this.textColor,
  });

  @override
  State<AnimatedPromotionText> createState() => _AnimatedPromotionTextState();
}

class _AnimatedPromotionTextState extends State<AnimatedPromotionText>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.shouldAnimate) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(AnimatedPromotionText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      for (var controller in _controllers) {
        controller.dispose();
      }
      _initializeAnimations();
      if (widget.shouldAnimate) {
        _startAnimations();
      }
    } else if (!oldWidget.shouldAnimate && widget.shouldAnimate) {
      for (var controller in _controllers) {
        controller.reset();
      }
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    final letters = widget.text.split('');

    _controllers = List.generate(
      letters.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.0,
            end: 1.3,
          ).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.3,
            end: 0.95,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 30,
        ),
      ]).animate(controller);
    }).toList();

    _rotationAnimations = _controllers.asMap().entries.map((entry) {
      final controller = entry.value;
      final index = entry.key;
      final rotationDirection = index % 2 == 0 ? 1.0 : -1.0;
      return Tween<double>(
        begin: 0.25 * rotationDirection,
        end: 0.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, -1.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    }).toList();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.delay + Duration(milliseconds: i * 30), () {
        if (mounted && widget.shouldAnimate) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.text.split('');

    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(letters.length, (index) {
        final letter = letters[index];
        final isSpace = letter == ' ';

        if (isSpace) {
          return SizedBox(width: widget.fontSize * 0.25);
        }

        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _slideAnimations[index].value.dx,
                _slideAnimations[index].value.dy * widget.fontSize * 0.5,
              ),
              child: Transform.scale(
                scale: _scaleAnimations[index].value,
                child: Transform.rotate(
                  angle: _rotationAnimations[index].value,
                  child: Text(
                    letter,
                    style: GoogleFonts.plusJakartaSans(
                      color: widget.textColor ?? Colors.white,
                      fontSize: widget.fontSize,
                      fontWeight: widget.fontWeight,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

class TypewriterMessageBubble extends StatefulWidget {
  final String text;
  final VoidCallback? onComplete;

  const TypewriterMessageBubble({
    super.key,
    required this.text,
    this.onComplete,
  });

  @override
  State<TypewriterMessageBubble> createState() =>
      _TypewriterMessageBubbleState();
}

class _TypewriterMessageBubbleState extends State<TypewriterMessageBubble> {
  String _displayedText = '';
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      // If text changes (e.g. streaming update), restart or continue
      // For now, let's assume the text is final when passed here,
      // or if it grows, we just append.
      // Since we want a "word after word" effect for the *entire* response
      // (assuming we get the full response at once), we reset if significantly different.
      if (widget.text.startsWith(oldWidget.text) &&
          widget.text.length > oldWidget.text.length) {
        // Appending text scenario (if we were streaming tokens)
        // But our current BLoC logic sends full response at 'success'.
        // So we just restart if it's a completely new text.
      } else {
        _currentIndex = 0;
        _displayedText = '';
        _startTyping();
      }
    }
  }

  void _startTyping() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentIndex < widget.text.length) {
        // Optimization: Add 2-3 characters at a time for long texts to speed up
        final int nextIndex = (_currentIndex + 2).clamp(0, widget.text.length);

        setState(() {
          _displayedText = widget.text.substring(0, nextIndex);
          _currentIndex = nextIndex;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceColorLight,
        borderRadius: BorderRadius.circular(
          20,
        ).copyWith(bottomLeft: const Radius.circular(0)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: MarkdownBody(
        data: _displayedText,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.plusJakartaSans(
            color: kTextPrimary,
            fontSize: 15,
            height: 1.5,
          ),
          code: GoogleFonts.firaCode(
            backgroundColor: Colors.grey[200],
            color: kTextPrimary,
            fontSize: 14,
          ),
          codeblockDecoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

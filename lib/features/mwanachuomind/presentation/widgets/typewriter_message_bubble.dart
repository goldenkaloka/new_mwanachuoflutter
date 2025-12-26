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
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: kSurfaceColorLight,
        borderRadius: BorderRadius.circular(
          20,
        ).copyWith(bottomLeft: Radius.zero),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
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
          h1: GoogleFonts.plusJakartaSans(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          h2: GoogleFonts.plusJakartaSans(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          h3: GoogleFonts.plusJakartaSans(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          strong: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
          em: GoogleFonts.plusJakartaSans(
            fontStyle: FontStyle.italic,
            color: kTextPrimary,
          ),
          code: GoogleFonts.firaCode(
            backgroundColor: Colors.black.withValues(alpha: 0.05),
            color: kTextPrimary,
            fontSize: 14,
          ),
          codeblockDecoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          blockquote: GoogleFonts.plusJakartaSans(
            color: kTextPrimary.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: kTextPrimary.withValues(alpha: 0.3),
                width: 4,
              ),
            ),
          ),
          listBullet: GoogleFonts.plusJakartaSans(color: kTextPrimary),
        ),
      ),
    );
  }
}

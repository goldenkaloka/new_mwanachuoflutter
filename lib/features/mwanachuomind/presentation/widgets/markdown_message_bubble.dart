import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

class MarkdownMessageBubble extends StatelessWidget {
  final String text;
  final bool isAi;

  const MarkdownMessageBubble({
    super.key,
    required this.text,
    this.isAi = true,
  });

  @override
  Widget build(BuildContext context) {
    // Determine visuals based on sender
    final bgColor = isAi ? kSurfaceColorLight : kPrimaryColor;
    final textColor = isAi ? kTextPrimary : Colors.white;
    final radius = BorderRadius.circular(20).copyWith(
      bottomLeft: isAi ? Radius.zero : const Radius.circular(20),
      bottomRight: isAi ? const Radius.circular(20) : Radius.zero,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),

      // Note: flutter_chat_ui adds its own margin, but custom builders sometimes need adjustment.
      // We'll trust the parent layout mostly, but add internal padding.
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        // improved shadow for lift and readability
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: isAi
            ? Border.all(color: Colors.black.withValues(alpha: 0.05))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: MarkdownBody(
          data: text,
          selectable: true, // Allow copying text
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontSize: 15,
              height: 1.5,
            ),
            h1: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            h2: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            h3: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            strong: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            em: GoogleFonts.plusJakartaSans(
              fontStyle: FontStyle.italic,
              color: textColor,
            ),
            code: GoogleFonts.firaCode(
              backgroundColor: isAi
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.2),
              color: textColor,
              fontSize: 14,
            ),
            codeblockDecoration: BoxDecoration(
              color: isAi
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            blockquote: GoogleFonts.plusJakartaSans(
              color: textColor.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: textColor.withValues(alpha: 0.3),
                  width: 4,
                ),
              ),
            ),
            listBullet: GoogleFonts.plusJakartaSans(color: textColor),
          ),
        ),
      ),
    );
  }
}

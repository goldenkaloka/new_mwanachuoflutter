import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import '../../domain/entities/document.dart' as app;
import '../../domain/entities/chat_message.dart';
import '../widgets/typewriter_message_bubble.dart';
import 'package:mwanachuo/core/widgets/futuristic_animated_background.dart';
import '../bloc/bloc.dart';

class MwanachuomindChatPage extends StatefulWidget {
  const MwanachuomindChatPage({super.key});

  @override
  State<MwanachuomindChatPage> createState() => _MwanachuomindChatPageState();
}

class _MwanachuomindChatPageState extends State<MwanachuomindChatPage> {
  app.Document? _selectedDocument;

  // AI user for chat
  final _aiUser = const types.User(id: 'ai', firstName: 'Mwanachuomind');
  final _currentUser = const types.User(id: 'user');

  // Track session start to avoid re-animating old messages
  final DateTime _sessionStartTime = DateTime.now();

  // Input controller
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<types.Message> _convertToFlutterChatMessages(
    List<ChatMessage> messages,
  ) {
    return messages
        .map((msg) {
          return types.TextMessage(
            author: msg.sender == MessageSender.user ? _currentUser : _aiUser,
            createdAt: msg.timestamp.millisecondsSinceEpoch,
            id: msg.id,
            text: msg.content,
          );
        })
        .toList()
        .reversed
        .toList(); // flutter_chat_ui expects reversed order
  }

  void _handleSendPressed(types.PartialText message) {
    if (message.text.trim().isEmpty) return;

    context.read<MwanachuomindBloc>().add(
      SendQuery(message.text, documentId: _selectedDocument?.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MwanachuomindBloc, MwanachuomindState>(
      builder: (context, state) {
        final course = state.selectedCourse ?? state.enrolledCourse;
        if (course == null) {
          return const Scaffold(
            body: Center(child: Text("No course selected")),
          );
        }

        final chatMessages = _convertToFlutterChatMessages(state.chatHistory);
        final isAiTyping = state.isGenerating;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(course.code, course.name, state),
          body: FuturisticAnimatedBackground(
            child: Column(
              children: [
                Expanded(
                  child: Chat(
                    messages: chatMessages,
                    onSendPressed: _handleSendPressed,
                    user: _currentUser,
                    showUserAvatars: true,
                    showUserNames: true,
                    theme: _buildChatTheme(context),
                    textMessageBuilder:
                        (message, {required messageWidth, required showName}) {
                          final isAi = message.author.id == 'ai';
                          final isLatest =
                              chatMessages.isNotEmpty &&
                              message.id == chatMessages.first.id;
                          final messageTimestamp =
                              DateTime.fromMillisecondsSinceEpoch(
                                message.createdAt ?? 0,
                              );
                          final isNewMessage = messageTimestamp.isAfter(
                            _sessionStartTime,
                          );

                          if (isAi && isLatest && !isAiTyping && isNewMessage) {
                            return TypewriterMessageBubble(text: message.text);
                          }

                          if (isAi) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(
                                20,
                              ).copyWith(bottomLeft: Radius.zero),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: 8,
                                  sigmaY: 8,
                                ),
                                child: TextMessage(
                                  emojiEnlargementBehavior:
                                      EmojiEnlargementBehavior.multi,
                                  hideBackgroundOnEmojiMessages: true,
                                  message: message,
                                  showName: showName,
                                  usePreviewData: true,
                                ),
                              ),
                            );
                          }

                          // User messages: Solid/Uniform color as requested
                          return TextMessage(
                            emojiEnlargementBehavior:
                                EmojiEnlargementBehavior.multi,
                            hideBackgroundOnEmojiMessages: true,
                            message: message,
                            showName: showName,
                            usePreviewData: true,
                          );
                        },
                    emptyState: _buildEmptyState(course.name),

                    customBottomWidget:
                        const SizedBox.shrink(), // Using our own input
                  ),
                ),
                // Typing indicator
                if (isAiTyping) _buildTypingIndicator(),
                // Custom input
                _buildInput(context),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    String code,
    String name,
    MwanachuomindState state,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.black.withValues(alpha: 0.05),
            surfaceTintColor: Colors.transparent,
            foregroundColor: kTextPrimary,
            titleSpacing: 0,
            title: Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryColor.withValues(alpha: 0.2),
                        kPrimaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: kPrimaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 22,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Mwanachuomind',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kTextPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _PulseIndicator(),
                        ],
                      ),
                      Text(
                        code,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (state.courseDocuments.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _selectedDocument != null
                        ? Icons.article
                        : Icons.article_outlined,
                    color: kTextPrimary,
                  ),
                  onPressed: () => _showDocumentSelector(state),
                ),
              IconButton(
                icon: Icon(Icons.tune_rounded, color: kTextPrimary),
                onPressed: () => _showCourseInfo(),
              ),
              const SizedBox(width: 4),
            ],
            shape: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentSelector(MwanachuomindState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceColorLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Focus your Query',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildDocumentOption(
                    title: 'All documents',
                    subtitle: 'Search across everything',
                    icon: Icons.all_inclusive,
                    isSelected: _selectedDocument == null,
                    onTap: () {
                      setState(() => _selectedDocument = null);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(indent: 70),
                  ...state.courseDocuments.map(
                    (doc) => _buildDocumentOption(
                      title: doc.title,
                      subtitle: 'Query this document only',
                      icon: Icons.description,
                      isSelected: _selectedDocument?.id == doc.id,
                      onTap: () {
                        setState(() => _selectedDocument = doc);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withValues(alpha: 0.1)
              : kTextSecondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isSelected ? kPrimaryColor : kTextSecondary),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? kPrimaryColor : kTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(fontSize: 12),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: kPrimaryColor)
          : null,
      onTap: onTap,
    );
  }

  DefaultChatTheme _buildChatTheme(BuildContext context) {
    return DefaultChatTheme(
      backgroundColor: Colors.transparent,
      primaryColor: kPrimaryColor, // Opaque uniform color for user bubbles
      secondaryColor: Colors.white.withValues(alpha: 0.5),
      inputBackgroundColor: kSurfaceColorLight,
      inputTextColor: kTextPrimary,
      inputBorderRadius: BorderRadius.circular(24),
      inputMargin: const EdgeInsets.all(16),
      inputPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      inputTextStyle: GoogleFonts.plusJakartaSans(fontSize: 16),
      messageBorderRadius: 20,
      messageInsetsHorizontal: 16,
      messageInsetsVertical: 12,
      sentMessageBodyTextStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 15,
        height: 1.5,
      ),
      receivedMessageBodyTextStyle: GoogleFonts.plusJakartaSans(
        color: kTextPrimary,
        fontSize: 15,
        height: 1.5,
      ),
      userAvatarNameColors: [kPrimaryColor],
      userNameTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: kTextSecondary,
      ),
      dateDividerTextStyle: GoogleFonts.plusJakartaSans(
        color: kTextSecondary,
        fontSize: 12,
      ),
      sendButtonIcon: const Icon(Icons.send_rounded, color: kPrimaryColor),
      attachmentButtonIcon: null,
      sendButtonMargin: EdgeInsets.zero,
    );
  }

  Widget _buildEmptyState(String courseName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimaryColor.withValues(alpha: 0.1),
                    kPrimaryColorLight.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                size: 64,
                color: kPrimaryColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hi! I\'m Mwanachuomind 👋',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your AI study companion for $courseName',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kInfoColorLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: kInfoColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Use the document icon to focus answers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: kInfoColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kSurfaceColorLight,
          borderRadius: BorderRadius.circular(
            20,
          ).copyWith(bottomLeft: const Radius.circular(4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const _TypingDots(),
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_selectedDocument != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Icon(
                              Icons.article,
                              color: kPrimaryColor,
                              size: 20,
                            ),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: _selectedDocument != null
                                  ? 'Ask about ${_selectedDocument!.title}...'
                                  : 'Ask Mwanachuomind...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: kTextSecondary.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              isDense: true,
                            ),
                            style: GoogleFonts.plusJakartaSans(
                              color: kTextPrimary,
                              fontSize: 15,
                            ),
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) {
                              final text = _textController.text.trim();
                              if (text.isEmpty) return;
                              _handleSendPressed(types.PartialText(text: text));
                              _textController.clear();
                              _focusNode.requestFocus();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isEmpty) return;
                      _handleSendPressed(types.PartialText(text: text));
                      _textController.clear();
                      _focusNode.requestFocus();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCourseInfo() {
    final bloc = context.read<MwanachuomindBloc>();
    final state = bloc.state;
    final course = state.selectedCourse ?? state.enrolledCourse;

    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceColorLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school, color: kPrimaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course?.code ?? 'No Course',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        course?.name ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.description, color: kTextSecondary, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${state.courseDocuments.length} documents available',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
            if (_selectedDocument != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.filter_center_focus,
                    color: kPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Focused on: ${_selectedDocument!.title}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change Course'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: kPrimaryColor),
                  foregroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Change Course'),
                      content: const Text(
                        'Are you sure you want to change your course? This will clear your current chat session.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Close bottom sheet
                            final userId =
                                Supabase.instance.client.auth.currentUser?.id;
                            if (userId != null) {
                              bloc.add(ClearEnrolledCourse(userId));
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Animated typing dots widget
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animation = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(delay, delay + 0.4, curve: Curves.easeInOut),
              ),
            );
            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              child: Transform.translate(
                offset: Offset(0, -4 * animation.value),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(
                      alpha: 0.5 + 0.5 * animation.value,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator();

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00E676), // Bright green
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF00E676,
                ).withValues(alpha: 0.5 * (1 - _controller.value)),
                blurRadius: 10 * _controller.value,
                spreadRadius: 5 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

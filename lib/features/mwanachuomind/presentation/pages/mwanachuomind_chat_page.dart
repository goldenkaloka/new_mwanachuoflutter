import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import '../../domain/entities/document.dart' as app;
import '../../domain/entities/chat_message.dart';
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

        return Scaffold(
          appBar: _buildAppBar(course.code, course.name, state),
          body: Chat(
            messages: chatMessages,
            onSendPressed: _handleSendPressed,
            user: _currentUser,
            showUserAvatars: true,
            showUserNames: true,
            theme: _buildChatTheme(context),
            emptyState: _buildEmptyState(course.name),
            textMessageBuilder: _buildTextMessage,
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
    return AppBar(
      elevation: 0,
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mwanachuomind',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  code,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Document selector dropdown
        if (state.courseDocuments.isNotEmpty)
          PopupMenuButton<app.Document?>(
            icon: Icon(
              _selectedDocument != null
                  ? Icons.article
                  : Icons.article_outlined,
              color: Colors.white,
            ),
            tooltip: 'Focus on document',
            onSelected: (doc) => setState(() => _selectedDocument = doc),
            itemBuilder: (context) => [
              PopupMenuItem<app.Document?>(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      color: _selectedDocument == null
                          ? kPrimaryColor
                          : kTextSecondary,
                    ),
                    const SizedBox(width: 12),
                    const Text('All documents'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...state.courseDocuments.map(
                (doc) => PopupMenuItem<app.Document>(
                  value: doc,
                  child: Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: _selectedDocument?.id == doc.id
                            ? kPrimaryColor
                            : kTextSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(doc.title, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        if (_selectedDocument != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              label: Text(
                _selectedDocument!.title,
                style: const TextStyle(fontSize: 10, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              deleteIcon: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
              onDeleted: () => setState(() => _selectedDocument = null),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showCourseInfo(),
        ),
      ],
    );
  }

  DefaultChatTheme _buildChatTheme(BuildContext context) {
    return DefaultChatTheme(
      backgroundColor: kBackgroundColorLight,
      primaryColor: kPrimaryColor,
      secondaryColor: kSurfaceColorLight,
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

  Widget _buildTextMessage(
    types.TextMessage message, {
    required int messageWidth,
    required bool showName,
  }) {
    final isUser = message.author.id == 'user';

    return Container(
      margin: EdgeInsets.only(left: isUser ? 40 : 0, right: isUser ? 0 : 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? kPrimaryColor : kSurfaceColorLight,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomRight: isUser ? const Radius.circular(4) : null,
          bottomLeft: !isUser ? const Radius.circular(4) : null,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isUser
          ? Text(
              message.text,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            )
          : MarkdownBody(
              data: message.text,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.plusJakartaSans(
                  color: kTextPrimary,
                  fontSize: 15,
                  height: 1.5,
                ),
                code: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  backgroundColor: kBackgroundColorLight,
                ),
                codeblockDecoration: BoxDecoration(
                  color: kBackgroundColorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                h1: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: kTextPrimary,
                ),
                h2: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: kTextPrimary,
                ),
                h3: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: kTextPrimary,
                ),
                listBullet: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: kTextPrimary,
                ),
                strong: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
                em: GoogleFonts.plusJakartaSans(
                  fontStyle: FontStyle.italic,
                  color: kTextPrimary,
                ),
              ),
            ),
    );
  }

  void _showCourseInfo() {
    final state = context.read<MwanachuomindBloc>().state;
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

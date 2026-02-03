import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:mwanachuo/features/copilot/presentation/bloc/bloc.dart';
import 'package:uuid/uuid.dart';

class CopilotChatPage extends StatefulWidget {
  final String courseId;
  final String? initialQuery;
  final String? noteId;

  const CopilotChatPage({
    super.key,
    required this.courseId,
    this.initialQuery,
    this.noteId,
  });

  @override
  State<CopilotChatPage> createState() => _CopilotChatPageState();
}

class _CopilotChatPageState extends State<CopilotChatPage> {
  final List<Message> _messages = [];
  final _user = const User(id: 'user-id');
  final _copilot = const User(id: 'copilot-id', name: 'Copilot');
  String? _currentAiMessageId;
  late final InMemoryChatController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = InMemoryChatController(messages: _messages);
    // Wrap initial query logic in post frame callback to ensure Bloc is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _handleSendPressed(widget.initialQuery!);
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _handleSendPressed(String text) {
    if (text.trim().isEmpty) return;

    final textMessage = Message.text(
      authorId: _user.id,
      createdAt: DateTime.now(),
      id: const Uuid().v4(),
      text: text,
    );

    // Insert user message at the end (bottom) of the list
    _chatController.insertMessage(textMessage);

    // Provide immediate "Thinking..." feedback or prepare empty AI message
    _currentAiMessageId = const Uuid().v4();
    final loadingMessage = Message.text(
      authorId: _copilot.id,
      createdAt: DateTime.now(),
      id: _currentAiMessageId!,
      text: '...',
      status: MessageStatus.sending,
    );
    // Insert AI loading message at the end (bottom) of the list
    _chatController.insertMessage(loadingMessage);

    context.read<CopilotBloc>().add(
      QueryWithRag(
        question: text,
        courseId: widget.courseId,
        noteId: widget.noteId,
      ),
    );
  }

  void _updateAiMessage(String text, {bool isComplete = false}) {
    if (_currentAiMessageId == null) return;

    final index = _chatController.messages.indexWhere(
      (m) => m.id == _currentAiMessageId,
    );
    if (index != -1) {
      final oldMessage = _chatController.messages[index] as TextMessage;
      final newMessage = oldMessage.copyWith(
        text: text.isEmpty ? '...' : text, // Keep ellipsis if empty
        status: isComplete ? MessageStatus.sent : MessageStatus.sending,
      );
      _chatController.updateMessage(oldMessage, newMessage);
    }
  }

  Future<User?> _resolveUser(UserID userId) async {
    if (userId == _user.id) return _user;
    if (userId == _copilot.id) return _copilot;
    return const User(id: 'unknown');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5), // WhatsApp-like Light Grey BG
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Copilot AI', style: TextStyle(fontSize: 18)),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0d9488),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: BlocConsumer<CopilotBloc, CopilotState>(
        listener: (context, state) {
          if (state is CopilotRagQuerying) {
            _updateAiMessage(state.currentResponse);
          } else if (state is CopilotRagQueryComplete) {
            _updateAiMessage(state.fullResponse, isComplete: true);
            _currentAiMessageId = null; // Reset for next interaction
          } else if (state is CopilotError) {
            _updateAiMessage("Error: ${state.message}", isComplete: true);
            _currentAiMessageId = null;
          }
        },
        builder: (context, state) {
          return Chat(
            chatController: _chatController,
            currentUserId: _user.id,
            resolveUser: _resolveUser,
            onMessageSend: (text) {
              _handleSendPressed(text);
            },
            theme: ChatTheme(
              colors: ChatColors.light().copyWith(
                primary: const Color(0xFFE7FFDB), // WhatsApp Sent Bubble Green
                surfaceContainer:
                    Colors.white, // WhatsApp Received Bubble White
                surface: const Color(0xFFE5DDD5), // WhatsApp BG
                onSurface: Colors.black87,
                onPrimary: Colors.black87,
              ),
              typography: ChatTypography.standard().copyWith(
                bodyLarge: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                bodyMedium: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                labelSmall: TextStyle(
                  color: Colors.black54.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              shape: const BorderRadius.all(Radius.circular(12)),
            ),
          );
        },
      ),
    );
  }
}

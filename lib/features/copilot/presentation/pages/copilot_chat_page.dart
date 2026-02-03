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
  final TextEditingController _textController = TextEditingController();
  bool _isAttachmentOpen = false;
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
    _textController.dispose();
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

    _chatController.insertMessage(textMessage, index: 0);
    _textController.clear();

    // Provide immediate "Thinking..." feedback or prepare empty AI message
    _currentAiMessageId = const Uuid().v4();
    final loadingMessage = Message.text(
      authorId: _copilot.id,
      createdAt: DateTime.now(),
      id: _currentAiMessageId!,
      text: '...',
      status: MessageStatus.sending,
    );
    _chatController.insertMessage(loadingMessage, index: 0);

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

  Widget _buildCustomInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.transparent,
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _textController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
                      color: Colors.grey[600],
                      onPressed: () {},
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          color: Colors.grey[600],
                          onPressed: () {
                            setState(() {
                              _isAttachmentOpen = !_isAttachmentOpen;
                            });
                          },
                        ),
                        if (_textController.text.isEmpty)
                          IconButton(
                            icon: const Icon(Icons.camera_alt_outlined),
                            color: Colors.grey[600],
                            onPressed: () {},
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0d9488),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  _handleSendPressed(_textController.text);
                },
              ),
            ),
          ],
        ),
      ),
    );
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
            builders: Builders(composerBuilder: (_) => _buildCustomInput()),
            theme: ChatTheme(
              colors: ChatColors.light().copyWith(
                primary: const Color(0xFFE7FFDB), // WhatsApp Sent Bubble Green
                surfaceContainer:
                    Colors.white, // WhatsApp Received Bubble White
                surface: const Color(0xFFE5DDD5), // WhatsApp BG
              ),
              typography: ChatTypography.standard().copyWith(
                bodyLarge: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
              shape: const BorderRadius.all(Radius.circular(12)),
            ),
          );
        },
      ),
    );
  }
}

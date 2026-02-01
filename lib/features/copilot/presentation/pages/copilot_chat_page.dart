import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:mwanachuo/features/copilot/presentation/bloc/bloc.dart';
import 'package:uuid/uuid.dart';

class CopilotChatPage extends StatefulWidget {
  final String courseId;
  final String? initialQuery;

  const CopilotChatPage({super.key, required this.courseId, this.initialQuery});

  @override
  State<CopilotChatPage> createState() => _CopilotChatPageState();
}

class _CopilotChatPageState extends State<CopilotChatPage> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user-id');
  final _copilot = const types.User(id: 'copilot-id', firstName: 'Copilot');
  String? _currentAiMessageId;

  @override
  void initState() {
    super.initState();
    // Wrap initial query logic in post frame callback to ensure Bloc is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _handleSendPressed(types.PartialText(text: widget.initialQuery!));
      }
    });
  }

  void _handleSendPressed(types.PartialText message) {
    if (message.text.trim().isEmpty) return;

    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);

    // Provide immediate "Thinking..." feedback or prepare empty AI message
    _currentAiMessageId = const Uuid().v4();
    final loadingMessage = types.TextMessage(
      author: _copilot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _currentAiMessageId!,
      text: '...',
      status: types.Status.sending,
    );
    _addMessage(loadingMessage);

    context.read<CopilotBloc>().add(
      QueryWithRag(
        question: message.text,
        courseId: widget.courseId,
        // noteId is optional, omitted for course-wide search
      ),
    );
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _updateAiMessage(String text, {bool isComplete = false}) {
    if (_currentAiMessageId == null) return;

    final index = _messages.indexWhere((m) => m.id == _currentAiMessageId);
    if (index != -1) {
      setState(() {
        _messages[index] = (_messages[index] as types.TextMessage).copyWith(
          text: text.isEmpty ? '...' : text, // Keep ellipsis if empty
          status: isComplete ? types.Status.sent : types.Status.sending,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copilot Chat'),
        backgroundColor: const Color(0xFF0d9488),
        foregroundColor: Colors.white,
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
            messages: _messages,
            onSendPressed: _handleSendPressed,
            user: _user,
            theme: const DefaultChatTheme(
              primaryColor: Color(0xFF0d9488),
              secondaryColor: Color(0xFFeef2ff),
            ),
          );
        },
      ),
    );
  }
}

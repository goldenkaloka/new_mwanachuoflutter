import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/document.dart';
import '../bloc/bloc.dart';
import '../widgets/chat_bubble.dart';

class MwanachuomindChatPage extends StatefulWidget {
  const MwanachuomindChatPage({super.key});

  @override
  State<MwanachuomindChatPage> createState() => _MwanachuomindChatPageState();
}

class _MwanachuomindChatPageState extends State<MwanachuomindChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _showDocumentPicker = false;
  String _documentSearchQuery = '';
  Document? _selectedDocument;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    if (cursorPos > 0 && cursorPos <= text.length) {
      // Find the @ symbol before cursor
      final beforeCursor = text.substring(0, cursorPos);
      final lastAtIndex = beforeCursor.lastIndexOf('@');

      if (lastAtIndex != -1) {
        // Check if there's a space between @ and cursor (means mention is complete)
        final afterAt = beforeCursor.substring(lastAtIndex + 1);
        if (!afterAt.contains(' ')) {
          setState(() {
            _showDocumentPicker = true;
            _documentSearchQuery = afterAt.toLowerCase();
          });
          return;
        }
      }
    }

    if (_showDocumentPicker) {
      setState(() => _showDocumentPicker = false);
    }
  }

  void _selectDocument(Document doc) {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPos);
    final lastAtIndex = beforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      final afterCursor = cursorPos < text.length
          ? text.substring(cursorPos)
          : '';
      final newText =
          '${text.substring(0, lastAtIndex)}@[${doc.title}] $afterCursor';
      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: lastAtIndex + doc.title.length + 4),
      );
    }

    setState(() {
      _showDocumentPicker = false;
      _selectedDocument = doc;
    });
    _focusNode.requestFocus();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<MwanachuomindBloc>().add(
      SendQuery(text, documentId: _selectedDocument?.id),
    );
    _controller.clear();
    setState(() => _selectedDocument = null);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MwanachuomindBloc, MwanachuomindState>(
      listener: (context, state) {
        if (state.status == MwanachuomindStatus.success) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        final course = state.selectedCourse ?? state.enrolledCourse;
        if (course == null) {
          return const Scaffold(
            body: Center(child: Text("No course selected")),
          );
        }

        final filteredDocs = state.courseDocuments
            .where(
              (doc) => doc.title.toLowerCase().contains(_documentSearchQuery),
            )
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text('${course.code} Assistant'),
            actions: [
              if (_selectedDocument != null)
                Chip(
                  label: Text(
                    _selectedDocument!.title,
                    style: const TextStyle(fontSize: 10),
                  ),
                  onDeleted: () => setState(() => _selectedDocument = null),
                ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: state.chatHistory.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Ask me anything about the course!",
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tip: Type @ to reference a specific document",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: state.chatHistory.length,
                            itemBuilder: (context, index) {
                              return ChatBubble(
                                message: state.chatHistory[index],
                              );
                            },
                          ),
                  ),
                  if (state.status == MwanachuomindStatus.loading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText:
                                  'Type your question... (@ to mention doc)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          color: Theme.of(context).primaryColor,
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Document picker overlay
              if (_showDocumentPicker && filteredDocs.isNotEmpty)
                Positioned(
                  bottom: 70,
                  left: 8,
                  right: 60,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.description, size: 20),
                            title: Text(
                              doc.title,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _selectDocument(doc),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

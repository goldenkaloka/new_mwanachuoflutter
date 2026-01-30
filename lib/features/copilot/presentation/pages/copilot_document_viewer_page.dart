import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/copilot/presentation/bloc/bloc.dart';

class CopilotDocumentViewerPage extends StatefulWidget {
  final String noteId;
  final String courseId;

  const CopilotDocumentViewerPage({
    super.key,
    required this.noteId,
    required this.courseId,
  });

  @override
  State<CopilotDocumentViewerPage> createState() =>
      _CopilotDocumentViewerPageState();
}

class _CopilotDocumentViewerPageState extends State<CopilotDocumentViewerPage> {
  final TextEditingController _questionController = TextEditingController();
  bool _showAIPanel = false;

  @override
  void initState() {
    super.initState();
    context.read<CopilotBloc>().add(LoadNoteDetails(widget.noteId));
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              context.read<CopilotBloc>().add(
                DownloadNoteForOffline(widget.noteId),
              );
            },
          ),
          IconButton(
            icon: Icon(_showAIPanel ? Icons.close : Icons.smart_toy),
            onPressed: () {
              setState(() => _showAIPanel = !_showAIPanel);
            },
          ),
        ],
      ),
      body: BlocBuilder<CopilotBloc, CopilotState>(
        builder: (context, state) {
          if (state is CopilotLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CopilotNoteDetailsLoaded) {
            return _buildDocumentView(state);
          } else if (state is CopilotError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDocumentView(CopilotNoteDetailsLoaded state) {
    return Row(
      children: [
        // Main Document View
        Expanded(
          flex: _showAIPanel ? 2 : 1,
          child: Column(
            children: [
              // Concepts Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFccfbf1).withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFF0d9488),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Extracted Concepts',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0d9488),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.concepts.take(5).map((concept) {
                        return Chip(
                          label: Text(
                            concept.conceptText,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF0d9488)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Document Content (placeholder)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.note.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (state.note.description != null)
                        Text(
                          state.note.description!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      const SizedBox(height: 24),
                      // File preview placeholder
                      Container(
                        height: 400,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Document Preview',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.note.fileType,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // AI Co-Pilot Panel
        if (_showAIPanel)
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(left: BorderSide(color: Colors.grey[300]!)),
            ),
            child: _buildAIPanel(),
          ),
      ],
    );
  }

  Widget _buildAIPanel() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0d9488), Color(0xFF2dd4bf)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF14b8a6).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.psychology, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'AI Co-Pilot',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Chat Area
        Expanded(
          child: BlocBuilder<CopilotBloc, CopilotState>(
            builder: (context, state) {
              if (state is CopilotRagQuerying) {
                return _buildChatResponse(state.currentResponse, false);
              } else if (state is CopilotRagQueryComplete) {
                return _buildChatResponse(state.fullResponse, true);
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ask anything about\nthis document',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _submitQuestion,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _submitQuestion(_questionController.text),
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0d9488),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatResponse(String response, bool isComplete) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFccfbf1).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF0d9488),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isComplete ? 'AI Response' : 'AI is typing...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0d9488),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(response, style: const TextStyle(height: 1.6)),
            ),
          ),
        ],
      ),
    );
  }

  void _submitQuestion(String question) {
    if (question.trim().isEmpty) return;

    context.read<CopilotBloc>().add(
      QueryWithRag(
        question: question,
        noteId: widget.noteId,
        courseId: widget.courseId,
      ),
    );
    _questionController.clear();
  }
}

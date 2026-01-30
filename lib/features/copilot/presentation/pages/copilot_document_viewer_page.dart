import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/copilot/presentation/bloc/bloc.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

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
        title: const Text('Document Viewer'),
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
              // Concepts Bar (Optional shortcut to AI)
              _buildConceptsBar(state),

              // Document Content
              Expanded(child: _buildFileContent(state)),
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

  Widget _buildConceptsBar(CopilotNoteDetailsLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFccfbf1).withValues(alpha: 0.3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFF0d9488),
              size: 16,
            ),
            const SizedBox(width: 8),
            ...state.concepts.take(3).map((concept) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    concept.conceptText,
                    style: const TextStyle(fontSize: 10),
                  ),
                  onPressed: () {
                    if (!_showAIPanel) setState(() => _showAIPanel = true);
                    _questionController.text = "Explain ${concept.conceptText}";
                  },
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFileContent(CopilotNoteDetailsLoaded state) {
    final mimeType = state.note.fileType.toLowerCase();
    final isPdf = mimeType.contains('pdf');
    final isImage = mimeType.contains('image');
    final localPath = state.localFilePath;

    // 1. Image Viewer
    if (isImage) {
      return Center(
        child: SingleChildScrollView(
          child: localPath != null
              ? Image.file(File(localPath), fit: BoxFit.contain)
              : Image.network(state.note.fileUrl, fit: BoxFit.contain),
        ),
      );
    }

    // 2. PDF Viewer
    if (isPdf) {
      if (localPath != null && File(localPath).existsSync()) {
        return SfPdfViewer.file(File(localPath));
      }
      return SfPdfViewer.network(state.note.fileUrl);
    }

    // 3. Other Types (Word, PPT, etc.)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getFileIcon(mimeType), size: 84, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Preview not available in-app',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.note.fileType.split('/').last.toUpperCase(),
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _launchURL(state.note.fileUrl),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open with External App'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0d9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.contains('word')) return Icons.description;
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) {
      return Icons.slideshow;
    }
    return Icons.insert_drive_file;
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
                  onSubmitted: (val) => _submitQuestion(val),
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mwanachuo/features/copilot/presentation/bloc/bloc.dart';
import 'package:uuid/uuid.dart';

class CopilotUploadPage extends StatefulWidget {
  final String courseId;

  const CopilotUploadPage({super.key, required this.courseId});

  @override
  State<CopilotUploadPage> createState() => _CopilotUploadPageState();
}

class _CopilotUploadPageState extends State<CopilotUploadPage> {
  File? _selectedFile;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'docx',
        'doc',
        'pptx',
        'ppt',
        'jpg',
        'jpeg',
        'png',
        'webp',
      ],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _titleController.text = result.files.single.name.replaceAll(
          RegExp(r'\.(pdf|docx|doc|pptx|ppt|jpg|jpeg|png|webp)$'),
          '',
        );
      });
    }
  }

  void _uploadFile() {
    if (_selectedFile == null) return;

    final noteId = const Uuid().v4();
    context.read<CopilotBloc>().add(
      UploadNote(
        filePath: _selectedFile!.path,
        noteId: noteId,
        courseId: widget.courseId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Note')),
      body: BlocConsumer<CopilotBloc, CopilotState>(
        listener: (context, state) {
          if (state is CopilotUploadSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Note uploaded and analyzed successfully!'),
                backgroundColor: Color(0xFF0d9488),
              ),
            );
            Navigator.pop(context);
          } else if (state is CopilotError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CopilotUploading) {
            return _buildUploadingView(state.progress);
          } else if (state is CopilotUploadSuccess) {
            return _buildSuccessView(state.analysisResult);
          }
          return _buildUploadForm();
        },
      ),
    );
  }

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // File Picker
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFccfbf1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0d9488),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0d9488).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Color(0xFF0d9488),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFile == null
                        ? 'Tap to select a file'
                        : _selectedFile!.path.split('/').last,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0d9488),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PDF, Word, PPT or Images supported',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Note Title',
              hintText: 'Enter a descriptive title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.title),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'Add a brief description...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.notes),
            ),
          ),

          const SizedBox(height: 24),

          // AI Features Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0d9488), Color(0xFF2dd4bf)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'AI will process this note',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Extract key concepts\n• Generate flashcards\n• Create study guide\n• Enable AI Q&A',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Upload Button
          ElevatedButton(
            onPressed: _selectedFile != null && _titleController.text.isNotEmpty
                ? _uploadFile
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0d9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Upload & Analyze',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingView(int progress) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF0d9488)),
          const SizedBox(height: 24),
          Text(
            'Uploading & Analyzing...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is processing your document',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFccfbf1).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Color(0xFF0d9488),
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'Extracting concepts...',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(Map<String, dynamic> result) {
    final chunksCount = result['chunks_count'] ?? 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0d9488).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF0d9488),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Successfully Uploaded!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your note has been processed and is ready for study',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    Icons.splitscreen,
                    'Chunks Created',
                    chunksCount.toString(),
                  ),
                  const Divider(),
                  _buildStatRow(Icons.lightbulb, 'AI Features', 'Ready'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0d9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('View in Library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0d9488), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

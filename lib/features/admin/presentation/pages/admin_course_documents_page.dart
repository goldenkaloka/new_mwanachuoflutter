import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/copilot/domain/repositories/copilot_repository.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/copilot/domain/entities/note_entity.dart';
import 'package:uuid/uuid.dart';

class AdminCourseDocumentsPage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const AdminCourseDocumentsPage({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<AdminCourseDocumentsPage> createState() =>
      _AdminCourseDocumentsPageState();
}

class _AdminCourseDocumentsPageState extends State<AdminCourseDocumentsPage> {
  final _repository = sl<CopilotRepository>();
  List<NoteEntity> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final result = await _repository.getCourseNotes(
        courseId: widget.courseId,
      );
      result.fold(
        (failure) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading documents: ${failure.message}'),
              ),
            );
          }
        },
        (notes) {
          if (mounted) {
            setState(() {
              _documents = notes;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading documents: $e')));
      }
    }
  }

  Future<void> _uploadDocument() async {
    final titleController = TextEditingController();
    File? selectedFile;
    String? selectedFileName;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
            title: Text(
              'Upload Document',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : kTextPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Document Title',
                    hintText: 'e.g., Lecture 1 Notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: [
                        'pdf',
                        'doc',
                        'docx',
                        'ppt',
                        'pptx',
                        'xls',
                        'xlsx',
                        'txt',
                      ],
                    );

                    if (result != null) {
                      setState(() {
                        selectedFile = File(result.files.single.path!);
                        selectedFileName = result.files.single.name;
                        // Auto-fill title if empty
                        if (titleController.text.isEmpty) {
                          titleController.text = selectedFileName!;
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    selectedFileName ?? 'Select File (PDF, DOCX, PPT...)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),
                if (selectedFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Selected: $selectedFileName',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty ||
                      selectedFile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please Provide title and file'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext);
                  _performUpload(titleController.text.trim(), selectedFile!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Upload'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performUpload(String title, File file) async {
    setState(() => _isLoading = true);
    try {
      final noteId = const Uuid().v4();
      final result = await _repository.uploadAndAnalyze(
        courseId: widget.courseId,
        noteId: noteId,
        file: file,
        title: title,
      );

      result.fold(
        (failure) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            _loadDocuments();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.courseName} - Documents',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadDocument,
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents uploaded yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.description,
                        color: kPrimaryColor,
                      ),
                    ),
                    title: Text(
                      doc.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                    ),
                    subtitle: Text(
                      'Uploaded on ${_formatDate(doc.createdAt)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

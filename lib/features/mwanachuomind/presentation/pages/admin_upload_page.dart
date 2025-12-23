import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/bloc.dart';
import '../../domain/entities/course.dart';

class AdminUploadPage extends StatefulWidget {
  const AdminUploadPage({super.key});

  @override
  State<AdminUploadPage> createState() => _AdminUploadPageState();
}

class _AdminUploadPageState extends State<AdminUploadPage> {
  final TextEditingController _titleController = TextEditingController();
  Course? _selectedCourse;
  File? _selectedFile;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  void _upload() {
    if (_selectedCourse == null || _selectedFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a file')),
      );
      return;
    }

    // Since bloc expects a selected course in state for uploading (based on previous implementation logic),
    // we might need to dispatch SelectCourse or refactor Bloc.
    // However, the bloc event UploadDocument just takes title and file, and uses state.selectedCourse.
    // optimizing: The bloc expects state.selectedCourse to be set.
    // So we must ensure we dispatch SelectCourse before UploadDocument OR modify UploadDocument event to accept courseId.
    // Let's modify the Bloc usage here to:
    // 1. Select the course in Bloc
    // 2. Upload
    
    context.read<MwanachuomindBloc>().add(SelectCourse(_selectedCourse!));
    context.read<MwanachuomindBloc>().add(UploadDocument(_titleController.text, _selectedFile!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: BlocConsumer<MwanachuomindBloc, MwanachuomindState>(
        listener: (context, state) {
            if (!state.isUploading && state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            } else if (!state.isUploading && state.status == MwanachuomindStatus.loading) {
                 // loading...
            } else if (!state.isUploading && state.errorMessage == null && state.status != MwanachuomindStatus.initial) {
                // Success (implied by lack of error after uploading false) - Wait, state management in bloc: 
                // UploadDocument sets isUploading=false on success. 
                // Ideally we should have a specific success state or event.
                // For now, let's just show snackbar if we are not uploading anymore and no error.
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload Successful!')));
                 Navigator.pop(context);
            }
        },
        builder: (context, state) {
          if (state.isUploading) {
              return const Center(child: CircularProgressIndicator());
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButton<Course>(
                  hint: const Text('Select Course'),
                  value: _selectedCourse,
                  // We can use the courses from the bloc state if they are loaded
                  items: state.courses.map((e) => DropdownMenuItem(value: e, child: Text(e.code))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCourse = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Document Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(_selectedFile == null ? 'Pick File (PDF/TXT)' : 'File: ${_selectedFile!.path.split(Platform.pathSeparator).last}'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _upload,
                  child: const Text('Upload'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

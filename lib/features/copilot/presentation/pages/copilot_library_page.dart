import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/copilot/presentation/bloc/bloc.dart';
import 'package:mwanachuo/features/copilot/domain/entities/note_entity.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';

class CopilotLibraryPage extends StatefulWidget {
  final String courseId;

  final String? initialSearchQuery;

  const CopilotLibraryPage({
    super.key,
    required this.courseId,
    this.initialSearchQuery,
  });

  @override
  State<CopilotLibraryPage> createState() => _CopilotLibraryPageState();
}

class _CopilotLibraryPageState extends State<CopilotLibraryPage> {
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    int? year;
    int? semester;

    if (authState is Authenticated) {
      year = authState.user.yearOfStudy;
      semester = authState.user.currentSemester;
    }

    if (widget.initialSearchQuery != null) {
      context.read<CopilotBloc>().add(
        SearchNotes(
          query: widget.initialSearchQuery!,
          courseId: widget.courseId,
        ),
      );
    } else {
      context.read<CopilotBloc>().add(
        LoadCourseNotes(
          courseId: widget.courseId,
          year: year,
          semester: semester,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: BlocBuilder<CopilotBloc, CopilotState>(
              builder: (context, state) {
                if (state is CopilotLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is CopilotNotesLoaded) {
                  if (state.notes.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildNotesList(state.notes);
                } else if (state is CopilotSearchResults) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Colors.grey[100],
                        child: Row(
                          children: [
                            Text(
                              'Search results for: "${state.query}"',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                context.read<CopilotBloc>().add(
                                  LoadCourseNotes(courseId: widget.courseId),
                                );
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      ),
                      if (state.results.isEmpty)
                        Expanded(child: _buildEmptySearchState())
                      else
                        Expanded(child: _buildNotesList(state.results)),
                    ],
                  );
                } else if (state is CopilotError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/copilot-upload',
            arguments: {'courseId': widget.courseId},
          );
        },
        backgroundColor: const Color(0xFF0d9488),
        extendedIconLabelSpacing: 16,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        elevation: 12,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.upload_file, color: Colors.white, size: 24),
        label: const Text(
          'Upload Note',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Notes'),
            selected: _currentFilter == null,
            onSelected: (_) => _changeFilter(null),
            selectedColor: const Color(0xFFccfbf1),
            checkmarkColor: const Color(0xFF0d9488),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Official'),
            selected: _currentFilter == 'official',
            onSelected: (_) => _changeFilter('official'),
            selectedColor: const Color(0xFFccfbf1),
            checkmarkColor: const Color(0xFF0d9488),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('My Notes'),
            selected: _currentFilter == 'my_notes',
            onSelected: (_) => _changeFilter('my_notes'),
            selectedColor: const Color(0xFFccfbf1),
            checkmarkColor: const Color(0xFF0d9488),
          ),
        ],
      ),
    );
  }

  void _changeFilter(String? filter) {
    setState(() => _currentFilter = filter);
    context.read<CopilotBloc>().add(
      LoadCourseNotes(courseId: widget.courseId, filterBy: filter),
    );
  }

  Widget _buildNotesList(List<NoteEntity> notes) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(NoteEntity note) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/copilot-viewer',
            arguments: {'noteId': note.id, 'courseId': widget.courseId},
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'by ${note.uploaderName ?? 'User'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getTimeAgo(note.createdAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF14b8a6),
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                        if (note.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            note.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (note.isOfficial)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFccfbf1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OFFICIAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0f766e),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Readiness Score
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getReadinessColor(
                        note.studyReadinessScore,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getReadinessColor(note.studyReadinessScore),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school,
                          size: 14,
                          color: _getReadinessColor(note.studyReadinessScore),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${note.studyReadinessScore.toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getReadinessColor(note.studyReadinessScore),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Downloads
                  Icon(
                    Icons.download_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${note.downloadCount}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  // Views
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${note.viewCount}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  // AI Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0d9488), Color(0xFF2dd4bf)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getReadinessColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first note to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No matching notes',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different concept or keyword',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Future<void> _showSearchDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Notes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Search by title or content...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (mounted) {
        context.read<CopilotBloc>().add(
          SearchNotes(query: result, courseId: widget.courseId),
        );
      }
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }
}

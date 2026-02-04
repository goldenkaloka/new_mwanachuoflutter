import 'package:flutter/material.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/copilot/presentation/bloc/bloc.dart';
import 'package:mwanachuo/features/copilot/domain/entities/note_entity.dart';
import 'package:mwanachuo/features/promotions/presentation/widgets/single_random_promotion.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';

class CopilotDashboardPage extends StatefulWidget {
  final String courseId;

  const CopilotDashboardPage({super.key, required this.courseId});

  @override
  State<CopilotDashboardPage> createState() => _CopilotDashboardPageState();
}

class _CopilotDashboardPageState extends State<CopilotDashboardPage> {
  final TextEditingController _searchController = TextEditingController();

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

    context.read<CopilotBloc>().add(
      LoadCourseNotes(
        courseId: widget.courseId,
        year: year,
        semester: semester,
      ),
    );
  }

  Future<void> _scanText() async {
    final picker = ImagePicker();
    // specific fix for Windows: ImageSource.camera might fail if no delegate.
    // Fallback to gallery (file picker) on Desktop.
    final source =
        (Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux ||
            Theme.of(context).platform == TargetPlatform.macOS)
        ? ImageSource.gallery
        : ImageSource.camera;

    try {
      final image = await picker.pickImage(source: source);
      if (image == null) return;

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      final text = recognizedText.text;

      await textRecognizer.close();

      if (text.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _searchController.text = text;
        });
        // Optionally execute search immediately
        _navigateToChat(text);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scanning text: $e')));
    }
  }

  void _navigateToChat(String query) {
    if (query.isEmpty) return;
    Navigator.pushNamed(
      context,
      '/copilot-chat',
      arguments: {'courseId': widget.courseId, 'initialQuery': query},
    ).then((_) {
      // Clear search text when returning from chat
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Search
            _buildHeader(),

            // Scrollable Content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  const SliverToBoxAdapter(child: SingleRandomPromotion()),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _buildDownloadedSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  SliverToBoxAdapter(child: _buildUnitMaterialsSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  _buildRecentlyProcessedSliver(),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildUploadNoteButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(color: kPrimaryColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          // Profile Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kPrimaryColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  color: Theme.of(context).cardColor,
                ),
                child: const Icon(Icons.person, color: kPrimaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI STUDY PILOT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MwanachuoCopilot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                color: kPrimaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ask your AI Tutor about anything...',
                hintStyle: TextStyle(
                  color: kPrimaryColor.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.psychology_outlined,
                  color: kPrimaryColor,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      color: kPrimaryColor,
                      onPressed: _scanText,
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (_searchController.text.isNotEmpty) {
                            _navigateToChat(_searchController.text);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (query) {
                _navigateToChat(query);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedSection() {
    return BlocBuilder<CopilotBloc, CopilotState>(
      builder: (context, state) {
        if (state is CopilotNotesLoaded && state.downloadedNotes.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.offline_pin_outlined,
                      color: kPrimaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ready for Offline Study',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${state.downloadedNotes.length} notes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.downloadedNotes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final note = state.downloadedNotes[index];
                    return _buildOfflineNoteCard(note);
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOfflineNoteCard(NoteEntity note) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/copilot-viewer',
          arguments: {'noteId': note.id, 'courseId': widget.courseId},
        );
      },
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.file_download_done,
                color: kPrimaryColorDark,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              note.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              note.fileType.split('/').last.toUpperCase(),
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitMaterialsSection() {
    return BlocBuilder<CopilotBloc, CopilotState>(
      builder: (context, state) {
        if (state is CopilotNotesLoaded) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Unit Materials',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/copilot-library',
                          arguments: {'courseId': widget.courseId},
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(color: kPrimaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryColor,
                        kPrimaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Course Library',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Browse ${state.notes.length} academic resources',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/copilot-library',
                                  arguments: {'courseId': widget.courseId},
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: kPrimaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Open Library'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.library_books,
                        size: 64,
                        color: Colors.white24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRecentlyProcessedSliver() {
    return BlocBuilder<CopilotBloc, CopilotState>(
      builder: (context, state) {
        List<NoteEntity> recentNotes = [];
        if (state is CopilotNotesLoaded) {
          recentNotes = state.notes;
        }

        if (recentNotes.isNotEmpty) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                Text(
                  'Recently Processed by AI',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...recentNotes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNoteCard(note),
                  ),
                ),
              ]),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildNoteCard(NoteEntity note) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
              color: kPrimaryColor.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.description, color: kPrimaryColorDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'by ${note.uploaderName ?? 'User'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getTimeAgo(note.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kPrimaryColor.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFccfbf1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AI SUMMARIZED',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0f766e),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome),
            color: kPrimaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadNoteButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/copilot-upload',
          arguments: {'courseId': widget.courseId},
        );
      },
      backgroundColor: kPrimaryColor,
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
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }
}

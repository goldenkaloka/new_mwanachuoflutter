import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/copilot/presentation/bloc/bloc.dart';

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
    context.read<CopilotBloc>().add(LoadCourseNotes(courseId: widget.courseId));
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // _buildAIStudyPaths(), // Removed hardcoded data
                    // const SizedBox(height: 24),
                    _buildRecentlyProcessed(),
                    // const SizedBox(height: 24),
                    // _buildAIInsightCard(), // Removed hardcoded data
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildAskAIButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF0d9488).withValues(alpha: 0.1),
          ),
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
                    color: const Color(0xFF0d9488).withValues(alpha: 0.2),
                    width: 2,
                  ),
                  color: Theme.of(context).cardColor,
                ),
                child: const Icon(Icons.person, color: Color(0xFF0d9488)),
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
                        color: const Color(0xFF14b8a6),
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
                color: const Color(0xFF0d9488),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0d9488).withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF14b8a6).withValues(alpha: 0.1),
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
                  color: const Color(0xFF0d9488).withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.psychology_outlined,
                  color: Color(0xFF0d9488),
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0d9488),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (query) {
                Navigator.pushNamed(
                  context,
                  '/copilot-library',
                  arguments: {
                    'courseId': widget.courseId,
                    'initialSearchQuery': query,
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyProcessed() {
    return BlocBuilder<CopilotBloc, CopilotState>(
      builder: (context, state) {
        if (state is CopilotNotesLoaded) {
          final recentNotes = state.notes.take(3).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Recently Processed by AI',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recentNotes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final note = recentNotes[index];
                  return _buildNoteCard(note);
                },
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildNoteCard(note) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0d9488).withValues(alpha: 0.1),
        ),
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
              border: Border.all(
                color: const Color(0xFF0d9488).withValues(alpha: 0.2),
              ),
              color: const Color(0xFFccfbf1),
            ),
            child: const Icon(Icons.description, color: Color(0xFF0f766e)),
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
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0f766e),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '2h ago',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF14b8a6).withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome),
            color: const Color(0xFF0d9488),
          ),
        ],
      ),
    );
  }

  Widget _buildAskAIButton() {
    return FloatingActionButton.extended(
      onPressed: () {},
      backgroundColor: const Color(0xFF0d9488),
      elevation: 8,
      label: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Ask AI Anything',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

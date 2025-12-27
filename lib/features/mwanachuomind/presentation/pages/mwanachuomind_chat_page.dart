import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart' as toolkit;

import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/chat_message.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

import 'package:mwanachuo/core/widgets/futuristic_animated_background.dart';
import '../bloc/bloc.dart';

class MwanachuomindChatPage extends StatefulWidget {
  const MwanachuomindChatPage({super.key});

  @override
  State<MwanachuomindChatPage> createState() => _MwanachuomindChatPageState();
}

class _MwanachuomindChatPageState extends State<MwanachuomindChatPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<MwanachuomindBloc>();
      final state = bloc.state;
      final course = state.selectedCourse ?? state.enrolledCourse;
      final user = Supabase.instance.client.auth.currentUser;

      if (course != null && user != null && state.sessions.isEmpty) {
        bloc.add(LoadChatSessions(userId: user.id, courseId: course.id));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Create the provider instance
  toolkit.LlmProvider _createLlamaProvider(MwanachuomindState state) {
    return _MwanachuomindAiProvider(
      context: context,
      initialHistory: state.chatHistory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MwanachuomindBloc, MwanachuomindState>(
      listener: (context, state) {
        // Listen for errors or specific events if needed
      },
      builder: (context, state) {
        final course = state.selectedCourse ?? state.enrolledCourse;
        if (course == null) {
          return const Scaffold(
            body: Center(child: Text("No course selected")),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          drawer: _buildDrawer(state, course.id),
          appBar: _buildAppBar(course.code, course.name, state, course.id),
          body: SafeArea(
            bottom: false, // Don't add bottom safe area padding
            child: FuturisticAnimatedBackground(
              child: Column(
                children: [
                  Expanded(
                    child: toolkit.LlmChatView(
                      provider: _createLlamaProvider(state),
                      enableAttachments: false,
                      enableVoiceNotes: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    String code,
    String name,
    MwanachuomindState state,
    String courseId,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.black.withValues(alpha: 0.05),
            surfaceTintColor: Colors.transparent,
            foregroundColor: kTextPrimary,
            titleSpacing: 0,
            title: Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryColor.withValues(alpha: 0.2),
                        kPrimaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: kPrimaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 22,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Mwanachuomind',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: kTextPrimary,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _PulseIndicator(),
                        ],
                      ),
                      Text(
                        code,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (state.courseDocuments.isNotEmpty)
                IconButton(
                  icon: Icon(
                    state.selectedDocument != null
                        ? Icons.article
                        : Icons.article_outlined,
                    color: kTextPrimary,
                  ),
                  onPressed: () => _showDocumentSelector(state),
                ),
              IconButton(
                icon: Icon(Icons.tune_rounded, color: kTextPrimary),
                onPressed: () => _showCourseInfo(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.add, color: kPrimaryColor),
                onPressed: () {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    context.read<MwanachuomindBloc>().add(
                      CreateNewChatSession(userId: user.id, courseId: courseId),
                    );
                  }
                },
                tooltip: 'New Chat',
              ),
              const SizedBox(width: 8),
            ],
            shape: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentSelector(MwanachuomindState state) {
    final bloc = context.read<MwanachuomindBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceColorLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Focus your Query',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildDocumentOption(
                    title: 'All documents',
                    subtitle: 'Search across everything',
                    icon: Icons.all_inclusive,
                    isSelected: state.selectedDocument == null,
                    onTap: () {
                      bloc.add(const SelectDocument(null));
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(indent: 70),
                  ...state.courseDocuments.map(
                    (doc) => _buildDocumentOption(
                      title: doc.title,
                      subtitle: 'Query this document only',
                      icon: Icons.description,
                      isSelected: state.selectedDocument?.id == doc.id,
                      onTap: () {
                        bloc.add(SelectDocument(doc));
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withValues(alpha: 0.1)
              : kTextSecondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isSelected ? kPrimaryColor : kTextSecondary),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? kPrimaryColor : kTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(fontSize: 12),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: kPrimaryColor)
          : null,
      onTap: onTap,
    );
  }

  void _showCourseInfo() {
    final bloc = context.read<MwanachuomindBloc>();
    final state = bloc.state;
    final course = state.selectedCourse ?? state.enrolledCourse;

    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceColorLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school, color: kPrimaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course?.code ?? 'No Course',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        course?.name ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.description, color: kTextSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${state.courseDocuments.length} documents available',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: kTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (state.selectedDocument != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.filter_center_focus,
                    color: kPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Focused on: ${state.selectedDocument!.title}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change Course'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: kPrimaryColor),
                  foregroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Change Course'),
                      content: const Text(
                        'Are you sure you want to change your course? This will clear your current chat session.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Close bottom sheet
                            final userId =
                                Supabase.instance.client.auth.currentUser?.id;
                            if (userId != null) {
                              bloc.add(ClearEnrolledCourse(userId));
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(MwanachuomindState state, String courseId) {
    return Drawer(
      backgroundColor: kSurfaceColorLight,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.05),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, color: kPrimaryColor, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Chat History',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: state.sessions.isEmpty
                ? Center(
                    child: Text(
                      'No chat history yet',
                      style: GoogleFonts.plusJakartaSans(color: kTextSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: state.sessions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final session = state.sessions[index];
                      final isSelected = session.id == state.sessionId;
                      return ListTile(
                        title: Text(
                          session.title.isEmpty ? 'New Chat' : session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? kPrimaryColor : kTextPrimary,
                          ),
                        ),
                        tileColor: isSelected
                            ? kPrimaryColor.withValues(alpha: 0.1)
                            : null,
                        onTap: () {
                          if (!isSelected) {
                            context.read<MwanachuomindBloc>().add(
                              SelectChatSession(session.id),
                            );
                          }
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    context.read<MwanachuomindBloc>().add(
                      CreateNewChatSession(userId: user.id, courseId: courseId),
                    );
                  }
                  Navigator.pop(context); // Close drawer
                },
                icon: const Icon(Icons.add),
                label: const Text("New Chat"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  side: BorderSide(color: kPrimaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Provider Implementation
class _MwanachuomindAiProvider extends ChangeNotifier
    implements toolkit.LlmProvider {
  final BuildContext context;
  List<toolkit.ChatMessage> _history;

  _MwanachuomindAiProvider({
    required this.context,
    required List<ChatMessage> initialHistory,
  }) : _history = initialHistory
           .map(
             (m) => toolkit.ChatMessage(
               origin: m.sender == MessageSender.user
                   ? toolkit.MessageOrigin.user
                   : toolkit.MessageOrigin.llm,
               text: m.content,
               attachments: [],
             ),
           )
           .toList();

  @override
  Iterable<toolkit.ChatMessage> get history => _history;

  @override
  set history(Iterable<toolkit.ChatMessage> value) {
    _history = value.toList();
    notifyListeners();
  }

  @override
  Stream<String> generateStream(
    String input, {
    Iterable<toolkit.Attachment> attachments = const [],
  }) async* {
    final bloc = context.read<MwanachuomindBloc>();
    final state = bloc.state;

    if (state.selectedCourse == null || state.sessionId == null) {
      throw Exception('No course or session selected');
    }

    // Build history for API
    final apiHistory = state.chatHistory
        .map(
          (m) => {
            'role': m.sender == MessageSender.user ? 'user' : 'model',
            'parts': m.content,
          },
        )
        .toList();

    // Stream directly from repository (now handles word-by-word streaming)
    final stream = bloc.repository.chatStream(
      query: input,
      courseId: state.selectedCourse!.id,
      history: apiHistory,
      documentId: state.selectedDocument?.id,
    );

    // Yield each chunk as it arrives
    await for (final chunk in stream) {
      yield chunk;
    }

    // After streaming completes, save to Bloc
    bloc.add(SendQuery(input, documentId: state.selectedDocument?.id));
  }

  @override
  Stream<String> sendMessageStream(
    String message, {
    Iterable<toolkit.Attachment> attachments = const [],
  }) {
    return generateStream(message, attachments: attachments);
  }
}

class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator();

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00E676), // Bright green
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF00E676,
                ).withValues(alpha: 0.5 * (1 - _controller.value)),
                blurRadius: 10 * _controller.value,
                spreadRadius: 5 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bloc/bloc.dart';
import 'mwanachuomind_chat_page.dart';
import '../widgets/mwanachuomind_shimmer.dart';

/// Wrapper page that checks if user is enrolled in a course.
/// If yes, navigates directly to chat.
/// If no, shows course selection for enrollment.
class MwanachuomindWrapperPage extends StatefulWidget {
  const MwanachuomindWrapperPage({super.key});

  @override
  State<MwanachuomindWrapperPage> createState() =>
      _MwanachuomindWrapperPageState();
}

class _MwanachuomindWrapperPageState extends State<MwanachuomindWrapperPage> {
  bool _hasCheckedEnrollment = false;
  bool _enrollmentLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkEnrollment();
  }

  void _checkEnrollment() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<MwanachuomindBloc>().add(LoadEnrolledCourse(userId));
      setState(() => _hasCheckedEnrollment = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MwanachuomindBloc, MwanachuomindState>(
      listenWhen: (previous, current) {
        // Only listen when status changes from loading to success/failure
        return previous.status != current.status;
      },
      listener: (context, state) {
        // When enrollment check completes
        if (_hasCheckedEnrollment &&
            state.status == MwanachuomindStatus.success &&
            !_enrollmentLoaded) {
          setState(() => _enrollmentLoaded = true);

          // If user has enrolled course, load chat history and documents
          if (state.enrolledCourse != null) {
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId != null && state.sessionId == null) {
              context.read<MwanachuomindBloc>().add(
                LoadChatSessions(
                  userId: userId,
                  courseId: state.enrolledCourse!.id,
                ),
              );
              context.read<MwanachuomindBloc>().add(
                LoadCourseDocuments(state.enrolledCourse!.id),
              );
            }
          }
        }
      },
      buildWhen: (previous, current) {
        // Only rebuild on meaningful state changes
        return previous.enrolledCourse != current.enrolledCourse ||
            previous.status != current.status ||
            (previous.sessionId == null && current.sessionId != null);
      },
      builder: (context, state) {
        // Still checking enrollment
        if (!_enrollmentLoaded && state.status == MwanachuomindStatus.loading) {
          return const Scaffold(body: SafeArea(child: MwanachuomindShimmer()));
        }

        // User has enrolled course - show chat directly
        if (state.enrolledCourse != null) {
          return const MwanachuomindChatPage();
        }

        // User not enrolled - show course selection for first-time enrollment
        return const CourseEnrollmentPage();
      },
    );
  }
}

/// Page shown to first-time users to select their course
class CourseEnrollmentPage extends StatefulWidget {
  const CourseEnrollmentPage({super.key});

  @override
  State<CourseEnrollmentPage> createState() => _CourseEnrollmentPageState();
}

class _CourseEnrollmentPageState extends State<CourseEnrollmentPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserUniversity();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserUniversity() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final data = await Supabase.instance.client
            .from('users')
            .select('primary_university_id')
            .eq('id', userId)
            .single();
        final universityId = data['primary_university_id'] as String?;
        if (universityId != null && mounted) {
          context.read<MwanachuomindBloc>().add(
            LoadUniversityCourses(universityId),
          );
        }
      } catch (e) {
        debugPrint('Error loading university: $e');
      }
    }
  }

  void _enrollInCourse(String courseId) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<MwanachuomindBloc>().add(
        EnrollInCourse(userId: userId, courseId: courseId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Course')),
      body: BlocBuilder<MwanachuomindBloc, MwanachuomindState>(
        builder: (context, state) {
          if (state.status == MwanachuomindStatus.loading &&
              state.courses.isEmpty) {
            return const MwanachuomindShimmer();
          }

          final filteredCourses = state.courses.where((course) {
            final name = course.name.toLowerCase();
            final code = course.code.toLowerCase();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || code.contains(query);
          }).toList();

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Choose the course you are enrolled in.\nThis will personalize your AI assistant.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search course by name or code...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (filteredCourses.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty
                                ? Icons.school
                                : Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No courses available for your university yet.\nPlease contact your administrator.'
                                : 'No courses match "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = filteredCourses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(course.name),
                          subtitle: Text(course.code),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _enrollInCourse(course.id),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

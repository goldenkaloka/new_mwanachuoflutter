import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_event.dart';
import 'package:mwanachuo/features/shared/university/presentation/bloc/university_bloc.dart';
import 'package:mwanachuo/features/shared/university/presentation/bloc/university_state.dart';
import 'package:mwanachuo/features/shared/university/presentation/bloc/university_event.dart'; // Ensure this exists or create it
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mwanachuo/core/di/injection_container.dart';

class CourseSelectionPage extends StatelessWidget {
  const CourseSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<UniversityBloc>(),
      // Note: We need a way to load courses for a university.
      // UniversityBloc might need updating or we need a new Bloc/Cubit for this page.
      // For simplicity, let's assume we can trigger course loading here.
      child: const _CourseSelectionView(),
    );
  }
}

class _CourseSelectionView extends StatefulWidget {
  const _CourseSelectionView();

  @override
  State<_CourseSelectionView> createState() => _CourseSelectionViewState();
}

class _CourseSelectionViewState extends State<_CourseSelectionView> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserUniversity();
  }

  void _loadUserUniversity() async {
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
          context.read<UniversityBloc>().add(
            LoadUniversityCourses(universityId),
          );
        } else if (mounted) {
          setState(() {
            _errorMessage = 'No primary university found for your profile.';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load university profile.';
          });
        }
      }
    }
  }

  void _enrollInCourse(BuildContext context, String courseId) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<ProfileBloc>().add(
        EnrollUserInCourse(userId: userId, courseId: courseId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Your Course')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Course')),
      body: BlocBuilder<UniversityBloc, UniversityState>(
        builder: (context, state) {
          if (state is UniversityCoursesLoading || state is UniversityLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UniversityCoursesLoaded) {
            final courses = state.courses;
            if (courses.isEmpty) {
              return const Center(
                child: Text('No courses found for your university.'),
              );
            }

            return ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return ListTile(
                  title: Text(course.name),
                  subtitle: Text(course.code),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _enrollInCourse(context, course.id),
                );
              },
            );
          }

          if (state is UniversityError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          // Initial state - show loading while we fetch university ID
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

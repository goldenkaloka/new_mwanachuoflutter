import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/copilot/presentation/bloc/copilot_bloc.dart';
import 'package:mwanachuo/features/copilot/presentation/pages/copilot_dashboard_page.dart';
import 'package:mwanachuo/features/copilot/presentation/pages/course_selection_page.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_event.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CopilotWrapperPage extends StatefulWidget {
  const CopilotWrapperPage({super.key});

  @override
  State<CopilotWrapperPage> createState() => _CopilotWrapperPageState();
}

class _CopilotWrapperPageState extends State<CopilotWrapperPage> {
  @override
  void initState() {
    super.initState();
    _checkEnrollment();
  }

  void _checkEnrollment() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<ProfileBloc>().add(LoadEnrolledCourse(userId: userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileEnrolledCourseLoaded) {
          if (state.course != null) {
            return BlocProvider(
              create: (context) => sl<CopilotBloc>(),
              child: CopilotDashboardPage(courseId: state.course!.id),
            );
          } else {
            return const CourseSelectionPage();
          }
        }

        if (state is ProfileError) {
          // Retry button or error message
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  ElevatedButton(
                    onPressed: _checkEnrollment,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Ideally shouldn't happen, but show course selection as fallback
        return const CourseSelectionPage();
      },
    );
  }
}

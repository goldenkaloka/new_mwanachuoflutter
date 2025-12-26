import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bloc/bloc.dart';
import 'mwanachuomind_chat_page.dart';
import 'admin_upload_page.dart';
import '../widgets/mwanachuomind_shimmer.dart';

class CourseSelectionPage extends StatefulWidget {
  const CourseSelectionPage({super.key});

  @override
  State<CourseSelectionPage> createState() => _CourseSelectionPageState();
}

class _CourseSelectionPageState extends State<CourseSelectionPage> {
  String? _userRole;
  String? _universityId;
  String? _universityName;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadUserRole();
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

  Future<void> _loadUserRole() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final data = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', userId)
            .single();
        if (mounted) {
          setState(() {
            _userRole = data['role'] as String?;
          });
        }
      } catch (e) {
        debugPrint('Error fetching user role: $e');
      }
    }
  }

  Future<void> _loadCourses() async {
    // If university is already selected (e.g. by switcher), just load courses
    if (_universityId != null) {
      context.read<MwanachuomindBloc>().add(
        LoadUniversityCourses(_universityId!),
      );
      // Ensure name is loaded if missing
      if (_universityName == null) {
        final uniData = await Supabase.instance.client
            .from('universities')
            .select('name')
            .eq('id', _universityId!)
            .single();
        if (mounted) setState(() => _universityName = uniData['name']);
      }
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final data = await Supabase.instance.client
            .from('users')
            .select('primary_university_id, role')
            .eq('id', userId)
            .single();
        final universityId = data['primary_university_id'] as String?;
        final role = data['role'] as String?;

        if (universityId != null && mounted) {
          // Fetch university name
          final uniData = await Supabase.instance.client
              .from('universities')
              .select('name')
              .eq('id', universityId)
              .single();

          final universityName = uniData['name'] as String?;

          if (!mounted) return;

          setState(() {
            _universityId = universityId;
            _universityName = universityName;
            _userRole = role; // Ensure role is set
          });
          context.read<MwanachuomindBloc>().add(
            LoadUniversityCourses(universityId),
          );
        }
      } catch (e) {
        debugPrint('Error fetching user university: $e');
      }
    }
  }

  void _showUniversitySelector() async {
    try {
      final res = await Supabase.instance.client
          .from('universities')
          .select('id, name')
          .order('name');
      final universities = List<Map<String, dynamic>>.from(res);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Switch University'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: universities.length,
              itemBuilder: (ctx, i) {
                final uni = universities[i];
                return ListTile(
                  title: Text(uni['name']),
                  onTap: () {
                    setState(() {
                      _universityId = uni['id'];
                      _universityName = uni['name'];
                    });
                    _loadCourses(); // Reload courses for new university
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading universities: $e')),
        );
      }
    }
  }

  void _showAddCourseDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Add New Course\n${_universityName ?? ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Course Name'),
            ),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Course Code (e.g., CS101)',
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
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  codeController.text.isNotEmpty &&
                  _universityId != null) {
                context.read<MwanachuomindBloc>().add(
                  CreateCourse(
                    code: codeController.text,
                    name: nameController.text,
                    universityId: _universityId!,
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: (_userRole == 'admin') ? _showUniversitySelector : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Course', style: TextStyle(fontSize: 18)),
              if (_universityName != null)
                Row(
                  children: [
                    Text(
                      _universityName!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (_userRole == 'admin')
                      const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Course',
              onPressed: _showAddCourseDialog,
            ),
        ],
      ),
      floatingActionButton: (_userRole == 'admin' || _userRole == 'seller')
          ? FloatingActionButton.extended(
              onPressed: () {
                final bloc = context.read<MwanachuomindBloc>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: const AdminUploadPage(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Docs'),
            )
          : null,
      body: BlocBuilder<MwanachuomindBloc, MwanachuomindState>(
        builder: (context, state) {
          if (state.status == MwanachuomindStatus.loading &&
              state.courses.isEmpty) {
            return const MwanachuomindShimmer();
          }

          if (state.status == MwanachuomindStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }

          final filteredCourses = state.courses.where((course) {
            final name = course.name.toLowerCase();
            final code = course.code.toLowerCase();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || code.contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
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
              if (filteredCourses.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No courses found for your university.'
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
                          onTap: () {
                            context.read<MwanachuomindBloc>().add(
                              SelectCourse(course),
                            );
                            final bloc = context.read<MwanachuomindBloc>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: bloc,
                                  child: const MwanachuomindChatPage(),
                                ),
                              ),
                            );
                          },
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

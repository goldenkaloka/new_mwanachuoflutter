import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/config/supabase_config.dart';

class AdminRunnerManagementPage extends StatefulWidget {
  const AdminRunnerManagementPage({super.key});

  @override
  State<AdminRunnerManagementPage> createState() =>
      _AdminRunnerManagementPageState();
}

class _AdminRunnerManagementPageState extends State<AdminRunnerManagementPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final query = SupabaseConfig.client
          .from('users')
          .select('id, full_name, email, role, avatar_url')
          .order('full_name');

      final response = await query;
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRunnerRole(String userId, String currentRole) async {
    final newRole = currentRole == 'runner' ? 'buyer' : 'runner';
    try {
      await SupabaseConfig.client
          .from('users')
          .update({'role': newRole})
          .eq('id', userId);

      _fetchUsers(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User role updated to $newRole')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      final name = (user['full_name'] as String? ?? '').toLowerCase();
      final email = (user['email'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Runner Management',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isRunner = user['role'] == 'runner';
                      final isAdmin = user['role'] == 'admin';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['avatar_url'] != null
                              ? NetworkImage(user['avatar_url'])
                              : null,
                          child: user['avatar_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          user['full_name'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${user['email']}\nRole: ${user['role']}',
                        ),
                        trailing: isAdmin
                            ? const Chip(label: Text('ADMIN'))
                            : Switch(
                                value: isRunner,
                                onChanged: (_) =>
                                    _toggleRunnerRole(user['id'], user['role']),
                                activeColor: kPrimaryColor,
                              ),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

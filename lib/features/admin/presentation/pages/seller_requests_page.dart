import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';

class SellerRequestsPage extends StatefulWidget {
  const SellerRequestsPage({super.key});

  @override
  State<SellerRequestsPage> createState() => _SellerRequestsPageState();
}

class _SellerRequestsPageState extends State<SellerRequestsPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _selectedFilter = 'pending'; // pending, approved, rejected, all

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    try {
      final baseQuery = SupabaseConfig.client.from('seller_requests').select('''
            *,
            requester:users!seller_requests_user_id_fkey(id, full_name, email, avatar_url),
            reviewer:users!seller_requests_reviewed_by_fkey(id, full_name, email)
          ''');

      final filteredQuery = _selectedFilter != 'all'
          ? baseQuery.eq('status', _selectedFilter)
          : baseQuery;

      final data = await filteredQuery.order('created_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading requests: $e')));
      }
    }
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final requester = request['requester'] as Map<String, dynamic>?;
    final reviewer = request['reviewer'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
        title: Text(
          'Seller Request Details',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : kTextPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Requester',
                requester?['full_name'] ?? 'Unknown',
                isDarkMode,
              ),
              _buildDetailRow(
                'Email',
                requester?['email'] ?? 'N/A',
                isDarkMode,
              ),
              _buildDetailRow(
                'Status',
                request['status']?.toString().toUpperCase() ?? 'N/A',
                isDarkMode,
              ),
              _buildDetailRow(
                'Requested On',
                request['created_at'] != null
                    ? DateFormat(
                        'MMM d, yyyy \'at\' h:mm a',
                      ).format(DateTime.parse(request['created_at']))
                    : 'N/A',
                isDarkMode,
              ),
              const SizedBox(height: 12),
              Text(
                'Reason:',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : kTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                request['reason'] ?? 'No reason provided',
                style: GoogleFonts.plusJakartaSans(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              if (request['reviewed_at'] != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Reviewed On',
                  DateFormat(
                    'MMM d, yyyy \'at\' h:mm a',
                  ).format(DateTime.parse(request['reviewed_at'])),
                  isDarkMode,
                ),
                _buildDetailRow(
                  'Reviewed By',
                  reviewer?['full_name'] ?? 'Unknown',
                  isDarkMode,
                ),
                if (request['review_notes'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Review Notes:',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request['review_notes'],
                    style: GoogleFonts.plusJakartaSans(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          if (request['status'] == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRejectDialog(request);
              },
              child: Text(
                'Reject',
                style: GoogleFonts.plusJakartaSans(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showApproveDialog(request);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Approve', style: GoogleFonts.plusJakartaSans()),
            ),
          ] else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.plusJakartaSans()),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: isDarkMode ? Colors.white : kTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> request) {
    final notesController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
        title: Text(
          'Approve Seller Request',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : kTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Approve ${request['requester']?['full_name'] ?? 'this user'}\'s request to become a seller?',
              style: GoogleFonts.plusJakartaSans(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Optional notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans()),
          ),
          ElevatedButton(
            onPressed: () {
              final adminId = SupabaseConfig.client.auth.currentUser?.id;
              if (adminId != null) {
                context.read<AuthBloc>().add(
                  ApproveSellerRequestEvent(
                    requestId: request['id'],
                    adminId: adminId,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Approve', style: GoogleFonts.plusJakartaSans()),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> request) {
    final notesController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
        title: Text(
          'Reject Seller Request',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : kTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject ${request['requester']?['full_name'] ?? 'this user'}\'s request to become a seller?',
              style: GoogleFonts.plusJakartaSans(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection (recommended)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans()),
          ),
          ElevatedButton(
            onPressed: () {
              final adminId = SupabaseConfig.client.auth.currentUser?.id;
              if (adminId != null) {
                context.read<AuthBloc>().add(
                  RejectSellerRequestEvent(
                    requestId: request['id'],
                    adminId: adminId,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Reject', style: GoogleFonts.plusJakartaSans()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Seller Requests',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRequests),
        ],
      ),
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is SellerRequestApproved ||
              state is SellerRequestRejected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state is SellerRequestApproved
                      ? 'Request approved successfully!'
                      : 'Request rejected',
                ),
                backgroundColor: state is SellerRequestApproved
                    ? Colors.green
                    : Colors.orange,
              ),
            );
            _loadRequests();
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Filter tabs
            Container(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('Pending', 'pending', primaryTextColor),
                    const SizedBox(width: 8),
                    _buildFilterChip('Approved', 'approved', primaryTextColor),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', 'rejected', primaryTextColor),
                    const SizedBox(width: 8),
                    _buildFilterChip('All', 'all', primaryTextColor),
                  ],
                ),
              ),
            ),

            // Requests list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${_selectedFilter == 'all' ? '' : _selectedFilter} requests',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          final requester =
                              request['requester'] as Map<String, dynamic>?;
                          final status = request['status'] as String?;

                          return Card(
                            color: isDarkMode ? Colors.grey[900] : Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: kPrimaryColor,
                                backgroundImage:
                                    requester?['avatar_url'] != null
                                    ? NetworkImage(requester!['avatar_url'])
                                    : null,
                                child: requester?['avatar_url'] == null
                                    ? Text(
                                        (requester?['full_name'] ?? 'U')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                requester?['full_name'] ?? 'Unknown User',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  color: primaryTextColor,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    requester?['email'] ?? '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    request['created_at'] != null
                                        ? DateFormat('MMM d, yyyy').format(
                                            DateTime.parse(
                                              request['created_at'],
                                            ),
                                          )
                                        : 'Unknown date',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: status == 'pending'
                                      ? Colors.orange.withValues(alpha: 0.2)
                                      : status == 'approved'
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (status ?? 'Unknown').toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: status == 'pending'
                                        ? Colors.orange
                                        : status == 'approved'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                              onTap: () => _showRequestDetails(request),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color textColor) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: isSelected ? Colors.white : textColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _loadRequests();
        });
      },
      selectedColor: kPrimaryColor,
      backgroundColor: Colors.transparent,
      side: BorderSide(color: isSelected ? kPrimaryColor : Colors.grey[400]!),
    );
  }
}

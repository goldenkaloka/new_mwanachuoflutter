import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/wallet/domain/entities/manual_payment_request_entity.dart';
import 'package:mwanachuo/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:intl/intl.dart';

class WalletAdminPage extends StatefulWidget {
  const WalletAdminPage({super.key});

  @override
  State<WalletAdminPage> createState() => _WalletAdminPageState();
}

class _WalletAdminPageState extends State<WalletAdminPage> {
  @override
  void initState() {
    super.initState();
    // Load pending requests immediately
    context.read<WalletBloc>().add(LoadPendingManualPaymentRequests());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Verifications'),
        actions: [
          IconButton(
            onPressed: () => context.read<WalletBloc>().add(
              LoadPendingManualPaymentRequests(),
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is ManualPaymentApprovalSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment approved successfully!'),
                backgroundColor: kSuccessColor,
              ),
            );
          } else if (state is ManualPaymentRejectionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment rejected successfully'),
                backgroundColor: kSuccessColor,
              ),
            );
          } else if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: kErrorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WalletLoading ||
              state is ManualPaymentApprovalLoading ||
              state is ManualPaymentRejectionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WalletLoaded) {
            final pending = state.manualRequests
                .where((r) => r.status == PaymentRequestStatus.pending)
                .toList();

            if (pending.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text('No pending verifications'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(kSpacingLg),
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final req = pending[index];
                return _buildVerificationCard(context, req);
              },
            );
          }

          return const Center(child: Text('Load data to see verifications'));
        },
      ),
    );
  }

  Widget _buildVerificationCard(
    BuildContext context,
    ManualPaymentRequestEntity req,
  ) {
    // ... existing UI code ...
    return Card(
      margin: const EdgeInsets.only(bottom: kSpacingLg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
        side: BorderSide(color: kBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kSpacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TZS ${req.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                Text(
                  req.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('User ID', req.userId),
            _buildInfoRow('Transaction Ref', req.transactionRef),
            _buildInfoRow('Payer Phone', req.payerPhone ?? 'N/A'),
            _buildInfoRow(
              'Submitted',
              DateFormat('MMM d, HH:mm').format(req.createdAt.toLocal()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(context, req.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kErrorColor,
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: kSpacingMd),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showApproveDialog(context, req.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, String requestId) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payment'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Admin Note (Optional)',
            hintText: 'e.g. Verified via M-Pesa',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<WalletBloc>().add(
                ApproveManualPaymentEvent(
                  requestId: requestId,
                  adminNote: noteController.text.trim(),
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String requestId) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payment'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Reason (Optional)',
            hintText: 'e.g. Invalid transaction ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<WalletBloc>().add(
                RejectManualPaymentEvent(
                  requestId: requestId,
                  adminNote: noteController.text.trim(),
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/wallet/presentation/bloc/wallet_bloc.dart';

class ManualPaymentPage extends StatefulWidget {
  final String type; // 'topup', 'subscription', 'promotion'

  const ManualPaymentPage({super.key, this.type = 'topup'});

  @override
  State<ManualPaymentPage> createState() => _ManualPaymentPageState();
}

class _ManualPaymentPageState extends State<ManualPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _txnRefController = TextEditingController();
  final _phoneController = TextEditingController();

  final String _paymentNumber = '0616622485';
  final String _paymentName = 'Clement Kaloka';

  @override
  void dispose() {
    _amountController.dispose();
    _txnRefController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _paymentNumber)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Number copied to clipboard')),
      );
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<WalletBloc>().add(
        SubmitPaymentProofEvent(
          amount: double.parse(_amountController.text),
          transactionRef: _txnRefController.text.trim(),
          payerPhone: _phoneController.text.trim(),
          type: widget.type,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Payment'), centerTitle: true),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is PaymentProofSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Proof submitted successfully! Awaiting verification.',
                ),
                backgroundColor: kSuccessColor,
              ),
            );
            Navigator.pop(context);
          } else if (state is PaymentProofSubmissionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: kErrorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(kSpacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionsCard(),
                const SizedBox(height: kSpacing2xl),
                _buildForm(state is PaymentProofSubmitting),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 0,
      color: kPrimaryColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
        side: const BorderSide(color: kPrimaryColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kSpacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: kPrimaryColor),
                const SizedBox(width: kSpacingSm),
                Text(
                  'How to pay',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpacingMd),
            const Text(
              '1. Send the payment amount via M-Pesa, Tigo Pesa, or Airtel Money to:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: kSpacingMd),
            Container(
              padding: const EdgeInsets.all(kSpacingMd),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kRadiusSm),
                border: Border.all(color: kBorderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _paymentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _paymentNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            letterSpacing: 1.2,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy, color: kPrimaryColor),
                    tooltip: 'Copy Number',
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSpacingMd),
            const Text(
              '2. Once you receive the confirmation SMS, enter the details below to submit your proof.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submission Form',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: kSpacingLg),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (TZS)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
              hintText: 'e.g. 5000',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the amount';
              }
              if (double.tryParse(value) == null) return 'Invalid amount';
              if (double.parse(value) <= 0) {
                return 'Amount must be greater than 0';
              }
              return null;
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: kSpacingLg),
          TextFormField(
            controller: _txnRefController,
            decoration: const InputDecoration(
              labelText: 'Transaction Reference / ID',
              prefixIcon: Icon(Icons.receipt_long),
              border: OutlineInputBorder(),
              hintText: 'e.g. 5G789X...',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the transaction ID';
              }
              if (value.length < 5) return 'ID seems too short';
              return null;
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: kSpacingLg),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Your Payer Phone Number',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
              hintText: '07XXXXXXXX',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (!RegExp(r'^0[67]\d{8}$').hasMatch(value)) {
                return 'Invalid Tanzanian phone number';
              }
              return null;
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: kSpacing2xl),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Submit Proof',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: kSpacingMd),
          const Center(
            child: Text(
              'Verification usually takes 5-15 minutes.',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

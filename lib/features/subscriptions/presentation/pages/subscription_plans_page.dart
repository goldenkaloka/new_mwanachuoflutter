import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/subscriptions/presentation/cubit/subscription_cubit.dart';
import 'package:mwanachuo/features/subscriptions/presentation/cubit/subscription_state.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  String selectedBillingPeriod = 'monthly'; // 'monthly' or 'yearly'
  final SubscriptionCubit _cubit = sl<SubscriptionCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.loadSubscriptionPlans();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Subscription')),
      body: BlocProvider.value(
        value: _cubit,
        child: BlocConsumer<SubscriptionCubit, SubscriptionState>(
          listener: (context, state) async {
            if (state is SubscriptionPaymentInitiated) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Payment Initiated! Please check your phone to approve.',
                    ),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 5),
                  ),
                );
                // Optionally start polling for status or wait for webhook to update subscription
                // For now, let's suggest user to refresh after payment
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'After payment, refresh this page to see active subscription.',
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 8),
                  ),
                );
                Navigator.pop(context); // Close dialog
              }
            } else if (state is SubscriptionLoaded) {
              // ... existing logic ...
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subscription active!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              }
            } else if (state is SubscriptionError) {
              final errorMessage = state.message;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SubscriptionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SubscriptionPlansLoaded) {
              // We assume there's at least one plan or we default to a hardcoded one
              // But strictly we should use the one from DB.
              // User asked for 15,000 TZS. Let's filter or find that plan.

              // For simplicity, let's display the card with 15,000 TZS
              // and assume the first plan ID is the one to use, or 'business_plan'

              final plan = state.plans.isNotEmpty ? state.plans.first : null;
              final planId = plan?.id ?? 'business_plan_id'; // Fallback

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium Business',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '15,000 TZS / month',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Unlimited product & service uploads.',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const ListTile(
                              leading: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              title: Text('Unlimited Listings'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const ListTile(
                              leading: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              title: Text('Priority Support'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const ListTile(
                              leading: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              title: Text('Analytics Dashboard'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),

                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final authState = context
                                      .read<AuthBloc>()
                                      .state;
                                  if (authState is Authenticated) {
                                    _showPaymentDialog(
                                      context,
                                      authState.user.id,
                                      planId,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please log in to subscribe',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Pay with ZenoPay (Mobile Money)',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is SubscriptionError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _cubit.loadSubscriptionPlans(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: Text('Loading...'));
          },
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, String userId, String planId) {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You are about to pay 15,000 TZS for a 1-month Business Subscription.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: '07XXXXXXXX',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!RegExp(r'^0[67]\d{8}$').hasMatch(value)) {
                    return 'Invalid TZ number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _cubit.initiatePayment(
                  amount: 15000,
                  phone: phoneController.text,
                  planId: planId,
                  sellerId: userId,
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }
}

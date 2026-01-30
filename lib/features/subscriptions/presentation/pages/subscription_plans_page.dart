import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
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
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: BlocProvider.value(
        value: _cubit,
        child: BlocConsumer<SubscriptionCubit, SubscriptionState>(
          listener: (context, state) async {
            if (state is SubscriptionLoaded) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subscription successfully activated!'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh auth state or navigate home
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  _cubit.loadSellerSubscription(authState.user.id);
                }
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
              if (state.plans.isEmpty) {
                return const Center(
                  child: Text('No subscription plans available'),
                );
              }

              final plan = state.plans.first;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Monthly'),
                          selected: selectedBillingPeriod == 'monthly',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedBillingPeriod = 'monthly');
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text('Yearly'),
                          selected: selectedBillingPeriod == 'yearly',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedBillingPeriod = 'yearly');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selectedBillingPeriod == 'monthly'
                                  ? '\$${plan.priceMonthly.toStringAsFixed(2)}/month'
                                  : '\$${plan.priceYearly.toStringAsFixed(2)}/year',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                            if (selectedBillingPeriod == 'yearly') ...[
                              const SizedBox(height: 8),
                              Text(
                                'Save \$${((plan.priceMonthly * 12) - plan.priceYearly).toStringAsFixed(2)} per year!',
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              plan.maxListings != null
                                  ? 'Up to ${plan.maxListings} listings'
                                  : 'Unlimited listings',
                            ),
                            const SizedBox(height: 8),
                            const Text('All features included'),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final authState = context
                                      .read<AuthBloc>()
                                      .state;
                                  if (authState is Authenticated) {
                                    _cubit.subscribe(
                                      sellerId: authState.user.id,
                                      planId: plan.id,
                                      billingPeriod: selectedBillingPeriod,
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
                                ),
                                child: const Text('Subscribe Now'),
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
}

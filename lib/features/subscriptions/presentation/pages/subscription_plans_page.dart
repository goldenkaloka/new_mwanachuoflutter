import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/subscriptions/presentation/cubit/subscription_cubit.dart';
import 'package:mwanachuo/features/subscriptions/presentation/cubit/subscription_state.dart';
import 'package:url_launcher/url_launcher.dart';

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
            if (state is StripePaymentDataReady) {
              final data = state.data;
              final isMobile =
                  !kIsWeb && (Platform.isAndroid || Platform.isIOS);

              // 1. Native Stripe Payment Sheet logic - Prioritized only on supported mobile platforms
              if (isMobile &&
                  data.containsKey('paymentIntent') &&
                  data['paymentIntent'] != null) {
                try {
                  // Initialize Payment Sheet
                  await Stripe.instance.initPaymentSheet(
                    paymentSheetParameters: SetupPaymentSheetParameters(
                      paymentIntentClientSecret: data['paymentIntent'],
                      customerEphemeralKeySecret: data['ephemeralKey'],
                      customerId: data['customer'],
                      merchantDisplayName: 'Mwanachuo',
                      style: Theme.of(context).brightness == Brightness.dark
                          ? ThemeMode.dark
                          : ThemeMode.light,
                      appearance: const PaymentSheetAppearance(
                        colors: PaymentSheetAppearanceColors(
                          primary: kPrimaryColor,
                        ),
                      ),
                    ),
                  );

                  // Display Payment Sheet
                  await Stripe.instance.presentPaymentSheet();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment successful!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    final authState = context.read<AuthBloc>().state;
                    if (authState is Authenticated) {
                      _cubit.loadSellerSubscription(authState.user.id);
                    }
                  }
                  return; // Exit on success
                } catch (e) {
                  if (e is StripeException) {
                    if (e.error.code == FailureCode.Canceled) {
                      debugPrint('Payment Sheet cancelled by user');
                      return;
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Stripe Error: ${e.error.localizedMessage}',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  // For other errors, we might want to try the web fallback if available
                }
              }

              // 2. Fallback for old checkout URL - Use ONLY if native flow is unavailable or failed
              if (data.containsKey('checkout_url') &&
                  data['checkout_url'] != null) {
                try {
                  final uri = Uri.parse(data['checkout_url']);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open checkout page'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening checkout: $e')),
                    );
                  }
                }
              }
            } else if (state is SubscriptionError) {
              final errorMessage = state.message;
              final isStripeConfigError =
                  errorMessage.toLowerCase().contains(
                    'stripe not configured',
                  ) ||
                  errorMessage.toLowerCase().contains('stripe_secret_key');

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isStripeConfigError
                        ? 'Stripe not configured. Please add STRIPE_SECRET_KEY to Supabase Edge Function secrets.'
                        : errorMessage,
                  ),
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
                                    _cubit.createCheckout(
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

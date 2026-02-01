import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/wallet/presentation/bloc/wallet_bloc.dart';
// import 'package:mwanachuo/features/wallet/presentation/bloc/wallet_state.dart'; // Removed
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<WalletBloc>()..add(LoadWalletData()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Wallet'),
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Top-Ups'),
              Tab(text: 'Fees'),
            ],
          ),
        ),
        body: BlocConsumer<WalletBloc, WalletState>(
          listener: (context, state) {
            if (state is WalletTopUpInitiated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Top-up initiated! Check your phone.'),
                ),
              );
            } else if (state is WalletError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is WalletLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is WalletLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildWalletContent(context, state, 'all'),
                  _buildWalletContent(context, state, 'credit'),
                  _buildWalletContent(context, state, 'debit'),
                ],
              );
            }
            return const Center(child: Text('Something went wrong'));
          },
        ),
      ),
    );
  }

  Widget _buildWalletContent(
    BuildContext context,
    WalletLoaded state,
    String filter,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<WalletBloc>().add(LoadWalletData());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBalanceCard(context, state),
            const SizedBox(height: 24),
            Text(
              filter == 'all'
                  ? 'All Transactions'
                  : filter == 'credit'
                  ? 'Top-Up History'
                  : 'Fee History',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTransactionsList(state, filter),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, WalletLoaded state) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'TZS ',
      decimalDigits: 2,
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008080), Color(0xFF004D4D)], // Teal gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(state.wallet.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showTopUpDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Top Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(WalletLoaded state, String filter) {
    // Filter transactions based on type
    final filteredTransactions = state.transactions.where((tx) {
      if (filter == 'all') return true;
      if (filter == 'credit') return tx.isCredit;
      if (filter == 'debit') return !tx.isCredit;
      return true;
    }).toList();

    if (filteredTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No transactions yet'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        final isCredit = transaction.isCredit;
        final amountFormat = NumberFormat.currency(
          symbol: '',
          decimalDigits: 2,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCredit
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              transaction.description ?? 'Transaction',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              DateFormat(
                'MMM d, yyyy • HH:mm',
              ).format(transaction.createdAt.toLocal()),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: Text(
              '${isCredit ? '+' : ''}${amountFormat.format(transaction.amount)}',
              style: TextStyle(
                color: isCredit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTopUpDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedProvider;

    final providers = [
      {'label': 'mixx by yass', 'value': 'TIGOPESA'},
      {'label': 'Vodacom', 'value': 'M-PESA'},
      {'label': 'Airtel', 'value': 'AIRTEL MONEY'},
      {'label': 'Halopesa', 'value': 'HALOPESA'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setState) => AlertDialog(
          title: const Text('Top Up Wallet'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedProvider,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Provider',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: providers.map((provider) {
                      return DropdownMenuItem(
                        value: provider['value'],
                        child: Text(provider['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProvider = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a provider' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      hintText: '07XXXXXXXX',
                      prefixIcon: Icon(Icons.phone),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (TZS)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) {
                        return 'Invalid amount';
                      }
                      if (double.parse(value) < 1000) return 'Min 1000 TZS';
                      return null;
                    },
                  ),
                ],
              ),
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
                  context.read<WalletBloc>().add(
                    InitiateWalletTopUp(
                      amount: double.parse(
                        amountController.text.replaceAll(',', ''),
                      ),
                      phone: phoneController.text.replaceAll(
                        RegExp(r'\s+'),
                        '',
                      ),
                      provider: selectedProvider!,
                    ),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Pay with ZenoPay'),
            ),
          ],
        ),
      ),
    );
  }
}

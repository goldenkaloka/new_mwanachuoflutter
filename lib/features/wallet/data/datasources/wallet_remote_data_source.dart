import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/wallet/data/models/wallet_model.dart';
import 'package:mwanachuo/features/wallet/data/models/wallet_transaction_model.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWallet();
  Future<List<WalletTransactionModel>> getTransactions();
  Future<String> initiateTopUp({
    required double amount,
    required String phone,
    required String provider,
  });
  Future<void> deductBalance({
    required double amount,
    required String description,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final SupabaseClient supabaseClient;

  WalletRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<WalletModel> getWallet() async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;
      final response = await supabaseClient
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle(); // Use maybeSingle instead of single to avoid errors if not found

      // If wallet doesn't exist, return default wallet
      if (response == null) {
        return WalletModel(
          userId: userId,
          balance: 0.0,
          currency: 'TZS',
          updatedAt: DateTime.now(),
        );
      }

      return WalletModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Handle specific Postgres errors
      if (e.code == 'PGRST116') {
        // No rows returned, wallet doesn't exist
        return WalletModel(
          userId: supabaseClient.auth.currentUser!.id,
          balance: 0.0,
          currency: 'TZS',
          updatedAt: DateTime.now(),
        );
      }
      throw ServerException('Database Error: ${e.message}');
    } catch (e) {
      // Catch any other errors
      throw ServerException('Failed to fetch wallet: $e');
    }
  }

  @override
  Future<List<WalletTransactionModel>> getTransactions() async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;
      final response = await supabaseClient
          .from('wallet_transactions')
          .select()
          .eq('wallet_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => WalletTransactionModel.fromJson(e))
          .toList();
    } catch (e) {
      throw const ServerException('Failed to fetch transactions');
    }
  }

  @override
  Future<String> initiateTopUp({
    required double amount,
    required String phone,
    required String provider,
  }) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'zenopay-payment',
        body: {
          'amount': amount,
          'phone': phone,
          'type': 'wallet_topup',
          'provider': provider,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final message =
            errorData != null &&
                errorData is Map &&
                errorData.containsKey('error')
            ? errorData['error'].toString()
            : 'Payment initiation failed (${response.status})';
        throw ServerException(message);
      }

      final data = response.data;
      if (data == null || data['order_id'] == null) {
        throw const ServerException('Invalid response from payment server');
      }
      return data['order_id'];
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to initiate payment: $e');
    }
  }

  @override
  Future<void> deductBalance({
    required double amount,
    required String description,
  }) async {
    try {
      await supabaseClient.rpc(
        'deduct_wallet_balance',
        params: {
          'user_id': supabaseClient.auth.currentUser!.id,
          'amount': amount,
          'description': description,
        },
      );
    } catch (e) {
      if (e is PostgrestException) {
        throw ServerException(e.message);
      }
      throw const ServerException('Failed to deduct balance');
    }
  }
}

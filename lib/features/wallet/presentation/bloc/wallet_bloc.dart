import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:mwanachuo/features/wallet/domain/entities/wallet_transaction_entity.dart';
import 'package:mwanachuo/features/wallet/domain/usecases/get_wallet.dart';
import 'package:mwanachuo/features/wallet/domain/usecases/get_wallet_transactions.dart';
import 'package:mwanachuo/features/wallet/domain/usecases/initiate_top_up.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWallet getWallet;
  final GetWalletTransactions getWalletTransactions;
  final InitiateTopUp initiateTopUp;

  WalletBloc({
    required this.getWallet,
    required this.getWalletTransactions,
    required this.initiateTopUp,
  }) : super(WalletInitial()) {
    on<LoadWalletData>(_onLoadWalletData);
    on<InitiateWalletTopUp>(_onInitiateWalletTopUp);
  }

  Future<void> _onLoadWalletData(
    LoadWalletData event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());

    // Fetch Wallet and Transactions in parallel
    final walletFuture = getWallet(NoParams());
    final transactionsFuture = getWalletTransactions(NoParams());

    final results = await Future.wait([walletFuture, transactionsFuture]);

    final walletResult = results[0];
    final transactionsResult = results[1];

    walletResult.fold((failure) => emit(WalletError(failure.message)), (
      wallet,
    ) {
      transactionsResult.fold(
        (failure) => emit(
          WalletLoaded(
            wallet: wallet as WalletEntity,
            transactions:
                const [], // Optionally handle transaction failure separately
          ),
        ),
        (transactions) => emit(
          WalletLoaded(
            wallet: wallet as WalletEntity,
            transactions: transactions as List<WalletTransactionEntity>,
          ),
        ),
      );
    });
  }

  Future<void> _onInitiateWalletTopUp(
    InitiateWalletTopUp event,
    Emitter<WalletState> emit,
  ) async {
    // Keep current state but show loading overlay if possible, or new state
    // For simplicity, we assume the UI handles the loading state for the button

    final currentState = state;
    WalletEntity? currentWallet;
    List<WalletTransactionEntity> currentTransactions = [];

    if (currentState is WalletLoaded) {
      currentWallet = currentState.wallet;
      currentTransactions = currentState.transactions;
    } else if (currentState is WalletTopUpFailure) {
      currentWallet = currentState.wallet;
      currentTransactions = currentState.transactions;
    } else if (currentState is WalletTopUpInitiated) {
      currentWallet = currentState.wallet;
      currentTransactions = currentState.transactions;
    }

    if (currentWallet == null) {
      emit(
        WalletTopUpFailure(
          message: 'Wallet not loaded',
          wallet: WalletEntity(
            userId: '',
            balance: 0,
            currency: 'TZS',
            updatedAt: DateTime.now(),
          ),
          transactions: const [],
        ),
      );
      return;
    }

    final result = await initiateTopUp(
      InitiateTopUpParams(
        amount: event.amount,
        phone: event.phone,
        provider: event.provider,
      ),
    );

    result.fold(
      (failure) => emit(
        WalletTopUpFailure(
          message: failure.message,
          wallet: currentWallet!,
          transactions: currentTransactions,
        ),
      ),
      (orderId) => emit(
        WalletTopUpInitiated(
          orderId: orderId,
          wallet: currentWallet!,
          transactions: currentTransactions,
        ),
      ),
    );
    // Reload data after a short delay or let user pull to refresh?
    // Ideally, we wait for webhook, but here we just initiated.
  }
}

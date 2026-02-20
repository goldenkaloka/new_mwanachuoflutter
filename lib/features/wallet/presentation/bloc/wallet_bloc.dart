import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:mwanachuo/features/wallet/domain/entities/wallet_transaction_entity.dart';
import 'package:mwanachuo/features/wallet/domain/entities/manual_payment_request_entity.dart';
import 'package:mwanachuo/features/wallet/domain/usecases/get_manual_payment_requests.dart';
import 'package:mwanachuo/features/wallet/domain/usecases/get_wallet.dart';
import 'package:mwanachuo/features/wallet/domain/usecases/get_wallet_transactions.dart';
import 'package:mwanachuo/features/wallet/domain/usecases/initiate_top_up.dart';
import 'package:mwanachuo/features/wallet/domain/usecases/submit_payment_proof.dart';
import 'package:mwanachuo/features/wallet/domain/usecases/approve_manual_payment.dart';
import 'package:mwanachuo/features/wallet/domain/usecases/reject_manual_payment.dart';
import 'package:mwanachuo/features/wallet/domain/usecases/get_pending_manual_payment_requests.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWallet getWallet;
  final GetWalletTransactions getWalletTransactions;
  final InitiateTopUp initiateTopUp;
  final SubmitPaymentProof submitPaymentProof;
  final GetManualPaymentRequests getManualPaymentRequests;
  final ApproveManualPayment approveManualPayment;
  final RejectManualPayment rejectManualPayment;
  final GetPendingManualPaymentRequests getPendingManualPaymentRequests;

  WalletBloc({
    required this.getWallet,
    required this.getWalletTransactions,
    required this.initiateTopUp,
    required this.submitPaymentProof,
    required this.getManualPaymentRequests,
    required this.approveManualPayment,
    required this.rejectManualPayment,
    required this.getPendingManualPaymentRequests,
  }) : super(WalletInitial()) {
    on<LoadWalletData>(_onLoadWalletData);
    on<InitiateWalletTopUp>(_onInitiateWalletTopUp);
    on<SubmitPaymentProofEvent>(_onSubmitPaymentProof);
    on<LoadManualPaymentRequests>(_onLoadManualPaymentRequests);
    on<LoadPendingManualPaymentRequests>(_onLoadPendingManualPaymentRequests);
    on<ApproveManualPaymentEvent>(_onApproveManualPayment);
    on<RejectManualPaymentEvent>(_onRejectManualPayment);
  }

  Future<void> _onLoadWalletData(
    LoadWalletData event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());

    // Fetch Wallet, Transactions, and Manual Requests in parallel
    final walletFuture = getWallet(NoParams());
    final transactionsFuture = getWalletTransactions(NoParams());
    final manualRequestsFuture = getManualPaymentRequests(NoParams());

    final results = await Future.wait([
      walletFuture,
      transactionsFuture,
      manualRequestsFuture,
    ]);

    final walletResult = results[0];
    final transactionsResult = results[1];
    final manualRequestsResult = results[2];

    walletResult.fold((failure) => emit(WalletError(failure.message)), (
      wallet,
    ) {
      final List<WalletTransactionEntity> transactions = transactionsResult
          .fold(
            (failure) => [],
            (data) => data as List<WalletTransactionEntity>,
          );

      final List<ManualPaymentRequestEntity> manualRequests =
          manualRequestsResult.fold(
            (failure) => [],
            (data) => data as List<ManualPaymentRequestEntity>,
          );

      emit(
        WalletLoaded(
          wallet: wallet as WalletEntity,
          transactions: transactions,
          manualRequests: manualRequests,
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

  Future<void> _onSubmitPaymentProof(
    SubmitPaymentProofEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(PaymentProofSubmitting());

    final result = await submitPaymentProof(
      SubmitPaymentProofParams(
        amount: event.amount,
        transactionRef: event.transactionRef,
        payerPhone: event.payerPhone,
        type: event.type,
        metadata: event.metadata,
      ),
    );

    result.fold(
      (failure) => emit(PaymentProofSubmissionError(failure.message)),
      (request) {
        emit(PaymentProofSubmitted(request));
        add(LoadWalletData()); // Refresh to show new request
      },
    );
  }

  Future<void> _onLoadManualPaymentRequests(
    LoadManualPaymentRequests event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;
    if (currentState is WalletLoaded) {
      final result = await getManualPaymentRequests(NoParams());
      result.fold(
        (failure) => emit(WalletError(failure.message)),
        (requests) => emit(currentState.copyWith(manualRequests: requests)),
      );
    }
  }

  Future<void> _onApproveManualPayment(
    ApproveManualPaymentEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(ManualPaymentApprovalLoading());

    final result = await approveManualPayment(
      ApproveManualPaymentParams(
        requestId: event.requestId,
        adminNote: event.adminNote,
      ),
    );

    result.fold((failure) => emit(WalletError(failure.message)), (_) {
      emit(ManualPaymentApprovalSuccess());
      // Refresh personal data (wallet/history)
      add(LoadWalletData());
      // Refresh pending list for admin
      add(LoadPendingManualPaymentRequests());
    });
  }

  Future<void> _onRejectManualPayment(
    RejectManualPaymentEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(ManualPaymentRejectionLoading());

    final result = await rejectManualPayment(
      RejectManualPaymentParams(
        requestId: event.requestId,
        adminNote: event.adminNote,
      ),
    );

    result.fold((failure) => emit(WalletError(failure.message)), (_) {
      emit(ManualPaymentRejectionSuccess());
      // Refresh personal data
      add(LoadWalletData());
      // Refresh pending list for admin
      add(LoadPendingManualPaymentRequests());
    });
  }

  Future<void> _onLoadPendingManualPaymentRequests(
    LoadPendingManualPaymentRequests event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;
    if (currentState is WalletLoaded) {
      final result = await getPendingManualPaymentRequests(NoParams());
      result.fold(
        (failure) => emit(WalletError(failure.message)),
        (requests) => emit(currentState.copyWith(manualRequests: requests)),
      );
    }
  }
}

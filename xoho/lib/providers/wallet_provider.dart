import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PaymentMethod { mtnMomo, moovMoney }

enum TransactionType { credit, debit, escrow, release }

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    this.reference,
  });

  final String id;
  final int amount;
  final TransactionType type;
  final String description;
  final DateTime date;
  final String? reference;

  bool get isCredit =>
      type == TransactionType.credit || type == TransactionType.release;
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier();
});

class WalletState {
  const WalletState({
    this.balance = 0,
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  final int balance;
  final List<WalletTransaction> transactions;
  final bool isLoading;
  final String? error;

  WalletState copyWith({
    int? balance,
    List<WalletTransaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(const WalletState()) {
    _loadDemoData();
  }

  void _loadDemoData() {
    state = state.copyWith(
      balance: 12500,
      transactions: [
        WalletTransaction(
          id: 'txn_001',
          amount: 3200,
          type: TransactionType.credit,
          description: 'Livraison Cotonou → Bohicon',
          date: DateTime.now().subtract(const Duration(days: 1)),
          reference: 'shp_001',
        ),
        WalletTransaction(
          id: 'txn_002',
          amount: 100,
          type: TransactionType.debit,
          description: 'Déblocage contact livreur',
          date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        ),
        WalletTransaction(
          id: 'txn_003',
          amount: 5000,
          type: TransactionType.credit,
          description: 'Recharge MTN MoMo',
          date: DateTime.now().subtract(const Duration(days: 3)),
          reference: 'MOMO_TXN_2024',
        ),
        WalletTransaction(
          id: 'txn_004',
          amount: 500,
          type: TransactionType.debit,
          description: 'Assurance Xoho Premium',
          date: DateTime.now().subtract(const Duration(days: 4)),
          reference: 'shp_002',
        ),
      ],
    );
  }

  Future<void> topUp({
    required int amount,
    required PaymentMethod method,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 3));
    // TODO: integrate MTN MoMo / Moov Money API

    final txn = WalletTransaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      type: TransactionType.credit,
      description:
          'Recharge ${method == PaymentMethod.mtnMomo ? 'MTN MoMo' : 'Moov Money'}',
      date: DateTime.now(),
    );

    state = state.copyWith(
      balance: state.balance + amount,
      transactions: [txn, ...state.transactions],
      isLoading: false,
    );
  }

  Future<bool> deduct(int amount, String description) async {
    if (state.balance < amount) return false;
    final txn = WalletTransaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      type: TransactionType.debit,
      description: description,
      date: DateTime.now(),
    );
    state = state.copyWith(
      balance: state.balance - amount,
      transactions: [txn, ...state.transactions],
    );
    return true;
  }
}

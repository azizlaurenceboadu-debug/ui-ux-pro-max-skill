import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/xoho_button.dart';
import '../../../../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  void _showTopUpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _TopUpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      body: XohoBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Text('Portefeuille', style: AppTextStyles.headingMD),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Balance card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF47920),
                              Color(0xFFFF6B00),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white70,
                                    size: 20),
                                const SizedBox(width: 8),
                                Text('Solde disponible',
                                    style: AppTextStyles.bodyMD
                                        .copyWith(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${wallet.balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} F CFA',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _WalletAction(
                                    icon: Icons.add_rounded,
                                    label: 'Recharger',
                                    onTap: _showTopUpSheet,
                                    bgColor: Colors.white24,
                                    fgColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _WalletAction(
                                    icon: Icons.send_rounded,
                                    label: 'Retirer',
                                    onTap: () {},
                                    bgColor: Colors.white24,
                                    fgColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _WalletAction(
                                    icon: Icons.history_rounded,
                                    label: 'Historique',
                                    onTap: () {},
                                    bgColor: Colors.white24,
                                    fgColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Payment methods
                      Row(
                        children: [
                          Text('Méthodes de paiement',
                              style: AppTextStyles.headingSM),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.mtnYellow,
                                    ),
                                    child: const Center(
                                      child: Text('MTN',
                                          style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('MTN MoMo',
                                          style: AppTextStyles.headingSM),
                                      Text('Lié',
                                          style: AppTextStyles.caption
                                              .copyWith(
                                                  color: AppColors.success)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.moovBlue,
                                    ),
                                    child: const Center(
                                      child: Text('MOOV',
                                          style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Moov Money',
                                          style: AppTextStyles.headingSM),
                                      Text('Ajouter',
                                          style: AppTextStyles.caption
                                              .copyWith(
                                                  color:
                                                      AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Transactions
                      Row(
                        children: [
                          Text('Transactions récentes',
                              style: AppTextStyles.headingSM),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ...wallet.transactions.map((txn) => _TransactionRow(txn: txn)),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.bgColor,
    required this.fgColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: fgColor, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style:
                    AppTextStyles.caption.copyWith(color: fgColor)),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.txn});
  final WalletTransaction txn;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: txn.isCredit
                  ? AppColors.successBg
                  : AppColors.errorBg,
            ),
            child: Icon(
              txn.isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 18,
              color: txn.isCredit ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.description, style: AppTextStyles.headingSM),
                Text(
                  '${txn.date.day}/${txn.date.month}/${txn.date.year} à ${txn.date.hour}h${txn.date.minute.toString().padLeft(2, '0')}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            '${txn.isCredit ? '+' : '-'}${txn.amount} F',
            style: AppTextStyles.priceSM.copyWith(
              color: txn.isCredit ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopUpSheet extends ConsumerStatefulWidget {
  const _TopUpSheet();

  @override
  ConsumerState<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<_TopUpSheet> {
  int _amount = 5000;
  PaymentMethod _method = PaymentMethod.mtnMomo;
  bool _isLoading = false;

  static const _presets = [1000, 2000, 5000, 10000, 20000, 50000];

  Future<void> _topUp() async {
    setState(() => _isLoading = true);
    await ref.read(walletProvider.notifier).topUp(
          amount: _amount,
          method: _method,
          phoneNumber: '+22997000000',
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recharger le portefeuille',
              style: AppTextStyles.headingLG),
          const SizedBox(height: 24),
          Text('Montant', style: AppTextStyles.labelLG),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((p) {
              final isSelected = _amount == p;
              return GestureDetector(
                onTap: () => setState(() => _amount = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.bgElevated,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '$p F',
                    style: AppTextStyles.labelLG.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Méthode de paiement', style: AppTextStyles.labelLG),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MethodTile(
                  label: 'MTN MoMo',
                  color: AppColors.mtnYellow,
                  textColor: Colors.black,
                  selected: _method == PaymentMethod.mtnMomo,
                  onTap: () =>
                      setState(() => _method = PaymentMethod.mtnMomo),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MethodTile(
                  label: 'Moov Money',
                  color: AppColors.moovBlue,
                  textColor: Colors.white,
                  selected: _method == PaymentMethod.moovMoney,
                  onTap: () =>
                      setState(() => _method = PaymentMethod.moovMoney),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          XohoButton(
            label: 'Payer $_amount F CFA',
            onPressed: _topUp,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.label,
    required this.color,
    required this.textColor,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final Color textColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? color : AppColors.bgElevated,
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelLG.copyWith(
              color: selected ? textColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

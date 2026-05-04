import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/xoho_button.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

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
                    Text('Mon profil', style: AppTextStyles.headingMD),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Avatar + info
                      Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withOpacity(0.3),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    user.initials,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.bgCard,
                                    border: Border.all(
                                        color: AppColors.border, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(user.fullName,
                              style: AppTextStyles.headingXL),
                          const SizedBox(height: 4),
                          Text(user.phone,
                              style: AppTextStyles.bodyMD),
                          const SizedBox(height: 12),
                          _KycBadge(status: user.kycStatus),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    user.rating.toStringAsFixed(1),
                                    style: AppTextStyles.price,
                                  ),
                                  const Icon(Icons.star_rounded,
                                      color: AppColors.starGold, size: 16),
                                  const SizedBox(height: 2),
                                  Text('Note', style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '${user.totalDeliveries}',
                                    style: AppTextStyles.price,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Livraisons',
                                      style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    user.role == UserRole.sender
                                        ? 'Expéditeur'
                                        : user.role == UserRole.driver
                                            ? 'Livreur'
                                            : 'Les deux',
                                    style: AppTextStyles.labelLG
                                        .copyWith(color: AppColors.primary),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Rôle', style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Menu items
                      ...[
                        _MenuItem(
                          icon: Icons.verified_user_rounded,
                          label: 'Vérification d\'identité (KYC)',
                          badge: user.kycStatus == KycStatus.none
                              ? 'Requis'
                              : null,
                          badgeColor: AppColors.warning,
                          onTap: () => context.push('/kyc'),
                        ),
                        _MenuItem(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Mon portefeuille',
                          onTap: () => context.push('/wallet'),
                        ),
                        _MenuItem(
                          icon: Icons.history_rounded,
                          label: 'Historique des livraisons',
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.notifications_rounded,
                          label: 'Notifications',
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.language_rounded,
                          label: 'Langue / Language',
                          trailing: 'Français',
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.security_rounded,
                          label: 'Sécurité & Confidentialité',
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.help_rounded,
                          label: 'Aide & Support',
                          onTap: () {},
                        ),
                      ],

                      const SizedBox(height: 24),

                      XohoButton(
                        label: 'Se déconnecter',
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/onboarding');
                        },
                        variant: XohoButtonVariant.danger,
                        icon: const Icon(Icons.logout_rounded),
                      ),

                      const SizedBox(height: 16),
                      Text('Xoho v1.0.0 · Made in Bénin 🇧🇯',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center),
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

class _KycBadge extends StatelessWidget {
  const _KycBadge({required this.status});
  final KycStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      KycStatus.verified => ('Identité vérifiée', AppColors.success,
          Icons.verified_rounded),
      KycStatus.pending => ('Vérification en cours', AppColors.warning,
          Icons.hourglass_empty_rounded),
      KycStatus.rejected => ('Vérification rejetée', AppColors.error,
          Icons.cancel_rounded),
      KycStatus.none => ('Non vérifié', AppColors.textTertiary,
          Icons.info_outline_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.labelSM.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyLG),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: (badgeColor ?? AppColors.warning).withOpacity(0.15),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.caption.copyWith(
                      color: badgeColor ?? AppColors.warning),
                ),
              ),
            if (trailing != null)
              Text(trailing!, style: AppTextStyles.bodyMD),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

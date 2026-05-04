import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/xoho_button.dart';
import '../../../../models/driver_model.dart';
import '../../../../providers/wallet_provider.dart';

class DriverBottomSheet extends ConsumerStatefulWidget {
  const DriverBottomSheet({super.key, required this.driver});
  final DriverModel driver;

  @override
  ConsumerState<DriverBottomSheet> createState() => _DriverBottomSheetState();
}

class _DriverBottomSheetState extends ConsumerState<DriverBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  bool _isUnlocked = false;
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    HapticFeedback.mediumImpact();
    setState(() => _isUnlocking = true);
    final success = await ref.read(walletProvider.notifier).deduct(
          100,
          'Déblocage contact – ${widget.driver.fullName}',
        );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solde insuffisant. Rechargez votre portefeuille.')),
      );
    }
    setState(() {
      _isUnlocking = false;
      _isUnlocked = success;
    });
    if (success) HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.driver;

    return SlideTransition(
      position: _slide,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
              left: BorderSide(color: AppColors.border, width: 1),
              right: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Driver header
                    Row(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: Center(
                                child: Text(
                                  d.fullName.split(' ').map((n) => n[0]).take(2).join(),
                                  style: AppTextStyles.headingLG.copyWith(
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            if (d.mode == DriverMode.available)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success,
                                    border: Border.all(
                                        color: AppColors.bgCard, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(d.fullName,
                                      style: AppTextStyles.headingMD),
                                  const SizedBox(width: 6),
                                  if (d.isVerified)
                                    const Icon(Icons.verified_rounded,
                                        color: AppColors.verified, size: 18),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: AppColors.starGold, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    d.rating.toStringAsFixed(1),
                                    style: AppTextStyles.labelLG,
                                  ),
                                  Text(
                                    ' · ${d.totalDeliveries} livraisons',
                                    style: AppTextStyles.bodySM,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.bgElevated,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${d.vehicleLabel} · ${d.mode == DriverMode.available ? 'Disponible' : 'Occupé'}',
                                  style: AppTextStyles.labelSM.copyWith(
                                    color: d.mode == DriverMode.available
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        _StatItem(
                          icon: Icons.local_shipping_rounded,
                          value: '${d.totalDeliveries}',
                          label: 'Livraisons',
                        ),
                        _StatItem(
                          icon: Icons.timer_rounded,
                          value: '< 15 min',
                          label: 'Réponse',
                        ),
                        _StatItem(
                          icon: Icons.thumb_up_rounded,
                          value: '98%',
                          label: 'Satisfaction',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Contact unlock section
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 400),
                      crossFadeState: _isUnlocked
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: GlassOrangeCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.15),
                              ),
                              child: const Icon(Icons.lock_rounded,
                                  color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Contact masqué',
                                      style: AppTextStyles.headingSM),
                                  Text(
                                    'Débloquez pour seulement 100 F CFA',
                                    style: AppTextStyles.bodySM,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      secondChild: GlassCard(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.success.withOpacity(0.08),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success.withOpacity(0.15),
                              ),
                              child: const Icon(Icons.phone_rounded,
                                  color: AppColors.success, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Contact débloqué',
                                    style: AppTextStyles.headingSM.copyWith(
                                        color: AppColors.success)),
                                Text(d.phone,
                                    style: AppTextStyles.headingMD),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (!_isUnlocked)
                      XohoButton(
                        label: 'Débloquer le contact – 100 F',
                        onPressed: _unlock,
                        isLoading: _isUnlocking,
                        icon: const Icon(Icons.lock_open_rounded),
                      )
                    else
                      XohoButton(
                        label: 'Appeler le livreur',
                        onPressed: () {},
                        icon: const Icon(Icons.call_rounded),
                      ),

                    const SizedBox(height: 12),
                    XohoButton(
                      label: 'Voir le profil complet',
                      onPressed: () {},
                      variant: XohoButtonVariant.ghost,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.headingSM),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

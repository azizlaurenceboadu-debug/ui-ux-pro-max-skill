import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/xoho_button.dart';
import '../../../../providers/driver_provider.dart';
import '../../../../providers/shipment_provider.dart';

class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverState = ref.watch(driverProvider);
    final shipments = ref.watch(shipmentProvider).shipments
        .where((s) => s.status == ShipmentStatus.pending)
        .toList();

    return Scaffold(
      body: XohoBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mode Livreur', style: AppTextStyles.headingMD),
                          Text('Trouvez des colis à livrer',
                              style: AppTextStyles.bodySM),
                        ],
                      ),
                    ),
                    // Online toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref.read(driverProvider.notifier).toggleOnlineMode(
                              !driverState.isOnline,
                            );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: driverState.isOnline
                              ? AppColors.successBg
                              : AppColors.bgCard,
                          border: Border.all(
                            color: driverState.isOnline
                                ? AppColors.success
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: driverState.isOnline
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              driverState.isOnline ? 'En ligne' : 'Hors ligne',
                              style: AppTextStyles.labelMD.copyWith(
                                color: driverState.isOnline
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _StatCard(
                      label: 'Aujourd\'hui',
                      value: '3 200 F',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Livraisons',
                      value: '234',
                      icon: Icons.local_shipping_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Note',
                      value: '4.8 ★',
                      icon: Icons.star_rounded,
                      color: AppColors.starGold,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // CTA Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: XohoButton(
                        label: 'Enregistrer un trajet',
                        onPressed: () => context.push('/register-trip'),
                        icon: const Icon(Icons.route_rounded),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: XohoButton(
                        label: 'Scanner QR',
                        onPressed: () {},
                        variant: XohoButtonVariant.secondary,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Available shipments
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('Colis disponibles',
                        style: AppTextStyles.headingSM),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${shipments.length}',
                          style: AppTextStyles.labelSM
                              .copyWith(color: Colors.white)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: shipments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 56,
                                color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text('Aucun colis disponible',
                                style: AppTextStyles.bodyMD),
                            const SizedBox(height: 4),
                            Text('Revenez plus tard ou activez le mode en ligne.',
                                style: AppTextStyles.bodySM,
                                textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: shipments.length,
                        itemBuilder: (_, i) {
                          final s = shipments[i];
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(shipmentProvider.notifier)
                                  .updateStatus(s.id, ShipmentStatus.accepted);
                            },
                            child: GlassCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary
                                              .withOpacity(0.12),
                                        ),
                                        child: const Icon(
                                          Icons.inventory_2_rounded,
                                          color: AppColors.primary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(s.description,
                                                style: AppTextStyles.headingSM,
                                                overflow: TextOverflow.ellipsis),
                                            Text(
                                              '${s.pickupAddress} → ${s.deliveryAddress}',
                                              style: AppTextStyles.bodySM,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${s.proposedPriceFcfa} F',
                                            style: AppTextStyles.priceSM,
                                          ),
                                          if (s.distanceKm != null)
                                            Text(
                                              '${s.distanceKm!.toStringAsFixed(1)} km',
                                              style: AppTextStyles.bodySM,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (s.insurance != InsuranceType.none)
                                        _Tag(
                                          label: s.insurance ==
                                                  InsuranceType.basic
                                              ? 'Assuré'
                                              : 'Assuré Premium',
                                          color: AppColors.success,
                                        ),
                                      if (s.type == ShipmentType.interurban)
                                        _Tag(
                                          label: 'Interurbain',
                                          color: AppColors.info,
                                        ),
                                      const Spacer(),
                                      const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: AppColors.textTertiary),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: AppTextStyles.headingSM.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}

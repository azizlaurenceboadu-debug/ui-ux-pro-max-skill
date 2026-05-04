import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/xoho_button.dart';
import '../../../../models/shipment_model.dart';
import '../../../../providers/shipment_provider.dart';
import '../../../home/presentation/widgets/map_widget.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.shipmentId});
  final String shipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shipmentProvider);
    final shipment = state.shipments.firstWhere(
      (s) => s.id == shipmentId,
      orElse: () => state.shipments.first,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Map
          XohoMapWidget(
            pickupLatLng: shipment.pickupLatLng,
            deliveryLatLng: shipment.deliveryLatLng,
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.bgDeep.withOpacity(0.95),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textPrimary),
                      ),
                      Text('Suivi du colis',
                          style: AppTextStyles.headingMD),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                    top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status header
                      Row(
                        children: [
                          _StatusBadge(status: shipment.status),
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                context.push('/qr/${shipment.id}'),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              borderRadius: BorderRadius.circular(10),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_rounded,
                                      size: 18,
                                      color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text('QR Code',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Route summary
                      _RouteRow(
                        from: shipment.pickupAddress,
                        to: shipment.deliveryAddress,
                        distance: shipment.distanceKm,
                        minutes: shipment.estimatedMinutes,
                      ),

                      const SizedBox(height: 20),

                      // Timeline
                      _StatusTimeline(status: shipment.status),

                      const SizedBox(height: 24),

                      // Price + insurance row
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Prix', style: AppTextStyles.bodySM),
                              Text(
                                '${shipment.proposedPriceFcfa} F CFA',
                                style: AppTextStyles.price,
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (shipment.insurance != InsuranceType.none)
                            GlassCard(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              borderRadius: BorderRadius.circular(10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_user_rounded,
                                      size: 16,
                                      color: AppColors.success),
                                  const SizedBox(width: 6),
                                  Text(
                                    shipment.insurance ==
                                            InsuranceType.basic
                                        ? 'Assuré Basic'
                                        : 'Assuré Premium',
                                    style: AppTextStyles.labelSM.copyWith(
                                        color: AppColors.success),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      if (shipment.status == ShipmentStatus.inTransit) ...[
                        const SizedBox(height: 16),
                        XohoButton(
                          label: 'Confirmer la livraison',
                          onPressed: () => _showRatingDialog(context, ref, shipment),
                          icon: const Icon(Icons.check_circle_rounded),
                        ),
                      ],

                      if (shipment.status == ShipmentStatus.pending) ...[
                        const SizedBox(height: 16),
                        XohoButton(
                          label: 'Annuler l\'annonce',
                          onPressed: () {},
                          variant: XohoButtonVariant.danger,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(
      BuildContext context, WidgetRef ref, ShipmentModel shipment) {
    double rating = 5;
    final reviewCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Évaluer la livraison', style: AppTextStyles.headingLG),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setModalState(() => rating = i + 1.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 40,
                        color: AppColors.starGold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: reviewCtrl,
                decoration: const InputDecoration(
                  hintText: 'Laissez un commentaire...',
                ),
              ),
              const SizedBox(height: 20),
              XohoButton(
                label: 'Valider la livraison',
                onPressed: () {
                  ref.read(shipmentProvider.notifier).confirmDelivery(
                        shipment.id,
                        rating,
                        reviewCtrl.text,
                      );
                  Navigator.of(ctx).pop();
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ShipmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = switch (status) {
      ShipmentStatus.pending => (
          AppColors.warning,
          AppColors.warningBg,
          'En attente de livreur'
        ),
      ShipmentStatus.accepted => (
          AppColors.info,
          AppColors.infoBg,
          'Livreur assigné'
        ),
      ShipmentStatus.pickedUp => (
          AppColors.primary,
          AppColors.glassOrange,
          'Pris en charge'
        ),
      ShipmentStatus.inTransit => (
          AppColors.primary,
          AppColors.glassOrange,
          'En route'
        ),
      ShipmentStatus.delivered => (
          AppColors.success,
          AppColors.successBg,
          'Livré ✓'
        ),
      ShipmentStatus.cancelled => (
          AppColors.error,
          AppColors.errorBg,
          'Annulé'
        ),
      ShipmentStatus.disputed => (
          AppColors.error,
          AppColors.errorBg,
          'Litige'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.labelMD.copyWith(color: color)),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.from,
    required this.to,
    this.distance,
    this.minutes,
  });
  final String from;
  final String to;
  final double? distance;
  final int? minutes;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.radio_button_checked_rounded,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(from,
                    style: AppTextStyles.bodyMD
                        .copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 7, top: 4, bottom: 4),
            child: SizedBox(
              height: 16,
              child: VerticalDivider(color: AppColors.border, width: 2),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.success, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(to,
                    style: AppTextStyles.bodyMD
                        .copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          if (distance != null || minutes != null) ...[
            const Divider(color: AppColors.divider, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (distance != null)
                  _InfoChip(
                      icon: Icons.straighten_rounded,
                      label: '${distance!.toStringAsFixed(1)} km'),
                if (minutes != null)
                  _InfoChip(
                      icon: Icons.schedule_rounded,
                      label: '~${minutes! < 60 ? '$minutes min' : '${minutes! ~/ 60}h${minutes! % 60 > 0 ? ' ${minutes! % 60}min' : ''}'}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelMD),
      ],
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});
  final ShipmentStatus status;

  static const _steps = [
    (ShipmentStatus.pending, Icons.search_rounded, 'Annonce publiée'),
    (ShipmentStatus.accepted, Icons.handshake_rounded, 'Livreur trouvé'),
    (ShipmentStatus.pickedUp, Icons.inventory_2_rounded, 'Colis pris en charge'),
    (ShipmentStatus.inTransit, Icons.local_shipping_rounded, 'En route'),
    (ShipmentStatus.delivered, Icons.check_circle_rounded, 'Livré'),
  ];

  int get _currentIndex {
    for (var i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == status) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;
    return Column(
      children: List.generate(_steps.length, (i) {
        final isDone = i < current;
        final isActive = i == current;
        final step = _steps[i];

        return Row(
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.success
                        : isActive
                            ? AppColors.primary
                            : AppColors.bgElevated,
                    border: Border.all(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : step.$2,
                    size: 16,
                    color: isDone || isActive
                        ? Colors.white
                        : AppColors.textTertiary,
                  ),
                ),
                if (i < _steps.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: isDone ? AppColors.success : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              step.$3,
              style: AppTextStyles.bodyMD.copyWith(
                color: isDone || isActive
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/xoho_button.dart';
import '../../../../providers/shipment_provider.dart';

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key, required this.shipmentId});
  final String shipmentId;

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  bool _showScanner = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shipmentProvider);
    final shipment = state.shipments.firstWhere(
      (s) => s.id == widget.shipmentId,
      orElse: () => state.shipments.first,
    );
    final qrData =
        'xoho://delivery/${shipment.id}/${shipment.qrCode ?? "NO_CODE"}';

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
                    Text('QR Code du colis', style: AppTextStyles.headingMD),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // QR Code display
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: child,
                        ),
                        child: GlassCard(
                          padding: const EdgeInsets.all(28),
                          borderRadius: BorderRadius.circular(28),
                          child: Column(
                            children: [
                              QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: 220,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF0A0A12),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF0A0A12),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.glassOrange,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: Text(
                                  shipment.id.toUpperCase(),
                                  style: AppTextStyles.headingSM
                                      .copyWith(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Instructions
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_rounded,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text('Comment utiliser le QR Code',
                                    style: AppTextStyles.headingSM),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...[
                              (Icons.camera_alt_rounded, '1. Prise en charge',
                                  'Le livreur scanne le QR code au moment de prendre votre colis.'),
                              (Icons.check_circle_rounded, '2. Livraison',
                                  'Le livreur scanne à nouveau lors de la remise au destinataire.'),
                              (Icons.payments_rounded, '3. Paiement',
                                  'Le paiement est libéré automatiquement après validation.'),
                            ]
                                .map((item) => Padding(
                                      padding:
                                          const EdgeInsets.only(top: 10),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(item.$1,
                                              size: 18,
                                              color: AppColors.primary),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(item.$2,
                                                    style: AppTextStyles
                                                        .headingSM),
                                                Text(item.$3,
                                                    style: AppTextStyles
                                                        .bodySM),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Package info
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Colis', style: AppTextStyles.bodySM),
                                Text(
                                  shipment.description,
                                  style: AppTextStyles.headingSM,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Statut', style: AppTextStyles.bodySM),
                                Text(
                                  shipment.statusLabel,
                                  style: AppTextStyles.labelLG.copyWith(
                                      color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      XohoButton(
                        label: 'Partager le QR Code',
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                        },
                        icon: const Icon(Icons.share_rounded),
                      ),
                      const SizedBox(height: 12),
                      XohoButton(
                        label: 'Scanner un QR Code',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Scanner: intégrez mobile_scanner pour la caméra')),
                          );
                        },
                        variant: XohoButtonVariant.secondary,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                      ),

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

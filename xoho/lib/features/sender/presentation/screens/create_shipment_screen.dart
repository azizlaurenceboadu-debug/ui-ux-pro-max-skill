import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/xoho_button.dart';
import '../../../../models/shipment_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/shipment_provider.dart';

class CreateShipmentScreen extends ConsumerStatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  ConsumerState<CreateShipmentScreen> createState() =>
      _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends ConsumerState<CreateShipmentScreen> {
  int _step = 0;
  final _pickupCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  int _price = 1000;
  ShipmentType _type = ShipmentType.urban;
  InsuranceType _insurance = InsuranceType.none;
  bool _isLoading = false;

  static const _steps = ['Adresses', 'Colis', 'Prix & Options'];

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _deliveryCtrl.dispose();
    _descCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  bool get _step0Valid =>
      _pickupCtrl.text.isNotEmpty && _deliveryCtrl.text.isNotEmpty;

  bool get _step1Valid =>
      _descCtrl.text.isNotEmpty;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final user = ref.read(authProvider).user!;

    final shipment = await ref.read(shipmentProvider.notifier).createShipment(
          senderId: user.id,
          pickupAddress: _pickupCtrl.text,
          deliveryAddress: _deliveryCtrl.text,
          pickupLatLng: const LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
          deliveryLatLng: const LatLng(6.3550, 2.4280),
          description: _descCtrl.text,
          proposedPriceFcfa: _price,
          type: _type,
          insurance: _insurance,
          weight: double.tryParse(_weightCtrl.text),
        );

    if (mounted) {
      context.pushReplacement('/tracking/${shipment.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: XohoBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary),
                    ),
                    Text('Envoyer un colis',
                        style: AppTextStyles.headingMD),
                  ],
                ),
              ),

              // Progress stepper
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: List.generate(_steps.length, (i) {
                    final isActive = i == _step;
                    final isDone = i < _step;
                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: isDone || isActive
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _steps[i],
                                  style: AppTextStyles.caption.copyWith(
                                    color: isActive
                                        ? AppColors.primary
                                        : isDone
                                            ? AppColors.textSecondary
                                            : AppColors.textTertiary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          if (i < _steps.length - 1) const SizedBox(width: 4),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              // Step content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: IndexedStack(
                      key: ValueKey(_step),
                      index: _step,
                      children: [
                        _StepAddresses(
                          pickupCtrl: _pickupCtrl,
                          deliveryCtrl: _deliveryCtrl,
                          type: _type,
                          onTypeChange: (t) => setState(() => _type = t),
                        ),
                        _StepPackage(
                          descCtrl: _descCtrl,
                          weightCtrl: _weightCtrl,
                        ),
                        _StepPricing(
                          price: _price,
                          insurance: _insurance,
                          onPriceChange: (v) => setState(() => _price = v),
                          onInsuranceChange: (i) =>
                              setState(() => _insurance = i),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: XohoButton(
                          label: 'Retour',
                          onPressed: () => setState(() => _step--),
                          variant: XohoButtonVariant.ghost,
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: XohoButton(
                        label: _step < 2 ? 'Suivant' : 'Publier l\'annonce',
                        isLoading: _isLoading,
                        onPressed: switch (_step) {
                          0 => _step0Valid
                              ? () => setState(() => _step = 1)
                              : null,
                          1 => _step1Valid
                              ? () => setState(() => _step = 2)
                              : null,
                          _ => _submit,
                        },
                        trailingIcon: _step < 2
                            ? const Icon(Icons.arrow_forward_rounded)
                            : null,
                      ),
                    ),
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

class _StepAddresses extends StatelessWidget {
  const _StepAddresses({
    required this.pickupCtrl,
    required this.deliveryCtrl,
    required this.type,
    required this.onTypeChange,
  });
  final TextEditingController pickupCtrl;
  final TextEditingController deliveryCtrl;
  final ShipmentType type;
  final void Function(ShipmentType) onTypeChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Type de trajet', style: AppTextStyles.labelLG),
        const SizedBox(height: 10),
        Row(
          children: [
            _TypeChip(
              label: 'Urbain',
              icon: Icons.location_city_rounded,
              selected: type == ShipmentType.urban,
              onTap: () => onTypeChange(ShipmentType.urban),
            ),
            const SizedBox(width: 10),
            _TypeChip(
              label: 'Interurbain',
              icon: Icons.route_rounded,
              selected: type == ShipmentType.interurban,
              onTap: () => onTypeChange(ShipmentType.interurban),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Adresses', style: AppTextStyles.labelLG),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Pickup
              Row(
                children: [
                  const _DotIndicator(color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: pickupCtrl,
                      style: AppTextStyles.bodyLG,
                      decoration: const InputDecoration(
                        hintText: 'Adresse de départ',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Divider(color: AppColors.divider, height: 24),
              ),
              // Delivery
              Row(
                children: [
                  const _DotIndicator(color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: deliveryCtrl,
                      style: AppTextStyles.bodyLG,
                      decoration: const InputDecoration(
                        hintText: 'Adresse de destination',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (type == ShipmentType.interurban) ...[
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(14),
            color: AppColors.info.withOpacity(0.06),
            child: Row(
              children: [
                const Icon(Icons.info_rounded,
                    color: AppColors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pour l\'interurbain, des livreurs en déplacement verront votre colis sur leur trajet.',
                    style: AppTextStyles.bodySM
                        .copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        Text('Villes populaires', style: AppTextStyles.labelLG),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.beninCities.take(6).map((city) {
            return GestureDetector(
              onTap: () {
                if (pickupCtrl.text.isEmpty) {
                  pickupCtrl.text = city;
                } else {
                  deliveryCtrl.text = city;
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.bgCard,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(city, style: AppTextStyles.labelMD),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _StepPackage extends StatelessWidget {
  const _StepPackage({required this.descCtrl, required this.weightCtrl});
  final TextEditingController descCtrl;
  final TextEditingController weightCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Description du colis', style: AppTextStyles.labelLG),
        const SizedBox(height: 10),
        TextField(
          controller: descCtrl,
          maxLines: 3,
          style: AppTextStyles.bodyLG,
          decoration: const InputDecoration(
            hintText: 'Ex: Colis de vêtements, documents, fragile...',
          ),
        ),
        const SizedBox(height: 20),
        Text('Poids estimé (kg)', style: AppTextStyles.labelLG),
        const SizedBox(height: 10),
        TextField(
          controller: weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
          style: AppTextStyles.bodyLG,
          decoration: const InputDecoration(
            hintText: 'Ex: 2.5',
            suffixText: 'kg',
          ),
        ),
        const SizedBox(height: 20),
        Text('Photo du colis (optionnel)', style: AppTextStyles.labelLG),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {},
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid),
              color: AppColors.bgCard,
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      size: 36, color: AppColors.textTertiary),
                  SizedBox(height: 8),
                  Text('Ajouter une photo',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _StepPricing extends StatelessWidget {
  const _StepPricing({
    required this.price,
    required this.insurance,
    required this.onPriceChange,
    required this.onInsuranceChange,
  });
  final int price;
  final InsuranceType insurance;
  final void Function(int) onPriceChange;
  final void Function(InsuranceType) onInsuranceChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Prix proposé', style: AppTextStyles.labelLG),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '$price F CFA',
            style: AppTextStyles.price.copyWith(fontSize: 36),
          ),
        ),
        const SizedBox(height: 16),
        Slider(
          value: price.toDouble(),
          min: 500,
          max: 20000,
          divisions: 390,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border,
          onChanged: (v) => onPriceChange(v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('500 F', style: AppTextStyles.caption),
            Text('20 000 F', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 32),
        Text('Assurance Xoho', style: AppTextStyles.labelLG),
        const SizedBox(height: 12),
        ...[
          (InsuranceType.none, 'Sans assurance', 'Gratuit',
              'Aucune garantie en cas de perte ou casse.', AppColors.textTertiary),
          (InsuranceType.basic, 'Assurance Basic', '+200 F',
              'Remboursement jusqu\'à 25 000 F CFA.', AppColors.success),
          (InsuranceType.premium, 'Assurance Premium', '+500 F',
              'Remboursement jusqu\'à 100 000 F CFA.', AppColors.primary),
        ].map((item) {
          final isSelected = insurance == item.$1;
          return GestureDetector(
            onTap: () => onInsuranceChange(item.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isSelected
                    ? item.$5.withOpacity(0.08)
                    : AppColors.bgCard,
                border: Border.all(
                  color: isSelected ? item.$5 : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? item.$5 : AppColors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2, style: AppTextStyles.headingSM),
                        Text(item.$4,
                            style: AppTextStyles.bodySM),
                      ],
                    ),
                  ),
                  Text(item.$3,
                      style: AppTextStyles.priceSM
                          .copyWith(color: item.$5)),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.bgCard,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                  size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.labelMD.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

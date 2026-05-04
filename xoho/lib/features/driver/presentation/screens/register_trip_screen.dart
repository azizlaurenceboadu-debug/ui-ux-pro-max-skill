import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/xoho_button.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/driver_provider.dart';

class RegisterTripScreen extends ConsumerStatefulWidget {
  const RegisterTripScreen({super.key});

  @override
  ConsumerState<RegisterTripScreen> createState() => _RegisterTripScreenState();
}

class _RegisterTripScreenState extends ConsumerState<RegisterTripScreen> {
  String? _origin;
  String? _destination;
  DateTime _departureTime = DateTime.now().add(const Duration(hours: 2));
  double _capacityKg = 20.0;
  int _maxPackages = 5;
  int _pricePerKg = 100;
  bool _isLoading = false;

  bool get _isValid =>
      _origin != null && _destination != null && _origin != _destination;

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() => _isLoading = true);

    final user = ref.read(authProvider).user!;
    await ref.read(driverProvider.notifier).registerTrip(
          driverId: user.id,
          originCity: _origin!,
          destinationCity: _destination!,
          departureTime: _departureTime,
          availableCapacityKg: _capacityKg,
          maxPackages: _maxPackages,
          pricePerKg: _pricePerKg,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trajet enregistré avec succès !')),
      );
      context.pop();
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departureTime),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _departureTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    Text('Enregistrer un trajet',
                        style: AppTextStyles.headingMD),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info banner
                      GlassCard(
                        padding: const EdgeInsets.all(14),
                        color: AppColors.info.withOpacity(0.06),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded,
                                color: AppColors.info, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Enregistrez votre voyage et des expéditeurs sur votre route vous contacteront directement.',
                                style: AppTextStyles.bodySM
                                    .copyWith(color: AppColors.info),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      Text('Ville de départ', style: AppTextStyles.labelLG),
                      const SizedBox(height: 10),
                      _CityDropdown(
                        value: _origin,
                        hint: 'Choisir une ville',
                        exclude: _destination,
                        onChanged: (v) => setState(() => _origin = v),
                      ),

                      const SizedBox(height: 20),
                      Text('Ville d\'arrivée', style: AppTextStyles.labelLG),
                      const SizedBox(height: 10),
                      _CityDropdown(
                        value: _destination,
                        hint: 'Choisir une ville',
                        exclude: _origin,
                        onChanged: (v) => setState(() => _destination = v),
                      ),

                      const SizedBox(height: 20),
                      Text('Date et heure de départ',
                          style: AppTextStyles.labelLG),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickDateTime,
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  color: AppColors.primary, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                '${_departureTime.day}/${_departureTime.month}/${_departureTime.year} à ${_departureTime.hour.toString().padLeft(2, '0')}h${_departureTime.minute.toString().padLeft(2, '0')}',
                                style: AppTextStyles.bodyLG,
                              ),
                              const Spacer(),
                              const Icon(Icons.edit_calendar_rounded,
                                  color: AppColors.textSecondary, size: 18),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Capacité (kg)',
                                    style: AppTextStyles.labelLG),
                                const SizedBox(height: 8),
                                Text(
                                  '${_capacityKg.toStringAsFixed(0)} kg',
                                  style: AppTextStyles.price,
                                ),
                                Slider(
                                  value: _capacityKg,
                                  min: 1,
                                  max: 200,
                                  activeColor: AppColors.primary,
                                  inactiveColor: AppColors.border,
                                  onChanged: (v) =>
                                      setState(() => _capacityKg = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Max colis',
                                    style: AppTextStyles.labelLG),
                                const SizedBox(height: 8),
                                Text(
                                  '$_maxPackages colis',
                                  style: AppTextStyles.price,
                                ),
                                Slider(
                                  value: _maxPackages.toDouble(),
                                  min: 1,
                                  max: 20,
                                  divisions: 19,
                                  activeColor: AppColors.primary,
                                  inactiveColor: AppColors.border,
                                  onChanged: (v) =>
                                      setState(() => _maxPackages = v.round()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Text('Prix par kg', style: AppTextStyles.labelLG),
                      const SizedBox(height: 8),
                      Text('$_pricePerKg F CFA / kg',
                          style: AppTextStyles.price),
                      Slider(
                        value: _pricePerKg.toDouble(),
                        min: 50,
                        max: 500,
                        divisions: 45,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.border,
                        onChanged: (v) =>
                            setState(() => _pricePerKg = v.round()),
                      ),

                      const SizedBox(height: 32),

                      // Summary
                      if (_isValid)
                        GlassOrangeCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.route_rounded,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Résumé du trajet',
                                      style: AppTextStyles.headingSM),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$_origin → $_destination',
                                style: AppTextStyles.headingMD
                                    .copyWith(color: AppColors.primary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Capacité: ${_capacityKg.toStringAsFixed(0)} kg · Max $_maxPackages colis · ${_pricePerKg} F/kg',
                                style: AppTextStyles.bodySM,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: XohoButton(
                  label: 'Publier mon trajet',
                  onPressed: _isValid ? _submit : null,
                  isLoading: _isLoading,
                  icon: const Icon(Icons.rocket_launch_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({
    required this.value,
    required this.hint,
    required this.onChanged,
    this.exclude,
  });
  final String? value;
  final String hint;
  final void Function(String?) onChanged;
  final String? exclude;

  @override
  Widget build(BuildContext context) {
    final cities = AppConstants.beninCities
        .where((c) => c != exclude)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: AppTextStyles.bodyMD),
          isExpanded: true,
          dropdownColor: AppColors.bgElevated,
          style: AppTextStyles.bodyLG,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          items: cities
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

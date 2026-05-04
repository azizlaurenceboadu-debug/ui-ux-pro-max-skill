import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/xoho_button.dart';
import '../../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _showOtp = false;
  String _otp = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.length < 8) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() { _isLoading = false; _showOtp = true; });
  }

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) return;
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).loginWithPhone(
          '+229${_phoneCtrl.text}',
          _otp,
        );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: AppTextStyles.headingLG,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Scaffold(
      body: AnimatedGlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Center(
                        child: Text('X',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('xoho',
                        style: AppTextStyles.headingXL
                            .copyWith(color: AppColors.primary)),
                  ],
                ),

                const SizedBox(height: 48),

                Text(
                  _showOtp ? 'Vérification' : 'Connexion',
                  style: AppTextStyles.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _showOtp
                      ? 'Entrez le code à 6 chiffres envoyé au\n+229 ${_phoneCtrl.text}'
                      : 'Entrez votre numéro de téléphone\npour recevoir un code de vérification.',
                  style: AppTextStyles.bodyLG
                      .copyWith(color: AppColors.textSecondary),
                ),

                const SizedBox(height: 40),

                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showOtp
                        ? Column(
                            key: const ValueKey('otp'),
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Pinput(
                                length: 6,
                                defaultPinTheme: defaultPinTheme,
                                focusedPinTheme: defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme.decoration!
                                      .copyWith(
                                    border: Border.all(
                                        color: AppColors.primary, width: 2),
                                  ),
                                ),
                                onCompleted: (val) {
                                  setState(() => _otp = val);
                                },
                              ),
                              const SizedBox(height: 24),
                              XohoButton(
                                label: 'Confirmer',
                                onPressed: _otp.length == 6 ? _verifyOtp : null,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _showOtp = false),
                                child: Text(
                                  'Changer de numéro',
                                  style: AppTextStyles.labelLG.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            key: const ValueKey('phone'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Country code row
                              Row(
                                children: [
                                  Container(
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgElevated,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('🇧🇯',
                                            style: TextStyle(fontSize: 20)),
                                        const SizedBox(width: 6),
                                        Text('+229',
                                            style: AppTextStyles.bodyLG),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(8),
                                      ],
                                      style: AppTextStyles.bodyLG,
                                      decoration: const InputDecoration(
                                        hintText: '01 23 45 67',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              XohoButton(
                                label: 'Recevoir le code',
                                onPressed: _phoneCtrl.text.length >= 8
                                    ? _sendOtp
                                    : null,
                                isLoading: _isLoading,
                                trailingIcon:
                                    const Icon(Icons.arrow_forward_rounded),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                Center(
                  child: Text(
                    'En vous connectant, vous acceptez nos\nConditions d\'utilisation et Politique de confidentialité.',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

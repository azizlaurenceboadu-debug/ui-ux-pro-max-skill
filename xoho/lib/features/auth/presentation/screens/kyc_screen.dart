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

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  int _step = 0;
  bool _idUploaded = false;
  bool _selfieUploaded = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    ref.read(authProvider.notifier).updateUser(
          ref.read(authProvider).user!.copyWith(kycStatus: KycStatus.pending),
        );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: XohoBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Text('Vérification d\'identité',
                        style: AppTextStyles.headingMD),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress
                LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  backgroundColor: AppColors.bgCard,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 4,
                ),
                const SizedBox(height: 32),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: IndexedStack(
                      key: ValueKey(_step),
                      index: _step,
                      children: [
                        _StepInfo(onNext: () => setState(() => _step = 1)),
                        _StepId(
                          isUploaded: _idUploaded,
                          onUpload: () =>
                              setState(() => _idUploaded = true),
                          onNext: () => setState(() => _step = 2),
                        ),
                        _StepSelfie(
                          isUploaded: _selfieUploaded,
                          onUpload: () =>
                              setState(() => _selfieUploaded = true),
                          onSubmit: _submit,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
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

class _StepInfo extends StatelessWidget {
  const _StepInfo({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pourquoi vérifier\nvotre identité ?',
            style: AppTextStyles.displayMedium),
        const SizedBox(height: 24),
        ...[
          (Icons.security_rounded, 'Sécurité des colis',
              'Protège les expéditeurs et les livreurs contre les fraudes.'),
          (Icons.verified_user_rounded, 'Badge Vérifié',
              'Les utilisateurs vérifiés inspirent confiance et reçoivent plus de missions.'),
          (Icons.lock_rounded, 'Conforme à la loi',
              'Exigé par la réglementation béninoise (CIP).'),
        ]
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.12),
                          ),
                          child: Icon(item.$1,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$2, style: AppTextStyles.headingSM),
                              const SizedBox(height: 2),
                              Text(item.$3,
                                  style: AppTextStyles.bodySM),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
        const Spacer(),
        XohoButton(label: 'Commencer la vérification', onPressed: onNext),
        const SizedBox(height: 16),
        XohoButton(
          label: 'Plus tard',
          onPressed: () => Navigator.of(context).pop(),
          variant: XohoButtonVariant.ghost,
        ),
      ],
    );
  }
}

class _StepId extends StatelessWidget {
  const _StepId({
    required this.isUploaded,
    required this.onUpload,
    required this.onNext,
  });
  final bool isUploaded;
  final VoidCallback onUpload;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Étape 1/2\nPhoto de votre CIP',
            style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text('Prenez votre Carte d\'Identité en photo. L\'image doit être nette et lisible.',
            style: AppTextStyles.bodyMD),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onUpload,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUploaded ? AppColors.success : AppColors.border,
                width: isUploaded ? 2 : 1,
              ),
              color: isUploaded
                  ? AppColors.success.withOpacity(0.08)
                  : AppColors.bgCard,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUploaded
                        ? Icons.check_circle_rounded
                        : Icons.add_photo_alternate_rounded,
                    size: 48,
                    color: isUploaded ? AppColors.success : AppColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUploaded ? 'Photo ajoutée ✓' : 'Appuyez pour prendre une photo',
                    style: AppTextStyles.labelLG.copyWith(
                      color: isUploaded ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        XohoButton(
          label: 'Suivant',
          onPressed: isUploaded ? onNext : null,
          trailingIcon: const Icon(Icons.arrow_forward_rounded),
        ),
      ],
    );
  }
}

class _StepSelfie extends StatelessWidget {
  const _StepSelfie({
    required this.isUploaded,
    required this.onUpload,
    required this.onSubmit,
    required this.isLoading,
  });
  final bool isUploaded;
  final VoidCallback onUpload;
  final VoidCallback onSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Étape 2/2\nVotre selfie', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text('Prenez un selfie pour confirmer que vous êtes bien le propriétaire de la carte d\'identité.',
            style: AppTextStyles.bodyMD),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onUpload,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isUploaded ? AppColors.success : AppColors.border,
                width: isUploaded ? 2 : 1,
              ),
              color: isUploaded
                  ? AppColors.success.withOpacity(0.08)
                  : AppColors.bgCard,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUploaded ? Icons.check_circle_rounded : Icons.face_rounded,
                    size: 48,
                    color: isUploaded ? AppColors.success : AppColors.textTertiary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUploaded ? 'Selfie ajouté ✓' : 'Prendre un selfie',
                    style: AppTextStyles.labelLG.copyWith(
                      color: isUploaded ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        XohoButton(
          label: 'Soumettre pour vérification',
          onPressed: isUploaded ? onSubmit : null,
          isLoading: isLoading,
        ),
      ],
    );
  }
}

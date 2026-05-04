import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/xoho_button.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.inventory_2_rounded,
      title: 'Envoyez vos colis\nen toute confiance',
      subtitle:
          'Publiez votre annonce et trouvez un livreur vérifié près de chez vous en quelques secondes.',
      color: AppColors.primary,
    ),
    _OnboardingPage(
      icon: Icons.route_rounded,
      title: 'Voyagez et\ngagnez de l\'argent',
      subtitle:
          'Vous partez en voyage ? Enregistrez votre trajet et transportez des colis sur votre route.',
      color: AppColors.success,
    ),
    _OnboardingPage(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Livraison sécurisée\npar QR Code',
      subtitle:
          'Un QR code unique par colis. Scannez à la prise en charge et à la livraison. Paiement sécurisé par séquestre.',
      color: AppColors.info,
    ),
    _OnboardingPage(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Payez avec\nMoMo ou Moov',
      subtitle:
          'Intégration native avec MTN MoMo et Moov Money. Transactions ultra-rapides, frais de mise en relation à seulement 100 F.',
      color: AppColors.warning,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: XohoBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Skip
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Passer',
                    style: AppTextStyles.labelLG
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _PageContent(page: _pages[i]),
                ),
              ),

              // Dots + buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: i == _currentPage
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    XohoButton(
                      label: _currentPage == _pages.length - 1
                          ? 'Commencer maintenant'
                          : 'Suivant',
                      onPressed: _next,
                      trailingIcon: _currentPage < _pages.length - 1
                          ? const Icon(Icons.arrow_forward_rounded)
                          : null,
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

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon blob
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.color.withOpacity(0.12),
              border: Border.all(
                color: page.color.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(page.icon, size: 52, color: page.color),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: AppTextStyles.bodyLG.copyWith(
              color: AppColors.textSecondary,
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

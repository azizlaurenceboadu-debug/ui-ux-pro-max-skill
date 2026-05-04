import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../models/driver_model.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/shipment_provider.dart';
import '../widgets/driver_bottom_sheet.dart';
import '../widgets/map_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  DriverModel? _selectedDriver;

  void _onDriverTap(DriverModel driver) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDriver = driver);
    _showDriverSheet(driver);
  }

  void _showDriverSheet(DriverModel driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => DriverBottomSheet(driver: driver),
    ).whenComplete(() => setState(() => _selectedDriver = null));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final activeShipment = ref.watch(activeShipmentProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Map fills entire screen ──────────────────────────────────
          XohoMapWidget(onDriverTap: _onDriverTap),

          // ── Top gradient + header ────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.bgDeep.withOpacity(0.95),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      // Header bar
                      Row(
                        children: [
                          // Logo
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                ),
                                child: const Center(
                                  child: Text('X',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      )),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('xoho',
                                  style: AppTextStyles.headingMD
                                      .copyWith(color: AppColors.primary)),
                            ],
                          ),
                          const Spacer(),
                          // Wallet chip
                          GestureDetector(
                            onTap: () => context.push('/wallet'),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text('12 500 F',
                                      style: AppTextStyles.labelLG.copyWith(
                                          color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Avatar
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                    width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  user?.initials ?? 'X',
                                  style: AppTextStyles.labelMD.copyWith(
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Search bar
                      GestureDetector(
                        onTap: () => context.push('/create-shipment'),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded,
                                  color: AppColors.textSecondary, size: 22),
                              const SizedBox(width: 12),
                              Text('Où livrer votre colis ?',
                                  style: AppTextStyles.bodyLG.copyWith(
                                      color: AppColors.textSecondary)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Envoyer',
                                    style: AppTextStyles.buttonSM),
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
          ),

          // ── Active shipment banner ───────────────────────────────────
          if (activeShipment != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: GestureDetector(
                onTap: () => context.push('/tracking/${activeShipment.id}'),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.primary.withOpacity(0.12),
                  borderOpacity: 0.25,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.local_shipping_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activeShipment.statusLabel,
                                style: AppTextStyles.labelLG
                                    .copyWith(color: AppColors.primary)),
                            Text(
                              '→ ${activeShipment.deliveryAddress}',
                              style: AppTextStyles.bodySM,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),

          // ── Role switcher pill ───────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 110,
            child: _RoleSwitcher(
              role: ref.watch(authProvider).user?.role ?? UserRole.sender,
              onSwitch: () {
                final user = ref.read(authProvider).user;
                if (user == null) return;
                final newRole = user.role == UserRole.sender
                    ? UserRole.driver
                    : UserRole.sender;
                ref.read(authProvider.notifier).setRole(newRole);
                if (newRole == UserRole.driver) {
                  context.push('/driver-home');
                }
              },
            ),
          ),

          // ── Bottom nav ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _XohoBottomNav(
              currentIndex: _navIndex,
              onTap: (i) {
                setState(() => _navIndex = i);
                switch (i) {
                  case 1:
                    context.push('/create-shipment');
                  case 2:
                    context.push('/driver-home');
                  case 3:
                    context.push('/wallet');
                  case 4:
                    context.push('/profile');
                  default:
                    break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  const _RoleSwitcher({required this.role, required this.onSwitch});
  final UserRole role;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final isDriver = role == UserRole.driver;
    return GestureDetector(
      onTap: onSwitch,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDriver
                  ? Icons.delivery_dining_rounded
                  : Icons.inventory_2_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isDriver ? 'Mode Livreur' : 'Mode Expéditeur',
              style: AppTextStyles.labelMD
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.swap_horiz_rounded,
                color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _XohoBottomNav extends StatelessWidget {
  const _XohoBottomNav({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: Icons.map_rounded, label: 'Carte', index: 0, current: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.add_circle_rounded, label: 'Envoyer', index: 1, current: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.delivery_dining_rounded, label: 'Livrer', index: 2, current: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Portefeuille', index: 3, current: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.person_rounded, label: 'Profil', index: 4, current: currentIndex, onTap: onTap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? AppColors.primary : AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

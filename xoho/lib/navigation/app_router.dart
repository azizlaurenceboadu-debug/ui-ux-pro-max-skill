import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/kyc_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/sender/presentation/screens/create_shipment_screen.dart';
import '../features/sender/presentation/screens/tracking_screen.dart';
import '../features/driver/presentation/screens/driver_home_screen.dart';
import '../features/driver/presentation/screens/register_trip_screen.dart';
import '../features/wallet/presentation/screens/wallet_screen.dart';
import '../features/qr/presentation/screens/qr_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = auth.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isLogin = state.matchedLocation == '/login';

      if (isSplash) return null;
      if (!isLoggedIn && !isOnboarding && !isLogin) return '/onboarding';
      if (isLoggedIn && (isOnboarding || isLogin)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/kyc',
        builder: (_, __) => const KycScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create-shipment',
        builder: (_, __) => const CreateShipmentScreen(),
      ),
      GoRoute(
        path: '/tracking/:id',
        builder: (_, state) =>
            TrackingScreen(shipmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/driver-home',
        builder: (_, __) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/register-trip',
        builder: (_, __) => const RegisterTripScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (_, __) => const WalletScreen(),
      ),
      GoRoute(
        path: '/qr/:shipmentId',
        builder: (_, state) =>
            QrScreen(shipmentId: state.pathParameters['shipmentId']!),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
    ],
  );
});

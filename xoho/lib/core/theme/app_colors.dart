import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFF47920);
  static const Color primaryDark = Color(0xFFD4640F);
  static const Color primaryLight = Color(0xFFFF9446);
  static const Color primaryGlow = Color(0x33F47920);

  // Backgrounds (Dark Mode)
  static const Color bgDeep = Color(0xFF0A0A12);
  static const Color bgBase = Color(0xFF0E0E1A);
  static const Color bgSurface = Color(0xFF141422);
  static const Color bgCard = Color(0xFF1A1A2C);
  static const Color bgElevated = Color(0xFF1F1F35);

  // Glass effects
  static const Color glassWhite = Color(0x0FFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassStrong = Color(0x1AFFFFFF);
  static const Color glassOrange = Color(0x1AF47920);

  // Text
  static const Color textPrimary = Color(0xFFF2F2F7);
  static const Color textSecondary = Color(0xFF8E8EA0);
  static const Color textTertiary = Color(0xFF5A5A72);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0x1A22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color warningBg = Color(0x1AEAB308);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1AEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0x1A3B82F6);

  // Dividers
  static const Color divider = Color(0xFF1E1E30);
  static const Color border = Color(0xFF252540);

  // Map
  static const Color mapMarkerDriver = Color(0xFFF47920);
  static const Color mapMarkerSender = Color(0xFF3B82F6);

  // Wallet / Payment
  static const Color mtnYellow = Color(0xFFFFCC00);
  static const Color moovBlue = Color(0xFF003DA5);

  // Rating
  static const Color starGold = Color(0xFFFBBF24);

  // Verified badge
  static const Color verified = Color(0xFF22C55E);
  static const Color unverified = Color(0xFFEF4444);

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF47920), Color(0xFFFF6B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1F1F35), Color(0xFF141422)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0A12), Color(0xFF0E0E1A), Color(0xFF141422)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient glowGradient = RadialGradient(
    colors: [Color(0x33F47920), Color(0x00F47920)],
    radius: 0.8,
  );
}

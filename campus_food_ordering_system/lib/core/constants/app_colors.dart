import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryVariant = Color(0xFFE55A2B);
  static const Color primaryLight = Color(0xFFFF8A5C);

  // Secondary
  static const Color secondary = Color(0xFF2EC4B6);
  static const Color secondaryLight = Color(0xFF3DD5C7);

  // Surfaces - Light
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F7);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Surfaces - Dark
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color backgroundDark = Color(0xFF121218);
  static const Color cardBackgroundDark = Color(0xFF252538);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFE8E8F0);
  static const Color textSecondaryDark = Color(0xFF9898A8);
  static const Color textHint = Color(0xFF9E9EB0);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Misc
  static const Color divider = Color(0xFFE8E8F0);
  static const Color dividerDark = Color(0xFF2A2A3A);
  static const Color shimmer = Color(0xFFE0E0E0);
  static const Color veg = Color(0xFF4CAF50);
  static const Color nonVeg = Color(0xFFE53935);
  static const Color star = Color(0xFFFFB800);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFFF8A5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

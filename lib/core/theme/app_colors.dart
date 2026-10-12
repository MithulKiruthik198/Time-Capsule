import 'package:flutter/material.dart';

/// Design tokens for the Time Capsule Midnight + Warm Gold aesthetic:
/// "A personal time machine for your life."
class AppColors {
  AppColors._();

  // Primary backgrounds & surfaces
  static const Color background = Color(0xFF08090D); // Midnight Black
  static const Color surface = Color(0xFF11131A); // Deep Charcoal
  static const Color surfaceElevated = Color(0xFF181B24);
  static const Color surfaceBorder = Color(0x1AFFFFFF); // 10% white subtle border
  static const Color surfaceBorderLight = Color(0x33FFFFFF); // 20% white border

  // Warm Gold Accents (Active, Unlockable & Celebratory)
  static const Color accent = Color(0xFFD6A84F); // Time Gold (Primary Accent)
  static const Color brightAccent = Color(0xFFF4D58A); // Memory Gold (Bright Accent)
  static const Color accentGlow = Color(0x55D6A84F); // Soft gold glow
  static const Color accentSubtle = Color(0xFF262116); // Subtle warm charcoal
  static const Color readyGold = Color(0xFFFFD43D); // Radiant Sun Gold
  static const Color amberGold = Color(0xFFFF8A00); // Seam Fissure Amber
  static const Color champagne = Color(0xFFF4D58A); // Light Bloom Champagne

  // Sealed Vault Accents (Unified with Signature Time Gold Theme)
  static const Color stasisViolet = Color(0xFFD6A84F); // Time Gold
  static const Color stasisIndigo = Color(0xFF8C6D2B); // Deep Bronze Gold
  static const Color stasisBlue = Color(0xFFF4D58A); // Memory Bright Gold
  static const Color stasisAura = Color(0x33D6A84F); // Suspended Gold Aura
  static const Color stasisBorder = Color(0x33D6A84F); // 20% Gold Border

  // Elevation Depths
  static const List<BoxShadow> depthCard = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
  static const List<BoxShadow> depthFloating = [
    BoxShadow(
      color: Color(0x99000000),
      blurRadius: 36,
      offset: Offset(0, 14),
    ),
  ];

  // Status Colors
  static const Color locked = Color(0xFFD6A84F); // Sealed Time Gold
  static const Color ready = Color(0xFFFFD43D); // Success / Unlocked / Returned
  static const Color opened = Color(0xFFD6A84F); // Opened memories
  static const Color danger = Color(0xFFFF4D4F);

  // Typography
  static const Color textPrimary = Color(0xFFF5F3EE);
  static const Color textSecondary = Color(0xFF9295A0);
  static const Color textTertiary = Color(0xFF696D78);
  static const Color textAccent = Color(0xFFF4D58A);

  // Gradients
  static const RadialGradient heroPortalGlow = RadialGradient(
    colors: [
      Color(0x33D6A84F),
      Color(0x10D6A84F),
      Color(0x0008090D),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0xCC08090D),
      Color(0xF008090D),
    ],
  );
}

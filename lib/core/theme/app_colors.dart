import 'package:flutter/material.dart';

/// Centralized design tokens for colors in Vyapar Mitra.
/// Aligned with the Stitch "Empowered Enterprise" design system.
/// Designed for high outdoor readability, trust, and rural/semi-urban micro-enterprise context.
class AppColors {
  // Primary: Deep Indigo Trust (#0F2942)
  static const Color primary = Color(0xFF0F2942);
  static const Color primaryContainer = Color(0xFF0F2942);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryLight = Color(0xFF1E4E79);
  static const Color primaryDark = Color(0xFF071828);

  // Secondary: Auspicious Saffron / Marigold (#E65100 / #FC6018)
  static const Color secondary = Color(0xFFE65100);
  static const Color secondaryContainer = Color(0xFFFC6018);
  static const Color secondaryLight = Color(0xFFFF7543);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF531800);

  // Tertiary: Organic Growth Green (#166534)
  static const Color tertiary = Color(0xFF166534);
  static const Color tertiaryContainer = Color(0xFF002F13);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF549E67);

  // Canvas, Surface & Structural Cards
  static const Color background = Color(0xFFFAF6EE); // Warm Khadi Sand
  static const Color surface = Color(0xFFFFFFFF);    // Milk White structural card
  static const Color surfaceVariant = Color(0xFFF4EFE6);
  static const Color surfaceContainerLow = Color(0xFFF7F3EB);
  static const Color surfaceContainer = Color(0xFFF1EDE6);
  static const Color surfaceContainerHigh = Color(0xFFECE8E0);

  // Text / Typography
  static const Color textPrimary = Color(0xFF0F172A); // Ink Charcoal
  static const Color textSecondary = Color(0xFF43474D); // Muted Slate
  static const Color textMuted = Color(0xFF74777E);

  // Status, Feasibility & Risk Badges
  static const Color success = Color(0xFF166534);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorBg = Color(0xFFFFDAD6);
  static const Color info = Color(0xFF1E4E79);
  static const Color infoBg = Color(0xFFEEF4FA);

  // Borders & Outlines
  static const Color border = Color(0xFFEAE0CE);
  static const Color borderMuted = Color(0xFFE8E3D7);
}

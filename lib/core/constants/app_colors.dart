import 'package:flutter/material.dart';

class AppColors {
  // Primary: Dark Forest Green
  static const Color primary = Color(0xFF1B4332);
  
  // Secondary: Deep Burnt Orange
  static const Color secondary = Color(0xFFD35400);

  // Tertiary: Medium Jungle Green
  static const Color tertiary = Color(0xFF2D6A4F);

  // Neutral: Bone White
  static const Color background = Color(0xFFFBF9F2);

  // Text Colors
  static const Color textPrimary = Color(0xFF1B4332); // Dark Forest Green for text
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textLight = Colors.white;

  /// Verde reservado sólo para el elemento seleccionado de la barra de
  /// navegación. Espejo de `Color.navigationSelection` (iOS).
  static const Color navigationSelection = Color(0xFF40916C);

  /// Fondo de pantalla en modo oscuro (iOS usa `.systemBackground`).
  static const Color backgroundDark = Color(0xFF121212);
}

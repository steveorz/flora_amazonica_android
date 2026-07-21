import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Tema de la app. Usa **Roboto**, la tipografía oficial de Material Design,
/// para que FlorAmaz se vea consistente con las apps nativas de Android, y el
/// type scale de Material 3.
class AppTheme {
  /// Roboto aplicado sobre el type scale de Material 3 (display / headline /
  /// title / body / label). `google_fonts` descarga la fuente en tiempo de
  /// ejecución y la cachea.
  static TextTheme _texto(TextTheme base) => GoogleFonts.robotoTextTheme(base);

  /// Transición de página al estilo Android moderno (zoom + fade), la que M3
  /// usa por defecto en todas las plataformas.
  static const PageTransitionsTheme _transiciones = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData get lightTheme => _base(Brightness.light);
  static ThemeData get darkTheme => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final oscuro = brightness == Brightness.dark;

    // Genera la paleta asegurando que los tonos respeten la semilla verde.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(brightness: brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: oscuro ? AppColors.backgroundDark : AppColors.background,
      textTheme: _texto(base.textTheme),
      pageTransitionsTheme: _transiciones,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: oscuro ? Colors.white : AppColors.primary),
        titleTextStyle: GoogleFonts.roboto(
          color: oscuro ? Colors.white : AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: oscuro ? const Color(0xFF1E1E1E) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      navigationBarTheme: _navigationBarTheme(brightness),
    );
  }

  /// Verde amazónico sólo para la selección de la barra, como en iOS
  /// (`.tint(Color.navigationSelection)`).
  static NavigationBarThemeData _navigationBarTheme(Brightness brightness) {
    final oscuro = brightness == Brightness.dark;
    return NavigationBarThemeData(
      elevation: 0,
      backgroundColor: oscuro
          ? Color.lerp(AppColors.backgroundDark, Colors.black, 0.20) // ~20% más oscuro en modo oscuro
          : Color.lerp(AppColors.background, Colors.black, 0.03), // ~3% más oscuro en modo claro (hueso muy sutil)
      indicatorColor: AppColors.navigationSelection.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final seleccionado = states.contains(WidgetState.selected);
        return GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
          color: seleccionado
              ? AppColors.navigationSelection
              : (oscuro ? Colors.grey.shade400 : Colors.grey),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final seleccionado = states.contains(WidgetState.selected);
        return IconThemeData(
          color: seleccionado
              ? AppColors.navigationSelection
              : (oscuro ? Colors.grey.shade400 : Colors.grey),
        );
      }),
    );
  }
}

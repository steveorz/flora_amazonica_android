import 'dart:math' as math;

/// Espejo de `Dasometria` (iOS, Core/Utils/Dasometria.swift).
abstract final class Dasometria {
  /// Diámetro a la altura del pecho (cm), calculado a partir del CAP.
  static double calcularDap(double cap) => cap / math.pi;

  /// Devuelve el valor con 1–2 decimales según su magnitud
  /// (más decimales para números pequeños).
  static String formato(double value) {
    final decimales = value.abs() < 10 ? 2 : 1;
    return value.toStringAsFixed(decimales);
  }

  /// Helper: dap formateado a partir del cap.
  static String dapFormateado(double cap) => formato(calcularDap(cap));
}

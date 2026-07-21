import 'package:flutter/material.dart';

/// Círculo de vidrio con un icono dentro, sobre fondos oscuros.
/// Equivale a `.glassEffect(.regular.tint(.white.opacity(0.2)), in: Circle())`.
class IconoEnVidrio extends StatelessWidget {
  const IconoEnVidrio({super.key, required this.icono, this.tamano = 72});

  final IconData icono;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(tamano * 0.38),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Icon(icono, size: tamano, color: Colors.white),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/estado_registro.dart';

class EstadoBadge extends StatelessWidget {
  final EstadoRegistro estado;

  const EstadoBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = estado.color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

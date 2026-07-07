import 'package:flutter/material.dart';
import '../../core/constants/estado_registro.dart';

class EstadoBadge extends StatelessWidget {
  final EstadoRegistro estado;

  const EstadoBadge({super.key, required this.estado});

  Color _getColor() {
    switch (estado) {
      case EstadoRegistro.pendiente:
        return Colors.orange;
      case EstadoRegistro.validado:
        return Colors.blue;
      case EstadoRegistro.publicado:
        return Colors.green;
      case EstadoRegistro.observado:
        return Colors.amber;
      case EstadoRegistro.rechazado:
        return Colors.red;
    }
  }

  String _getLabel() {
    switch (estado) {
      case EstadoRegistro.pendiente:
        return "Pendiente";
      case EstadoRegistro.validado:
        return "Validado";
      case EstadoRegistro.publicado:
        return "Publicado";
      case EstadoRegistro.observado:
        return "Observado";
      case EstadoRegistro.rechazado:
        return "Rechazado";
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getLabel(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

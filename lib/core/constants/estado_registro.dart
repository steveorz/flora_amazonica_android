import 'package:flutter/material.dart';

enum EstadoRegistro {
  borrador('borrador'),
  enRevision('en_revision'),
  observado('observado'),
  validado('validado'),
  rechazado('rechazado');

  final String value;
  const EstadoRegistro(this.value);

  /// iOS cae a `.borrador` cuando el backend manda un estado desconocido o nulo.
  static EstadoRegistro fromRaw(String? raw) => EstadoRegistro.values.firstWhere(
        (e) => e.value == raw,
        orElse: () => EstadoRegistro.borrador,
      );

  String get label {
    switch (this) {
      case EstadoRegistro.borrador:
        return "Borrador";
      case EstadoRegistro.enRevision:
        return "En revisión";
      case EstadoRegistro.observado:
        return "Observado";
      case EstadoRegistro.validado:
        return "Validado";
      case EstadoRegistro.rechazado:
        return "Rechazado";
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case EstadoRegistro.borrador:
        return Colors.grey;
      case EstadoRegistro.enRevision:
        return Colors.indigo;
      case EstadoRegistro.observado:
        return Colors.orange;
      case EstadoRegistro.validado:
        return Colors.green;
      case EstadoRegistro.rechazado:
        return Colors.red;
    }
  }
}

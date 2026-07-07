import 'package:flutter/material.dart';

enum EstadoRegistro {
  borrador('borrador'),
  enRevision('en_revision'),
  observado('observado'),
  validado('validado'),
  rechazado('rechazado'),
  publicado('publicado');

  final String value;
  const EstadoRegistro(this.value);

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
      case EstadoRegistro.publicado:
        return "Publicado";
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case EstadoRegistro.borrador:
        return Colors.grey;
      case EstadoRegistro.enRevision:
        return Colors.blue;
      case EstadoRegistro.observado:
        return Colors.orange;
      case EstadoRegistro.validado:
        return Colors.blue;
      case EstadoRegistro.rechazado:
        return Colors.red;
      case EstadoRegistro.publicado:
        return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black; // BrandColor
    }
  }
}

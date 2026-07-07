import 'package:flutter/material.dart';

enum TipoNotificacion {
  validacion,
  observacion,
  rechazo,
  publicacion,
  enRevision,
  cuentaActivada,
  rolActualizado,
  sistema;

  String get label {
    switch (this) {
      case TipoNotificacion.validacion: return "Validación";
      case TipoNotificacion.observacion: return "Observación";
      case TipoNotificacion.rechazo: return "Rechazo";
      case TipoNotificacion.publicacion: return "Publicación";
      case TipoNotificacion.enRevision: return "En revisión";
      case TipoNotificacion.cuentaActivada: return "Cuenta activada";
      case TipoNotificacion.rolActualizado: return "Rol actualizado";
      case TipoNotificacion.sistema: return "Sistema";
    }
  }

  IconData get icon {
    switch (this) {
      case TipoNotificacion.validacion: return Icons.verified; // checkmark.seal.fill
      case TipoNotificacion.observacion: return Icons.feedback; // exclamationmark.bubble.fill
      case TipoNotificacion.rechazo: return Icons.cancel; // xmark.octagon.fill
      case TipoNotificacion.publicacion: return Icons.public; // globe.americas.fill
      case TipoNotificacion.enRevision: return Icons.search; // magnifyingglass.circle.fill
      case TipoNotificacion.cuentaActivada: return Icons.person_add_alt_1; // person.crop.circle.badge.checkmark
      case TipoNotificacion.rolActualizado: return Icons.manage_accounts; // person.2.crop.square.stack.fill
      case TipoNotificacion.sistema: return Icons.settings; // gearshape.fill
    }
  }

  Color get color {
    switch (this) {
      case TipoNotificacion.validacion: return Colors.green;
      case TipoNotificacion.observacion: return Colors.orange;
      case TipoNotificacion.rechazo: return Colors.red;
      case TipoNotificacion.publicacion: return Colors.blue;
      case TipoNotificacion.enRevision: return Colors.indigo;
      case TipoNotificacion.cuentaActivada: return const Color(0xFF2D6A4F);
      case TipoNotificacion.rolActualizado: return Colors.purple;
      case TipoNotificacion.sistema: return Colors.grey;
    }
  }
}

class Notificacion {
  final String id;
  final TipoNotificacion tipo;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final bool leida;
  final String? registroRelacionadoId;
  final String? usuarioId;

  Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.leida,
    this.registroRelacionadoId,
    this.usuarioId,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      tipo: TipoNotificacion.values.firstWhere((e) => e.name == json['tipo'], orElse: () => TipoNotificacion.sistema),
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fecha: DateTime.parse(json['fecha']),
      leida: json['leida'],
      registroRelacionadoId: json['registroRelacionadoId'],
      usuarioId: json['usuarioId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo.name,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
      'leida': leida,
      'registroRelacionadoId': registroRelacionadoId,
      'usuarioId': usuarioId,
    };
  }
}

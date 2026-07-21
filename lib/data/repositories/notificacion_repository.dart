import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../models/notificacion.dart';

abstract class NotificacionRepository {
  Future<List<Notificacion>> listar(String usuarioId);
  Future<void> marcarLeida(String id);
  Future<void> marcarTodasLeidas(String usuarioId);
  Future<void> eliminar(String id);
}

class RealNotificacionRepository implements NotificacionRepository {
  /// Traduce el `event_type` del backend al tipo que entiende la UI.
  /// Para `status_changed` el tipo concreto depende de `metadata.new_status`.
  /// Espejo de `NotificationDTO.toNotificacion()` (iOS).
  static TipoNotificacion _tipoDesde(Map<String, dynamic> json) {
    final eventType = json['event_type'] as String?;
    switch (eventType) {
      case 'account_activated':
        return TipoNotificacion.cuentaActivada;
      case 'account_deactivated':
        return TipoNotificacion.sistema;
      case 'record_received':
        return TipoNotificacion.enRevision;
      case 'status_changed':
        final metadata = json['metadata'];
        final nuevoEstado = metadata is Map ? metadata['new_status'] as String? : null;
        return switch (nuevoEstado) {
          'observado' => TipoNotificacion.observacion,
          'rechazado' => TipoNotificacion.rechazo,
          'validado' => TipoNotificacion.validacion,
          _ => TipoNotificacion.validacion,
        };
      default:
        return TipoNotificacion.sistema;
    }
  }

  static Notificacion _toNotificacion(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] as String,
      tipo: _tipoDesde(json),
      titulo: json['title'] as String? ?? '',
      descripcion: json['description'] as String? ?? '',
      fecha: parseApiDate(json['created_at']),
      leida: json['is_read'] as bool? ?? false,
      registroRelacionadoId: json['species_record_id'] as String?,
      usuarioId: json['user_id'] as String?,
    );
  }

  @override
  Future<List<Notificacion>> listar(String usuarioId) async {
    final json = await apiClient.get('/notifications/user/$usuarioId');
    if (json is! List) return const [];
    return json.map((e) => _toNotificacion(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> marcarLeida(String id) async {
    await apiClient.patch('/notifications/$id/read');
  }

  @override
  Future<void> marcarTodasLeidas(String usuarioId) async {
    await apiClient.patch('/notifications/user/$usuarioId/read-all');
  }

  @override
  Future<void> eliminar(String id) async {
    await apiClient.delete('/notifications/$id');
  }
}

final notificacionRepositoryProvider =
    Provider<NotificacionRepository>((ref) => RealNotificacionRepository());

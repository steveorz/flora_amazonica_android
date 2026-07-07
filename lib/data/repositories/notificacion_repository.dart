import '../../models/notificacion.dart';
import '../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class NotificacionRepository {
  Future<List<Notificacion>> listar(String usuarioId);
  Future<void> marcarLeida(String id);
  Future<void> marcarTodasLeidas(String usuarioId);
  Future<void> crear(Notificacion notificacion);
}

class RealNotificacionRepository implements NotificacionRepository {
  final APIClient apiClient = APIClient.shared;

  @override
  Future<List<Notificacion>> listar(String usuarioId) async {
    final List<dynamic> records = await apiClient.request(endpoint: "/notifications/user/$usuarioId");
    return records.map((r) {
      // Map Swift DTO logic here for simplicity if backend returns raw event_types
      final eventType = r['event_type'];
      TipoNotificacion tipo = TipoNotificacion.sistema;
      
      switch (eventType) {
        case "account_activated": tipo = TipoNotificacion.cuentaActivada; break;
        case "record_received": tipo = TipoNotificacion.enRevision; break;
        case "status_changed":
          final status = r['metadata']?['new_status'];
          switch (status) {
            case "observado": tipo = TipoNotificacion.observacion; break;
            case "rechazado": tipo = TipoNotificacion.rechazo; break;
            case "publicado": tipo = TipoNotificacion.publicacion; break;
            case "validado": tipo = TipoNotificacion.validacion; break;
            default: tipo = TipoNotificacion.validacion; break;
          }
          break;
      }
      
      return Notificacion(
        id: r['id'],
        tipo: tipo,
        titulo: r['title'],
        descripcion: r['description'],
        fecha: DateTime.parse(r['created_at']),
        leida: r['is_read'],
        registroRelacionadoId: r['species_record_id'],
        usuarioId: r['user_id'],
      );
    }).toList();
  }

  @override
  Future<void> marcarLeida(String id) async {
    await apiClient.request(endpoint: "/notifications/$id/read", method: "PATCH");
  }

  @override
  Future<void> marcarTodasLeidas(String usuarioId) async {
    await apiClient.request(endpoint: "/notifications/user/$usuarioId/read-all", method: "PATCH");
  }

  @override
  Future<void> crear(Notificacion notificacion) async {
    // Done on backend mostly
  }
}

final notificacionRepositoryProvider = Provider<NotificacionRepository>((ref) {
  return RealNotificacionRepository();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notificacion.dart';
import '../../data/repositories/notificacion_repository.dart';
import '../constants/app_error_kind.dart';
import '../network/api_client.dart';

/// Espejo de `NotificacionService` (iOS).
class NotificacionState {
  final List<Notificacion> notificaciones;
  final bool loading;
  final AppErrorKind? error;

  const NotificacionState({
    this.notificaciones = const [],
    this.loading = false,
    this.error,
  });

  /// Alimenta el badge de la pestaña "Avisos".
  int get noLeidas => notificaciones.where((n) => !n.leida).length;

  NotificacionState copyWith({
    List<Notificacion>? notificaciones,
    bool? loading,
    AppErrorKind? error,
    bool clearError = false,
  }) {
    return NotificacionState(
      notificaciones: notificaciones ?? this.notificaciones,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificacionService extends StateNotifier<NotificacionState> {
  NotificacionService(this._repo) : super(const NotificacionState());

  final NotificacionRepository _repo;

  static AppErrorKind _clasificar(Object e) =>
      e is ApiNetworkFailure ? AppErrorKind.sinConexion : AppErrorKind.servidor;

  Future<void> cargar(String usuarioId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final lista = await _repo.listar(usuarioId);
      // Las más recientes primero: el backend no garantiza el orden.
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
      state = state.copyWith(notificaciones: lista, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: _clasificar(e));
    }
  }

  Future<void> marcarLeida(String id) async {
    try {
      await _repo.marcarLeida(id);
      state = state.copyWith(
        notificaciones: [
          for (final n in state.notificaciones) n.id == id ? n.copyWith(leida: true) : n,
        ],
      );
    } catch (e) {
      state = state.copyWith(error: _clasificar(e));
    }
  }

  Future<void> marcarTodasLeidas(String usuarioId) async {
    try {
      await _repo.marcarTodasLeidas(usuarioId);
      state = state.copyWith(
        notificaciones: [for (final n in state.notificaciones) n.copyWith(leida: true)],
      );
    } catch (e) {
      state = state.copyWith(error: _clasificar(e));
    }
  }

  Future<void> eliminar(String id) async {
    // Eliminación optimista
    final backup = state.notificaciones;
    state = state.copyWith(
      notificaciones: state.notificaciones.where((n) => n.id != id).toList(),
    );
    try {
      await _repo.eliminar(id);
    } catch (e) {
      // Revertir en caso de error
      state = state.copyWith(notificaciones: backup, error: _clasificar(e));
    }
  }
}

final notificacionServiceProvider =
    StateNotifierProvider<NotificacionService, NotificacionState>(
  (ref) => NotificacionService(ref.watch(notificacionRepositoryProvider)),
);

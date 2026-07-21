import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/usuario.dart';
import '../../data/repositories/usuario_repository.dart';
import '../constants/app_error_kind.dart';
import '../constants/rol.dart';
import '../network/api_client.dart';

/// Espejo de `UsuarioService` (iOS). Sólo lo usa el módulo de Administrador.
class UsuarioState {
  final List<Usuario> usuarios;
  final bool loading;
  final AppErrorKind? error;

  const UsuarioState({
    this.usuarios = const [],
    this.loading = false,
    this.error,
  });

  // MARK: - Conteos para el dashboard

  Map<Rol, int> get conteoPorRol {
    final m = <Rol, int>{};
    for (final u in usuarios) {
      m[u.rol] = (m[u.rol] ?? 0) + 1;
    }
    return m;
  }

  Map<EstadoUsuario, int> get conteoPorEstado {
    final m = <EstadoUsuario, int>{};
    for (final u in usuarios) {
      m[u.estado] = (m[u.estado] ?? 0) + 1;
    }
    return m;
  }

  /// Cuentas esperando activación, la más reciente primero.
  List<Usuario> get pendientes {
    final lista = usuarios.where((u) => u.estado == EstadoUsuario.pendiente).toList();
    lista.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
    return lista;
  }

  UsuarioState copyWith({
    List<Usuario>? usuarios,
    bool? loading,
    AppErrorKind? error,
    bool clearError = false,
  }) {
    return UsuarioState(
      usuarios: usuarios ?? this.usuarios,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UsuarioService extends StateNotifier<UsuarioState> {
  UsuarioService(this._repo) : super(const UsuarioState());

  final UsuarioRepository _repo;

  static AppErrorKind _clasificar(Object e) => switch (e) {
        ApiNetworkFailure() => AppErrorKind.sinConexion,
        ApiRequestFailed(statusCode: 401 || 403) => AppErrorKind.sinPermisos,
        _ => AppErrorKind.servidor,
      };

  Future<void> cargar() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      state = state.copyWith(usuarios: await _repo.listar(), loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: _clasificar(e));
    }
  }

  /// Sólo refleja el cambio en memoria si el backend lo aceptó. (iOS usaba
  /// `try?` en el repositorio y actualizaba la UI aunque la llamada fallara.)
  Future<void> actualizarEstado(String id, EstadoUsuario nuevo) async {
    await _repo.actualizarEstado(id, nuevo);
    state = state.copyWith(
      usuarios: [
        for (final u in state.usuarios) u.id == id ? u.copyWith(estado: nuevo) : u,
      ],
    );
  }

  Future<void> actualizarRol(String id, Rol nuevo) async {
    await _repo.actualizarRol(id, nuevo);
    state = state.copyWith(
      usuarios: [
        for (final u in state.usuarios) u.id == id ? u.copyWith(rol: nuevo) : u,
      ],
    );
  }

  Usuario? get(String id) {
    for (final u in state.usuarios) {
      if (u.id == id) return u;
    }
    return null;
  }
}

final usuarioServiceProvider = StateNotifierProvider<UsuarioService, UsuarioState>(
  (ref) => UsuarioService(ref.watch(usuarioRepositoryProvider)),
);

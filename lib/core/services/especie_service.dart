import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/especie.dart';
import '../../data/repositories/especie_repository.dart';
import '../constants/app_error_kind.dart';
import '../network/api_client.dart';

/// Estado observable del catálogo de especies.
/// Espejo de `EspecieService` (iOS, Services/EspecieService.swift).
class EspecieState {
  final List<Especie> especies;
  final bool loading;
  final AppErrorKind? error;

  const EspecieState({
    this.especies = const [],
    this.loading = false,
    this.error,
  });

  EspecieState copyWith({
    List<Especie>? especies,
    bool? loading,
    AppErrorKind? error,
    bool clearError = false,
  }) {
    return EspecieState(
      especies: especies ?? this.especies,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EspecieService extends StateNotifier<EspecieState> {
  EspecieService(this._repo) : super(const EspecieState());

  final EspecieRepository _repo;

  /// Un fallo de red y uno de servidor se muestran distinto al usuario.
  static AppErrorKind _clasificar(Object e) =>
      e is ApiNetworkFailure ? AppErrorKind.sinConexion : AppErrorKind.servidor;

  Future<void> cargar() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      state = state.copyWith(especies: await _repo.listar(), loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: _clasificar(e));
    }
  }

  Future<void> buscar(String query) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      state = state.copyWith(especies: await _repo.buscar(query), loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: _clasificar(e));
    }
  }

  Future<Especie> get(String id) => _repo.get(id);

  List<Especie> registrosDe(String usuarioId) =>
      state.especies.where((e) => e.registradorId == usuarioId).toList();

  Future<Especie> crear(Especie especie) async {
    final nueva = await _repo.crear(especie);
    state = state.copyWith(especies: [...state.especies, nueva]);
    return nueva;
  }

  Future<Especie> actualizar(Especie especie) async {
    final actualizada = await _repo.actualizar(especie);
    state = state.copyWith(
      especies: [
        for (final e in state.especies) e.id == especie.id ? actualizada : e,
      ],
    );
    return actualizada;
  }

  Future<void> eliminar(String id) async {
    await _repo.eliminar(id);
    state = state.copyWith(
      especies: state.especies.where((e) => e.id != id).toList(),
    );
  }
}

final especieServiceProvider = StateNotifierProvider<EspecieService, EspecieState>(
  (ref) => EspecieService(ref.watch(especieRepositoryProvider)),
);

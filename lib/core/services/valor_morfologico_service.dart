import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/valor_morfologico.dart';
import '../../data/repositories/valor_morfologico_repository.dart';
import '../constants/app_error_kind.dart';
import '../network/api_client.dart';

/// Espejo de `ValorMorfologicoService` (iOS). Alimenta la pantalla de Admin
/// "Valores morfológicos".
class ValorMorfologicoState {
  final List<ValorMorfologico> valores;
  final bool loading;
  final AppErrorKind? error;

  const ValorMorfologicoState({
    this.valores = const [],
    this.loading = false,
    this.error,
  });

  List<String> get categorias {
    final set = valores.map((v) => v.categoria).toSet().toList();
    set.sort();
    return set;
  }

  List<ValorMorfologico> enCategoria(String categoria) {
    final lista = valores.where((v) => v.categoria == categoria).toList();
    lista.sort((a, b) => a.orden.compareTo(b.orden));
    return lista;
  }

  ValorMorfologicoState copyWith({
    List<ValorMorfologico>? valores,
    bool? loading,
    AppErrorKind? error,
    bool clearError = false,
  }) {
    return ValorMorfologicoState(
      valores: valores ?? this.valores,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ValorMorfologicoService extends StateNotifier<ValorMorfologicoState> {
  ValorMorfologicoService(this._repo) : super(const ValorMorfologicoState());

  final ValorMorfologicoRepository _repo;

  static AppErrorKind _clasificar(Object e) =>
      e is ApiNetworkFailure ? AppErrorKind.sinConexion : AppErrorKind.servidor;

  Future<void> cargar() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      state = state.copyWith(valores: await _repo.listar(), loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: _clasificar(e));
    }
  }

  Future<void> crear(ValorMorfologico v) async {
    try {
      await _repo.crear(v);
      final lista = [...state.valores, v]
        ..sort((a, b) {
          final c = a.categoria.compareTo(b.categoria);
          return c != 0 ? c : a.orden.compareTo(b.orden);
        });
      state = state.copyWith(valores: lista);
    } catch (e) {
      state = state.copyWith(error: _clasificar(e));
    }
  }

  Future<void> actualizar(ValorMorfologico v) async {
    try {
      await _repo.actualizar(v);
      state = state.copyWith(
        valores: [for (final x in state.valores) x.codigo == v.codigo ? v : x],
      );
    } catch (e) {
      state = state.copyWith(error: _clasificar(e));
    }
  }

  Future<void> eliminar(String codigo) async {
    try {
      await _repo.eliminar(codigo);
      state = state.copyWith(
        valores: state.valores.where((v) => v.codigo != codigo).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: _clasificar(e));
    }
  }

  Future<void> toggleActivo(ValorMorfologico v) => actualizar(v.copyWith(activo: !v.activo));
}

final valorMorfologicoServiceProvider =
    StateNotifierProvider<ValorMorfologicoService, ValorMorfologicoState>(
  (ref) => ValorMorfologicoService(ref.watch(valorMorfologicoRepositoryProvider)),
);

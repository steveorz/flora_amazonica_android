import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/estado_registro.dart';
import '../../../core/constants/habito.dart';
import '../../../data/models/especie.dart';
import 'morf_dimensions.dart';

/// Resultado de evaluar una especie contra el set actual de filtros.
class MorfMatch {
  final Especie especie;
  final int coincidencias;
  final int total;

  const MorfMatch(this.especie, this.coincidencias, this.total);
}

class MorfSearchState {
  /// Hábito elegido en CS-02. `null` = "no estoy seguro" (no filtra por hábito).
  final Habito? habito;

  /// Selecciones por dimensión: id de dimensión → labels seleccionados.
  final Map<String, Set<String>> selecciones;

  const MorfSearchState({this.habito, this.selecciones = const {}});

  /// Dimensiones con al menos una opción marcada.
  List<MorfDimension> get dimensionesActivas => MorfDimensions.todas
      .where((d) => (selecciones[d.id] ?? const <String>{}).isNotEmpty)
      .toList();

  MorfSearchState copyWith({
    Habito? habito,
    bool limpiarHabito = false,
    Map<String, Set<String>>? selecciones,
  }) {
    return MorfSearchState(
      habito: limpiarHabito ? null : (habito ?? this.habito),
      selecciones: selecciones ?? this.selecciones,
    );
  }
}

/// Espejo de `MorfologicalSearchStore` (iOS).
class MorfSearchNotifier extends StateNotifier<MorfSearchState> {
  MorfSearchNotifier() : super(const MorfSearchState());

  /// "No estoy seguro" es un estado válido, no la ausencia de elección.
  void setHabito(Habito? h) =>
      state = h == null ? state.copyWith(limpiarHabito: true) : state.copyWith(habito: h);

  void toggle(String dimensionId, String opcion) {
    final selecciones = {
      for (final e in state.selecciones.entries) e.key: Set<String>.of(e.value)
    };
    final set = selecciones.putIfAbsent(dimensionId, () => <String>{});
    if (!set.remove(opcion)) set.add(opcion);
    if (set.isEmpty) selecciones.remove(dimensionId);
    state = state.copyWith(selecciones: selecciones);
  }

  void limpiar(String dimensionId, String opcion) {
    final selecciones = {
      for (final e in state.selecciones.entries) e.key: Set<String>.of(e.value)
    };
    selecciones[dimensionId]?.remove(opcion);
    if (selecciones[dimensionId]?.isEmpty ?? false) selecciones.remove(dimensionId);
    state = state.copyWith(selecciones: selecciones);
  }

  void quitarFiltros() => state = state.copyWith(selecciones: const {});

  void reset() => state = const MorfSearchState();

  /// Texto donde se buscan las raíces: todo lo que describe a la especie.
  static String _textoBuscable(Especie e) {
    return [
      e.nombreLocal,
      e.familia,
      e.nombreCientifico,
      e.ubicacion.tipoHabitat,
      ...e.caracteres.values,
    ].join(' ').toLowerCase();
  }

  /// Evalúa las especies contra los filtros y devuelve los matches ordenados
  /// por número de coincidencias, de mayor a menor.
  ///
  /// Sólo considera lo que ve un consultor (validado), salvo
  /// que la búsqueda sea exhaustiva (para validadores/admins).
  List<MorfMatch> evaluar(List<Especie> especies, {bool permitirTodas = false}) {
    var base = especies;
    
    // 1. Filtrar por estado si aplica
    if (!permitirTodas) {
      base = base
          .where((e) => e.estado == EstadoRegistro.validado)
          .toList();
    }
    if (state.habito != null) {
      base = base.where((e) => e.habito == state.habito).toList();
    }

    final dims = state.dimensionesActivas;
    if (dims.isEmpty) {
      // Sin filtros: todo el universo, sin puntuación.
      return base.map((e) => MorfMatch(e, 0, 0)).toList();
    }

    final matches = <MorfMatch>[];
    for (final e in base) {
      final texto = _textoBuscable(e);
      var aciertos = 0;
      for (final dim in dims) {
        final labels = state.selecciones[dim.id]!;
        final acierta = dim.opciones
            .where((o) => labels.contains(o.label))
            .any((o) => o.stems.any((s) => texto.contains(s.toLowerCase())));
        if (acierta) aciertos++;
      }
      if (aciertos > 0) matches.add(MorfMatch(e, aciertos, dims.length));
    }

    matches.sort((a, b) => b.coincidencias.compareTo(a.coincidencias));
    return matches;
  }
}

/// El flujo de búsqueda es efímero: se descarta al cerrarlo.
final morfSearchProvider =
    StateNotifierProvider.autoDispose<MorfSearchNotifier, MorfSearchState>(
  (ref) => MorfSearchNotifier(),
);

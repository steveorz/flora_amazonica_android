import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_prefs.dart';

/// Espejo de `FavoritosStore` + `FavoritosStorage` (iOS).
/// Guarda los ids de especie marcados como favoritos y los persiste al vuelo.
class FavoritosNotifier extends StateNotifier<Set<String>> {
  FavoritosNotifier() : super(_load());

  static Set<String> _load() =>
      (prefs.getStringList(PrefsKeys.favoritos) ?? const <String>[]).toSet();

  void toggle(String id) {
    final next = Set<String>.of(state);
    if (!next.remove(id)) next.add(id);
    state = next;
    prefs.setStringList(PrefsKeys.favoritos, next.toList());
  }

  bool isFavorite(String id) => state.contains(id);

  void limpiar() {
    state = <String>{};
    prefs.remove(PrefsKeys.favoritos);
  }
}

final favoritosProvider =
    StateNotifierProvider<FavoritosNotifier, Set<String>>((ref) => FavoritosNotifier());

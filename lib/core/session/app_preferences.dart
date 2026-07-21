import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_prefs.dart';
import '../storage/draft_storage.dart';

/// Espejo de `AppPreferences.Tema`.
enum Tema {
  sistema,
  claro,
  oscuro;

  String get label => switch (this) {
        Tema.sistema => 'Sistema',
        Tema.claro => 'Claro',
        Tema.oscuro => 'Oscuro',
      };

  ThemeMode get themeMode => switch (this) {
        Tema.sistema => ThemeMode.system,
        Tema.claro => ThemeMode.light,
        Tema.oscuro => ThemeMode.dark,
      };
}

/// Espejo de `AppPreferences.Idioma`.
enum Idioma {
  espanol('es'),
  ingles('en');

  final String code;
  const Idioma(this.code);

  String get label => switch (this) {
        Idioma.espanol => 'Español',
        Idioma.ingles => 'Inglés',
      };
}

@immutable
class PreferenciasState {
  final Tema tema;
  final Idioma idioma;
  final bool notificacionesActivas;

  const PreferenciasState({
    required this.tema,
    required this.idioma,
    required this.notificacionesActivas,
  });

  PreferenciasState copyWith({Tema? tema, Idioma? idioma, bool? notificacionesActivas}) {
    return PreferenciasState(
      tema: tema ?? this.tema,
      idioma: idioma ?? this.idioma,
      notificacionesActivas: notificacionesActivas ?? this.notificacionesActivas,
    );
  }
}

/// Preferencias persistidas del usuario (tema, idioma, notificaciones).
/// Espejo de `AppPreferences` (iOS, Core/Session/AppPreferences.swift).
class PreferenciasNotifier extends StateNotifier<PreferenciasState> {
  PreferenciasNotifier() : super(_load());

  static PreferenciasState _load() {
    return PreferenciasState(
      tema: Tema.values.firstWhere(
        (t) => t.name == prefs.getString(PrefsKeys.tema),
        orElse: () => Tema.sistema,
      ),
      idioma: Idioma.values.firstWhere(
        (i) => i.code == prefs.getString(PrefsKeys.idioma),
        orElse: () => Idioma.espanol,
      ),
      notificacionesActivas: prefs.getBool(PrefsKeys.notificaciones) ?? true,
    );
  }

  void setTema(Tema tema) {
    state = state.copyWith(tema: tema);
    prefs.setString(PrefsKeys.tema, tema.name);
  }

  void setIdioma(Idioma idioma) {
    state = state.copyWith(idioma: idioma);
    prefs.setString(PrefsKeys.idioma, idioma.code);
  }

  void setNotificaciones(bool activas) {
    state = state.copyWith(notificacionesActivas: activas);
    prefs.setBool(PrefsKeys.notificaciones, activas);
  }

  /// "Limpiar caché": borra borradores (y sus fotos en disco) y favoritos.
  /// Las preferencias en sí se conservan, igual que en iOS.
  Future<void> limpiarCache() async {
    await DraftStorage.deleteAll();
    await prefs.remove(PrefsKeys.favoritos);
  }
}

final preferenciasProvider =
    StateNotifierProvider<PreferenciasNotifier, PreferenciasState>(
  (ref) => PreferenciasNotifier(),
);

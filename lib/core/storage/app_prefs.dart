import 'package:shared_preferences/shared_preferences.dart';

/// Acceso síncrono a SharedPreferences, equivalente a `UserDefaults.standard`.
///
/// Se inicializa una sola vez en `main()` antes de `runApp`, de modo que el
/// resto del código (stores, storages) pueda leer y escribir sin `await`,
/// igual que hace la app iOS.
late final SharedPreferences prefs;

Future<void> initPrefs() async {
  prefs = await SharedPreferences.getInstance();
}

/// Claves usadas en disco. Mismos nombres que en iOS para que un futuro
/// export/import de datos sea compatible entre plataformas.
abstract final class PrefsKeys {
  static const tema = 'app.tema';
  static const idioma = 'app.idioma';
  static const notificaciones = 'app.notif';
  static const drafts = 'registrador.drafts';
  static const favoritos = 'favoritos.ids';
}

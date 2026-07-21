import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../data/models/especie_draft.dart';
import '../../data/models/foto.dart';
import 'app_prefs.dart';

/// Persistencia de borradores. Espejo de `DraftStorage` (iOS):
/// - el JSON del draft va a SharedPreferences (allí: UserDefaults)
/// - los bytes de cada foto van a disco como `draft_<id>_<tipo>.jpg`
///   (allí: `.documentDirectory`), porque son demasiado grandes para prefs.
abstract final class DraftStorage {
  /// Ordenados por actualización más reciente primero, como en iOS.
  static List<EspecieDraft> loadAll() {
    final raw = prefs.getString(PrefsKeys.drafts);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final drafts = list
          .map((e) => EspecieDraft.fromJson(e as Map<String, dynamic>))
          .toList();
      drafts.sort((a, b) => b.fechaActualizacion.compareTo(a.fechaActualizacion));
      return drafts;
    } catch (_) {
      // Borradores corruptos (p. ej. tras un cambio de esquema): empezamos limpio
      // en vez de dejar la pantalla de borradores rota para siempre.
      return [];
    }
  }

  static EspecieDraft? get(String id) {
    for (final d in loadAll()) {
      if (d.id == id) return d;
    }
    return null;
  }

  static Future<void> upsert(EspecieDraft draft) async {
    final all = loadAll();
    final idx = all.indexWhere((d) => d.id == draft.id);
    if (idx >= 0) {
      all[idx] = draft;
    } else {
      all.add(draft);
    }
    await _save(all);
  }

  /// Borra el draft y además sus fotos en disco (iOS deja huérfanos los jpg;
  /// aquí los limpiamos para no acumular basura).
  static Future<void> delete(String id) async {
    final all = loadAll()..removeWhere((d) => d.id == id);
    await _save(all);
    for (final tipo in TipoFoto.values) {
      final file = await _photoFile(id, tipo);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {/* el archivo ya no está: nada que hacer */}
      }
    }
  }

  static Future<void> deleteAll() async {
    for (final d in loadAll()) {
      await delete(d.id);
    }
    await prefs.remove(PrefsKeys.drafts);
  }

  static Future<void> _save(List<EspecieDraft> drafts) async {
    await prefs.setString(
      PrefsKeys.drafts,
      jsonEncode(drafts.map((d) => d.toJson()).toList()),
    );
  }

  // MARK: - Fotos en disco

  static Future<File> _photoFile(String draftId, TipoFoto tipo) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/draft_${draftId}_${tipo.value}.jpg');
  }

  static Future<void> savePhoto(String draftId, TipoFoto tipo, Uint8List bytes) async {
    final file = await _photoFile(draftId, tipo);
    await file.writeAsBytes(bytes, flush: true);
  }

  static Future<Uint8List?> loadPhoto(String draftId, TipoFoto tipo) async {
    final file = await _photoFile(draftId, tipo);
    if (!file.existsSync()) return null;
    try {
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Recupera todas las fotos guardadas de un borrador, para retomarlo.
  static Future<Map<TipoFoto, Uint8List>> loadPhotos(String draftId) async {
    final result = <TipoFoto, Uint8List>{};
    for (final tipo in TipoFoto.values) {
      final bytes = await loadPhoto(draftId, tipo);
      if (bytes != null) result[tipo] = bytes;
    }
    return result;
  }
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/estado_registro.dart';
import '../../core/constants/habito.dart';
import '../../core/constants/tipo_vida.dart';
import '../../core/network/api_client.dart';
import '../models/datos_dasometricos.dart';
import '../models/especie.dart';
import '../models/foto.dart';
import '../models/ubicacion.dart';

abstract class EspecieRepository {
  Future<List<Especie>> listar();
  Future<List<Especie>> buscar(String query);
  Future<Especie> get(String id);
  Future<List<Especie>> listarPorRegistrador(String usuarioId);
  Future<Especie> crear(Especie especie);
  Future<Especie> actualizar(Especie especie);
  Future<void> eliminar(String id);
}

/// Ubicación por defecto cuando el registro no trae coordenadas (Lima),
/// igual que en `RealEspecieRepository.toEspecie()` de iOS.
const _ubicacionPorDefecto = Ubicacion(
  lat: -12.046374,
  long: -77.042793,
  referencia: '',
  altitud: 0.0,
  tipoHabitat: '',
);

class RealEspecieRepository implements EspecieRepository {
  // MARK: - Mapeo de DTOs

  /// `morphological_data` es un diccionario libre: el backend puede mandar
  /// números, booleanos o strings. Espejo de `SafeStringDictionary` (iOS):
  /// normalizamos todo a String y descartamos nulos.
  static Map<String, String> _safeStringMap(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, String>{};
    raw.forEach((key, value) {
      if (value == null) return;
      result[key.toString()] = value.toString();
    });
    return result;
  }

  /// Espejo de `SpeciesRecordDTO.toEspecie()`.
  static Especie _recordToEspecie(Map<String, dynamic> json) {
    final altura = (json['height'] as num?)?.toDouble();
    final cap = (json['cap'] as num?)?.toDouble();
    final diamCopa = (json['crown_diameter'] as num?)?.toDouble() ?? 0.0;

    // iOS sólo arma los dasométricos si vienen altura Y cap.
    final DatosDasometricos? daso = (altura != null && cap != null)
        ? DatosDasometricos(
            altura: altura,
            cap: cap,
            diamCopaParalelo: diamCopa,
            diamCopaPerpendicular: diamCopa,
            alturaInicioCopa: 0.0,
          )
        : null;

    final lat = (json['latitude'] as num?)?.toDouble();
    final lon = (json['longitude'] as num?)?.toDouble();
    final ubicacion = (lat != null && lon != null)
        ? Ubicacion(lat: lat, long: lon, referencia: '', altitud: 0.0, tipoHabitat: '')
        : _ubicacionPorDefecto;

    // Fotos: se descarta cualquiera cuyo tipo o url no sean utilizables.
    final fotos = <Foto>[];
    for (final p in (json['photos'] as List? ?? const [])) {
      if (p is! Map) continue;
      final tipo = TipoFoto.fromRaw(p['photo_type'] as String?);
      final url = p['cloudinary_url'] as String?;
      if (tipo == null || url == null || url.isEmpty) continue;
      fotos.add(Foto(
        id: p['id'] as String,
        tipo: tipo,
        url: url,
        autor: 'Desconocido',
        fecha: DateTime.now(),
      ));
    }
    final caracteres = _safeStringMap(json['morphological_data']);
    final morphLocalName = caracteres.remove('local_name') ?? caracteres.remove('loacal_name') ?? caracteres.remove('LOCAL NAME');
    final nombreLocal = json['local_name'] as String? ?? morphLocalName ?? json['observation_notes'] as String? ?? '';

    return Especie(
      id: json['id'] as String,
      nombreCientifico: json['scientific_name'] as String? ?? 'Desconocido',
      autorNombre: json['author_name'] as String? ?? '',
      familia: json['family'] as String? ?? 'Desconocida',
      nombreLocal: nombreLocal,
      habito: Habito.fromRaw(json['habit'] as String?),
      tipoVida: TipoVida.fromRaw(json['life_type'] as String?),
      distribucionPaises:
          (json['country_distribution'] as List?)?.map((e) => e.toString()).toList() ?? [],
      caracteres: caracteres,
      datosDasometricos: daso,
      ubicacion: ubicacion,
      fotos: fotos,
      estado: EstadoRegistro.fromRaw(json['status'] as String?),
      codigoSeguimiento: json['tracking_code'] as String? ?? '',
      registradorId: (json['user_id'] ?? json['registrador_id'] ?? json['registrar_id'])?.toString() ?? '',
      fechaEnvio: parseApiDate(json['submitted_at'] ?? json['created_at']),
      historialEstados: const [],
    );
  }

  /// Espejo de `SpeciesCatalogDTO.toEspecie()`: entradas del catálogo oficial,
  /// que no son registros de campo (no tienen fotos, hábito ni ubicación).
  static Especie _catalogToEspecie(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final activo = json['is_active'] as bool? ?? true;
    return Especie(
      id: id,
      catalogId: id,
      nombreCientifico: json['scientific_name'] as String? ?? 'Desconocido',
      autorNombre: '',
      familia: json['family'] as String? ?? 'Desconocida',
      nombreLocal: 'Sin nombre común',
      habito: Habito.arbol,
      tipoVida: TipoVida.terrestre,
      distribucionPaises: const [],
      caracteres: const {},
      ubicacion: const Ubicacion(
        lat: 0.0,
        long: 0.0,
        referencia: '',
        altitud: 0.0,
        tipoHabitat: '',
      ),
      fotos: const [],
      estado: activo ? EstadoRegistro.validado : EstadoRegistro.borrador,
      codigoSeguimiento: 'CAT-${id.length >= 6 ? id.substring(0, 6) : id}',
      registradorId: '',
      fechaEnvio: DateTime.now(),
      historialEstados: const [],
    );
  }

  /// Cuerpo que espera el backend al crear/actualizar. Espejo de `CreateSpeciesDTO`.
  static Map<String, dynamic> _toCreateDto(Especie e) {
    // El nombre local ahora viaja como campo propio.
    final morph = Map<String, String>.of(e.caracteres);

    final daso = e.datosDasometricos;
    final dto = {
      'scientific_name': e.nombreCientifico,
      'family': e.familia,
      'habit': e.habito.name,
      'country_distribution': e.distribucionPaises,
      'height': daso?.altura,
      'crown_diameter_parallel': daso?.diamCopaParalelo,
      'crown_diameter_perpendicular': daso?.diamCopaPerpendicular,
      'crown_base_height': daso?.alturaInicioCopa,
      'cap': daso?.cap,
      'longitude': e.ubicacion.long,
      'latitude': e.ubicacion.lat,
      'morphological_data': morph,
      'is_draft': e.estado == EstadoRegistro.borrador,
      'author_name': e.autorNombre.isEmpty ? null : e.autorNombre,
      'observation_notes': null,
      'life_type': e.tipoVida.name,
      'local_name': e.nombreLocal,
      'species_catalog_id': e.catalogId,
    };
    debugPrint('PATCH/POST Payload: $dto');
    return dto;
  }

  // MARK: - Lectura

  /// Une las tres fuentes que consulta iOS: registros propios, catálogo oficial
  /// y registros públicos validados. Un fallo en una fuente no tumba las otras.
  Future<List<Especie>> _fetchAllMerged() async {
    Future<List<Map<String, dynamic>>> safeList(String endpoint) async {
      try {
        final json = await apiClient.get(endpoint);
        if (json is List) return json.cast<Map<String, dynamic>>();
      } catch (e) {
        debugPrint('Error obteniendo $endpoint: $e');
      }
      return const [];
    }

    Future<List<Map<String, dynamic>>> safePaginated(String endpoint) async {
      try {
        final json = await apiClient.get(endpoint);
        if (json is Map && json['data'] is List) {
          return (json['data'] as List).cast<Map<String, dynamic>>();
        }
      } catch (e) {
        debugPrint('Error obteniendo $endpoint: $e');
      }
      return const [];
    }

    // Se lanzan en paralelo: iOS las hace en serie, pero el resultado es el
    // mismo y aquí la entrada tras el login es notablemente más rápida.
    final results = await Future.wait([
      safeList('/especies'),
      safeList('/catalogo/especies'),
      safePaginated('/catalogo/buscar?limit=100'),
    ]);

    final records = results[0];
    final catalog = results[1];
    final publicRecords = results[2];

    // Un mismo registro puede venir de /especies y de /catalogo/buscar.
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final r in [...records, ...publicRecords]) {
      final id = r['id'];
      if (id is String && seen.add(id)) unique.add(r);
    }

    return [
      ...unique.map(_recordToEspecie),
      ...catalog.map(_catalogToEspecie),
    ];
  }

  @override
  Future<List<Especie>> listar() => _fetchAllMerged();

  /// Filtro en cliente sobre las tres fuentes, igual que iOS.
  @override
  Future<List<Especie>> buscar(String query) async {
    final todas = await _fetchAllMerged();
    final q = query.toLowerCase();
    return todas
        .where((e) =>
            e.nombreCientifico.toLowerCase().contains(q) ||
            e.familia.toLowerCase().contains(q) ||
            e.codigoSeguimiento.toLowerCase().contains(q) ||
            e.nombreLocal.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<Especie> get(String id) async {
    // Primero como registro de campo; si es un id del catálogo, el endpoint
    // devuelve 404 y hay que buscarlo en la lista completa.
    try {
      final json = await apiClient.get('/especies/$id');
      if (json is Map<String, dynamic> && json['id'] != null) {
        return _recordToEspecie(json);
      }
    } catch (_) {/* cae al merge de abajo */}

    final todas = await _fetchAllMerged();
    for (final e in todas) {
      if (e.id == id) return e;
    }
    throw const ApiRequestFailed(404, 'Especie no encontrada');
  }

  @override
  Future<List<Especie>> listarPorRegistrador(String usuarioId) async {
    final todas = await _fetchAllMerged();
    return todas.where((e) => e.registradorId == usuarioId).toList();
  }

  // MARK: - Escritura

  @override
  Future<Especie> crear(Especie especie) async {
    final record = await apiClient.post('/especies', body: _toCreateDto(especie))
        as Map<String, dynamic>;
    await _subirFotos(record['id'] as String, especie.fotos);
    return _recordToEspecie(record);
  }

  @override
  Future<Especie> actualizar(Especie especie) async {
    final record = await apiClient.patch('/especies/${especie.id}', body: _toCreateDto(especie))
        as Map<String, dynamic>;
    await _subirFotos(record['id'] as String, especie.fotos);
    
    // Si la especie pasó a "en_revision" (ej. al reenviar una observación),
    // el backend requiere que se llame a esta ruta específica.
    if (especie.estado == EstadoRegistro.enRevision) {
      try {
        await apiClient.post('/especies/${especie.id}/enviar');
      } catch (e) {
        throw Exception('El backend rechazó el reenvío (/especies/.../enviar): $e');
      }
    }
    
    return _recordToEspecie(record);
  }

  @override
  Future<void> eliminar(String id) async {
    try {
      await apiClient.delete('/especies/$id');
    } catch (e) {
      debugPrint('Error eliminando especie $id: $e');
    }
  }

  /// Sube sólo las fotos que tienen bytes locales (las que ya están en
  /// Cloudinary llegan sin `localData`). Un fallo de subida no invalida el
  /// registro, que ya fue creado: se registra y se sigue, como en iOS.
  Future<void> _subirFotos(String recordId, List<Foto> fotos) async {
    for (final foto in fotos) {
      final bytes = foto.localData;
      if (bytes == null) continue;
      try {
        await apiClient.uploadMultipart(
          '/especies/fotos',
          fileBytes: bytes,
          fileName: 'foto_${foto.tipo.value}.jpg',
          mimeType: 'image/jpeg',
          parameters: {
            'species_record_id': recordId,
            'photo_type': foto.tipo.value,
          },
        );
      } catch (e) {
        debugPrint('Error subiendo foto ${foto.tipo.value}: $e');
      }
    }
  }
}

/// Código de seguimiento para registros nuevos, con el formato de iOS.
String generarCodigoSeguimiento() {
  final n = 10000 + math.Random().nextInt(90000);
  return 'FAM-${DateTime.now().year}-$n';
}

final especieRepositoryProvider = Provider<EspecieRepository>((ref) => RealEspecieRepository());

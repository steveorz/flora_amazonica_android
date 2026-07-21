import '../../core/constants/estado_registro.dart';
import '../../core/constants/habito.dart';
import '../../core/constants/tipo_vida.dart';
import '../../core/network/api_client.dart';
import 'datos_dasometricos.dart';
import 'especie.dart';
import 'foto.dart';
import 'ubicacion.dart';

/// Estado en construcción del wizard de nuevo registro.
/// Serializable para guardarse como borrador (JSON en SharedPreferences),
/// espejo de `EspecieDraft` (iOS, Data/Mock/EspecieDraft.swift).
///
/// Las imágenes NO viven aquí: sólo se guardan los *tipos* capturados
/// (`fotosCapturadas`). Los bytes van a disco vía [DraftStorage].
class EspecieDraft {
  String id;
  String? catalogId;
  String nombreCientifico;
  String autorNombre;
  String familia;
  String nombreLocal;
  Habito? habito;
  TipoVida? tipoVida;
  List<String> distribucionPaises;

  /// Caracteres morfológicos dinámicos (la clave depende del hábito).
  Map<String, String> caracteres;
  DatosDasometricos? datosDasometricos;
  Ubicacion? ubicacion;

  /// Qué tipos de foto fueron capturados.
  Set<TipoFoto> fotosCapturadas;

  /// Último paso visitado (1–7) para retomar el borrador.
  int pasoActual;
  DateTime fechaCreacion;
  DateTime fechaActualizacion;

  bool get isEmpty {
    return (catalogId == null || catalogId!.trim().isEmpty) &&
        nombreCientifico.trim().isEmpty &&
        autorNombre.trim().isEmpty &&
        familia.trim().isEmpty &&
        nombreLocal.trim().isEmpty &&
        habito == null &&
        tipoVida == null &&
        distribucionPaises.isEmpty &&
        caracteres.isEmpty &&
        datosDasometricos == null &&
        ubicacion == null &&
        fotosCapturadas.isEmpty;
  }

  EspecieDraft({
    String? id,
    this.catalogId,
    this.nombreCientifico = '',
    this.autorNombre = '',
    this.familia = '',
    this.nombreLocal = '',
    this.habito,
    this.tipoVida,
    List<String>? distribucionPaises,
    Map<String, String>? caracteres,
    this.datosDasometricos,
    this.ubicacion,
    Set<TipoFoto>? fotosCapturadas,
    this.pasoActual = 1,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        distribucionPaises = distribucionPaises ?? <String>[],
        caracteres = caracteres ?? <String, String>{},
        fotosCapturadas = fotosCapturadas ?? <TipoFoto>{},
        fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaActualizacion = fechaActualizacion ?? DateTime.now();

  /// Inicializa desde una Especie existente (para edición).
  factory EspecieDraft.fromEspecie(Especie especie) {
    return EspecieDraft(
      id: especie.id,
      catalogId: especie.catalogId,
      nombreCientifico: especie.nombreCientifico,
      autorNombre: especie.autorNombre,
      familia: especie.familia,
      nombreLocal: especie.nombreLocal,
      habito: especie.habito,
      tipoVida: especie.tipoVida,
      distribucionPaises: List.of(especie.distribucionPaises),
      caracteres: Map.of(especie.caracteres),
      datosDasometricos: especie.datosDasometricos,
      ubicacion: especie.ubicacion,
      fotosCapturadas: especie.fotos.map((f) => f.tipo).toSet(),
      fechaCreacion: especie.fechaEnvio,
    );
  }

  factory EspecieDraft.fromJson(Map<String, dynamic> json) {
    return EspecieDraft(
      id: json['id'] as String,
      catalogId: json['catalogId'] as String?,
      nombreCientifico: json['nombreCientifico'] as String? ?? '',
      autorNombre: json['autorNombre'] as String? ?? '',
      familia: json['familia'] as String? ?? '',
      nombreLocal: json['nombreLocal'] as String? ?? '',
      habito: json['habito'] != null ? Habito.fromRaw(json['habito'] as String) : null,
      tipoVida: json['tipoVida'] != null ? TipoVida.fromRaw(json['tipoVida'] as String) : null,
      distribucionPaises:
          (json['distribucionPaises'] as List?)?.map((e) => e.toString()).toList() ?? [],
      caracteres: Map<String, String>.from(json['caracteres'] as Map? ?? {}),
      datosDasometricos: json['datosDasometricos'] != null
          ? DatosDasometricos.fromJson(json['datosDasometricos'] as Map<String, dynamic>)
          : null,
      ubicacion: json['ubicacion'] != null
          ? Ubicacion.fromJson(json['ubicacion'] as Map<String, dynamic>)
          : null,
      fotosCapturadas: (json['fotosCapturadas'] as List? ?? [])
          .map((e) => TipoFoto.fromRaw(e as String))
          .whereType<TipoFoto>()
          .toSet(),
      pasoActual: json['pasoActual'] as int? ?? 1,
      fechaCreacion: parseApiDate(json['fechaCreacion']),
      fechaActualizacion: parseApiDate(json['fechaActualizacion']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'catalogId': catalogId,
        'nombreCientifico': nombreCientifico,
        'autorNombre': autorNombre,
        'familia': familia,
        'nombreLocal': nombreLocal,
        'habito': habito?.name,
        'tipoVida': tipoVida?.name,
        'distribucionPaises': distribucionPaises,
        'caracteres': caracteres,
        'datosDasometricos': datosDasometricos?.toJson(),
        'ubicacion': ubicacion?.toJson(),
        'fotosCapturadas': fotosCapturadas.map((t) => t.value).toList(),
        'pasoActual': pasoActual,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'fechaActualizacion': fechaActualizacion.toIso8601String(),
      };

  /// Título con el que se muestra el borrador en la lista.
  String get titulo {
    if (nombreCientifico.trim().isNotEmpty) return nombreCientifico;
    if (nombreLocal.trim().isNotEmpty) return nombreLocal;
    return 'Registro sin nombre';
  }

  /// Convierte el borrador local en un objeto Especie (solo para visualización en UI).
  Especie toEspecie() {
    return Especie(
      id: id,
      catalogId: catalogId,
      nombreCientifico: nombreCientifico,
      autorNombre: autorNombre,
      familia: familia,
      nombreLocal: nombreLocal,
      habito: habito ?? Habito.arbol,
      tipoVida: tipoVida ?? TipoVida.terrestre,
      distribucionPaises: distribucionPaises,
      caracteres: caracteres,
      datosDasometricos: datosDasometricos,
      ubicacion: ubicacion ?? const Ubicacion(lat: 0.0, long: 0.0, referencia: '', altitud: 0.0, tipoHabitat: ''),
      fotos: fotosCapturadas.map((t) => Foto(id: id, tipo: t, url: '', autor: '', fecha: fechaCreacion)).toList(),
      estado: EstadoRegistro.borrador,
      codigoSeguimiento: 'Borrador',
      registradorId: '', 
      fechaEnvio: fechaCreacion,
      historialEstados: const [],
    );
  }
}

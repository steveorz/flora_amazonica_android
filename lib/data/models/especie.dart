import '../../core/constants/estado_registro.dart';
import '../../core/constants/habito.dart';
import '../../core/constants/tipo_vida.dart';
import 'datos_dasometricos.dart';
import 'foto.dart';
import 'ubicacion.dart';

class HistorialEstado {
  final String id;
  final EstadoRegistro estado;
  final DateTime fecha;
  final String usuarioId;
  final String? comentario;

  HistorialEstado({
    required this.id,
    required this.estado,
    required this.fecha,
    required this.usuarioId,
    this.comentario,
  });

  factory HistorialEstado.fromJson(Map<String, dynamic> json) {
    return HistorialEstado(
      id: json['id'],
      estado: EstadoRegistro.values.firstWhere((e) => e.value == json['estado'], orElse: () => EstadoRegistro.borrador),
      fecha: DateTime.parse(json['fecha']),
      usuarioId: json['usuarioId'],
      comentario: json['comentario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estado': estado.value,
      'fecha': fecha.toIso8601String(),
      'usuarioId': usuarioId,
      'comentario': comentario,
    };
  }
}

class Especie {
  final String id;
  final String? catalogId;
  final String nombreCientifico;
  final String autorNombre;
  final String familia;
  final String nombreLocal;
  final Habito habito;
  final TipoVida tipoVida;
  final List<String> distribucionPaises;
  final Map<String, String> caracteres;
  final DatosDasometricos? datosDasometricos;
  final Ubicacion ubicacion;
  final List<Foto> fotos;
  final EstadoRegistro estado;
  final String codigoSeguimiento;
  final String registradorId;
  final DateTime fechaEnvio;
  final List<HistorialEstado> historialEstados;

  Especie({
    required this.id,
    this.catalogId,
    required this.nombreCientifico,
    required this.autorNombre,
    required this.familia,
    required this.nombreLocal,
    required this.habito,
    required this.tipoVida,
    required this.distribucionPaises,
    required this.caracteres,
    this.datosDasometricos,
    required this.ubicacion,
    required this.fotos,
    required this.estado,
    required this.codigoSeguimiento,
    required this.registradorId,
    required this.fechaEnvio,
    required this.historialEstados,
  });

  /// Portada de la especie: la primera foto, como en iOS (`fotos.first?.url`).
  String? get portadaUrl => fotos.isNotEmpty ? fotos.first.url : null;

  Especie copyWith({
    String? catalogId,
    String? nombreCientifico,
    String? autorNombre,
    String? familia,
    String? nombreLocal,
    Habito? habito,
    TipoVida? tipoVida,
    List<String>? distribucionPaises,
    Map<String, String>? caracteres,
    DatosDasometricos? datosDasometricos,
    Ubicacion? ubicacion,
    List<Foto>? fotos,
    EstadoRegistro? estado,
    String? codigoSeguimiento,
    String? registradorId,
    DateTime? fechaEnvio,
    List<HistorialEstado>? historialEstados,
  }) {
    return Especie(
      id: id,
      catalogId: catalogId ?? this.catalogId,
      nombreCientifico: nombreCientifico ?? this.nombreCientifico,
      autorNombre: autorNombre ?? this.autorNombre,
      familia: familia ?? this.familia,
      nombreLocal: nombreLocal ?? this.nombreLocal,
      habito: habito ?? this.habito,
      tipoVida: tipoVida ?? this.tipoVida,
      distribucionPaises: distribucionPaises ?? this.distribucionPaises,
      caracteres: caracteres ?? this.caracteres,
      datosDasometricos: datosDasometricos ?? this.datosDasometricos,
      ubicacion: ubicacion ?? this.ubicacion,
      fotos: fotos ?? this.fotos,
      estado: estado ?? this.estado,
      codigoSeguimiento: codigoSeguimiento ?? this.codigoSeguimiento,
      registradorId: registradorId ?? this.registradorId,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
      historialEstados: historialEstados ?? this.historialEstados,
    );
  }

  factory Especie.fromJson(Map<String, dynamic> json) {
    return Especie(
      id: json['id'],
      catalogId: json['catalogId'],
      nombreCientifico: json['nombreCientifico'],
      autorNombre: json['autorNombre'],
      familia: json['familia'],
      nombreLocal: json['nombreLocal'],
      habito: Habito.values.firstWhere((e) => e.name == json['habito'], orElse: () => Habito.arbol),
      tipoVida: TipoVida.values.firstWhere((e) => e.name == json['tipoVida'], orElse: () => TipoVida.terrestre),
      distribucionPaises: List<String>.from(json['distribucionPaises'] ?? []),
      caracteres: Map<String, String>.from(json['caracteres'] ?? {}),
      datosDasometricos: json['datosDasometricos'] != null ? DatosDasometricos.fromJson(json['datosDasometricos']) : null,
      ubicacion: Ubicacion.fromJson(json['ubicacion']),
      fotos: (json['fotos'] as List? ?? []).map((f) => Foto.fromJson(f)).toList(),
      estado: EstadoRegistro.values.firstWhere((e) => e.value == json['estado'], orElse: () => EstadoRegistro.borrador),
      codigoSeguimiento: json['codigoSeguimiento'],
      registradorId: json['registradorId'],
      fechaEnvio: DateTime.parse(json['fechaEnvio']),
      historialEstados: (json['historialEstados'] as List? ?? []).map((h) => HistorialEstado.fromJson(h)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catalogId': catalogId,
      'nombreCientifico': nombreCientifico,
      'autorNombre': autorNombre,
      'familia': familia,
      'nombreLocal': nombreLocal,
      'habito': habito.name,
      'tipoVida': tipoVida.name,
      'distribucionPaises': distribucionPaises,
      'caracteres': caracteres,
      'datosDasometricos': datosDasometricos?.toJson(),
      'ubicacion': ubicacion.toJson(),
      'fotos': fotos.map((f) => f.toJson()).toList(),
      'estado': estado.value,
      'codigoSeguimiento': codigoSeguimiento,
      'registradorId': registradorId,
      'fechaEnvio': fechaEnvio.toIso8601String(),
      'historialEstados': historialEstados.map((h) => h.toJson()).toList(),
    };
  }

  /// Título inteligente para mostrar en la interfaz
  String get displayTitle {
    if (nombreCientifico.trim().isNotEmpty) return nombreCientifico;
    if (nombreLocal.trim().isNotEmpty) return nombreLocal;
    return 'Registro sin nombre';
  }
}

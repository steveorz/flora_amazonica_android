import 'dart:typed_data';

enum TipoFoto {
  plantaCompleta('planta_completa'),
  hoja('hoja'),
  flor('flor'),
  fruto('fruto'),
  talloCorteza('tallo_corteza');

  final String value;
  const TipoFoto(this.value);

  String get label {
    switch (this) {
      case TipoFoto.plantaCompleta: return "Planta completa";
      case TipoFoto.hoja: return "Hoja";
      case TipoFoto.flor: return "Flor";
      case TipoFoto.fruto: return "Fruto";
      case TipoFoto.talloCorteza: return "Tallo / corteza";
    }
  }
}

class Foto {
  final String id;
  final TipoFoto tipo;
  final String url;
  final String autor;
  final DateTime fecha;
  final Uint8List? localData;

  Foto({
    required this.id,
    required this.tipo,
    required this.url,
    required this.autor,
    required this.fecha,
    this.localData,
  });

  factory Foto.fromJson(Map<String, dynamic> json) {
    return Foto(
      id: json['id'],
      tipo: TipoFoto.values.firstWhere((e) => e.value == json['tipo'], orElse: () => TipoFoto.plantaCompleta),
      url: json['url'],
      autor: json['autor'],
      fecha: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo.value,
      'url': url,
      'autor': autor,
      'fecha': fecha.toIso8601String(),
    };
  }
}

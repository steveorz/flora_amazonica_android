class Ubicacion {
  final double lat;
  final double long;
  final String referencia;
  final double altitud; // Metros sobre el nivel del mar
  final String tipoHabitat;

  const Ubicacion({
    required this.lat,
    required this.long,
    required this.referencia,
    required this.altitud,
    required this.tipoHabitat,
  });

  Ubicacion copyWith({
    double? lat,
    double? long,
    String? referencia,
    double? altitud,
    String? tipoHabitat,
  }) {
    return Ubicacion(
      lat: lat ?? this.lat,
      long: long ?? this.long,
      referencia: referencia ?? this.referencia,
      altitud: altitud ?? this.altitud,
      tipoHabitat: tipoHabitat ?? this.tipoHabitat,
    );
  }

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      lat: (json['lat'] as num).toDouble(),
      long: (json['long'] as num).toDouble(),
      referencia: json['referencia'],
      altitud: (json['altitud'] as num).toDouble(),
      tipoHabitat: json['tipoHabitat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'long': long,
      'referencia': referencia,
      'altitud': altitud,
      'tipoHabitat': tipoHabitat,
    };
  }
}

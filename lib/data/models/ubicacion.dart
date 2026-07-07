class Ubicacion {
  final double lat;
  final double long;
  final String referencia;
  final double altitud; // Metros sobre el nivel del mar
  final String tipoHabitat;

  Ubicacion({
    required this.lat,
    required this.long,
    required this.referencia,
    required this.altitud,
    required this.tipoHabitat,
  });

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

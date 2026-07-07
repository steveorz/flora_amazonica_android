import 'dart:math';

class DatosDasometricos {
  final double altura;
  final double cap;
  final double diamCopaParalelo;
  final double diamCopaPerpendicular;
  final double alturaInicioCopa;

  DatosDasometricos({
    required this.altura,
    required this.cap,
    required this.diamCopaParalelo,
    required this.diamCopaPerpendicular,
    required this.alturaInicioCopa,
  });

  double get dap => cap / pi;

  factory DatosDasometricos.fromJson(Map<String, dynamic> json) {
    return DatosDasometricos(
      altura: (json['altura'] as num).toDouble(),
      cap: (json['cap'] as num).toDouble(),
      diamCopaParalelo: (json['diamCopaParalelo'] as num).toDouble(),
      diamCopaPerpendicular: (json['diamCopaPerpendicular'] as num).toDouble(),
      alturaInicioCopa: (json['alturaInicioCopa'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'altura': altura,
      'cap': cap,
      'diamCopaParalelo': diamCopaParalelo,
      'diamCopaPerpendicular': diamCopaPerpendicular,
      'alturaInicioCopa': alturaInicioCopa,
    };
  }
}

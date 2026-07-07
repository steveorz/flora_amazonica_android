class OpcionMorfologica {
  final String id;
  final String valor;
  final int orden;

  OpcionMorfologica({
    required this.id,
    required this.valor,
    required this.orden,
  });

  factory OpcionMorfologica.fromJson(Map<String, dynamic> json) {
    return OpcionMorfologica(
      id: json['id'],
      valor: json['valor'],
      orden: json['orden'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valor': valor,
      'orden': orden,
    };
  }
}

class CampoMorfologico {
  final String seccion;
  final String nombre;
  final String tipoSeleccion; // "single" | "multiple"
  final String tipoCampo; // "option" | "number" | "text"
  final bool requerido;
  final int orden;
  List<OpcionMorfologica> opciones;

  CampoMorfologico({
    required this.seccion,
    required this.nombre,
    required this.tipoSeleccion,
    required this.tipoCampo,
    required this.requerido,
    required this.orden,
    required this.opciones,
  });

  String get id => "$seccion-$nombre";

  factory CampoMorfologico.fromJson(Map<String, dynamic> json) {
    return CampoMorfologico(
      seccion: json['seccion'],
      nombre: json['nombre'],
      tipoSeleccion: json['tipoSeleccion'],
      tipoCampo: json['tipoCampo'],
      requerido: json['requerido'],
      orden: json['orden'],
      opciones: (json['opciones'] as List).map((o) => OpcionMorfologica.fromJson(o)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seccion': seccion,
      'nombre': nombre,
      'tipoSeleccion': tipoSeleccion,
      'tipoCampo': tipoCampo,
      'requerido': requerido,
      'orden': orden,
      'opciones': opciones.map((o) => o.toJson()).toList(),
    };
  }
}

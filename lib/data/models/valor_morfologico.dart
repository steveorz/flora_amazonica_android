class ValorMorfologico {
  final String categoria;
  final String nombre;
  final String codigo;
  final int orden;
  final bool activo;

  ValorMorfologico({
    required this.categoria,
    required this.nombre,
    required this.codigo,
    required this.orden,
    required this.activo,
  });

  String get id => codigo;

  ValorMorfologico copyWith({String? categoria, String? nombre, int? orden, bool? activo}) {
    return ValorMorfologico(
      categoria: categoria ?? this.categoria,
      nombre: nombre ?? this.nombre,
      codigo: codigo,
      orden: orden ?? this.orden,
      activo: activo ?? this.activo,
    );
  }

  factory ValorMorfologico.fromJson(Map<String, dynamic> json) {
    return ValorMorfologico(
      categoria: json['categoria'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      orden: json['orden'],
      activo: json['activo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoria': categoria,
      'nombre': nombre,
      'codigo': codigo,
      'orden': orden,
      'activo': activo,
    };
  }
}

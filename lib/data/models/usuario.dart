enum EstadoUsuario {
  activo,
  inactivo,
  pendiente
}

class Usuario {
  final String id;
  final String nombres;
  final String apellidos;
  final String dni;
  final String email;
  final String institucion;
  final String cargo;
  final String rol; // Podríamos usar el enum Rol, pero como lo parseamos de JSON usaremos String por ahora o importaremos Rol
  final EstadoUsuario estado;
  final DateTime fechaRegistro;
  final String? avatarUrl;

  Usuario({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.dni,
    required this.email,
    required this.institucion,
    required this.cargo,
    required this.rol,
    required this.estado,
    required this.fechaRegistro,
    this.avatarUrl,
  });

  String get nombreCompleto => "$nombres $apellidos";

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombres: json['nombres'],
      apellidos: json['apellidos'],
      dni: json['dni'],
      email: json['email'],
      institucion: json['institucion'],
      cargo: json['cargo'],
      rol: json['rol'],
      estado: EstadoUsuario.values.firstWhere((e) => e.name == json['estado'], orElse: () => EstadoUsuario.pendiente),
      fechaRegistro: DateTime.parse(json['fechaRegistro']),
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'dni': dni,
      'email': email,
      'institucion': institucion,
      'cargo': cargo,
      'rol': rol,
      'estado': estado.name,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'avatarUrl': avatarUrl,
    };
  }
}

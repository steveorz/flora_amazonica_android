class Usuario {
  final String id;
  final String email;
  final String nombre;
  final RolUsuario rol;
  final EstadoUsuario estado; // PENDIENTE, ACTIVO, INACTIVO

  Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.estado,
  });

  // Métodos fromJson / toJson omitidos por brevedad
}

enum RolUsuario { registrador, consultor, administrador }
enum EstadoUsuario { pendiente, activo, inactivo }

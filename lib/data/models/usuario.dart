import '../../core/constants/rol.dart';
import '../../core/network/api_client.dart';

enum EstadoUsuario {
  activo,
  inactivo,
  pendiente;

  static EstadoUsuario fromRaw(String? raw) => EstadoUsuario.values.firstWhere(
        (e) => e.name == raw?.toLowerCase(),
        orElse: () => EstadoUsuario.pendiente,
      );
}

class Usuario {
  final String id;
  final String nombres;
  final String apellidos;
  final String dni;
  final String email;
  final String institucion;
  final String cargo;
  final Rol rol;
  final EstadoUsuario estado;
  final DateTime fechaRegistro;
  final String? avatarUrl;

  const Usuario({
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

  String get nombreCompleto => '$nombres $apellidos';

  /// Iniciales para el avatar cuando no hay foto (ej. "MG").
  String get iniciales {
    final n = nombres.trim().isNotEmpty ? nombres.trim()[0] : '';
    final a = apellidos.trim().isNotEmpty ? apellidos.trim()[0] : '';
    final ini = '$n$a'.toUpperCase();
    return ini.isEmpty ? '?' : ini;
  }

  Usuario copyWith({
    String? nombres,
    String? apellidos,
    String? dni,
    String? institucion,
    String? cargo,
    Rol? rol,
    EstadoUsuario? estado,
    String? avatarUrl,
  }) {
    return Usuario(
      id: id,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      dni: dni ?? this.dni,
      email: email,
      institucion: institucion ?? this.institucion,
      cargo: cargo ?? this.cargo,
      rol: rol ?? this.rol,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  /// Mapea el `UserDTO` que devuelve NestJS (snake_case), igual que
  /// `UserDTO.toUsuario()` en iOS: los apellidos se concatenan y los campos
  /// opcionales caen a cadena vacía.
  factory Usuario.fromDto(Map<String, dynamic> json) {
    final paterno = (json['paternal_last_name'] as String?) ?? '';
    final materno = json['maternal_last_name'] as String?;
    final apellidos =
        (materno != null && materno.isNotEmpty) ? '$paterno $materno' : paterno;

    return Usuario(
      id: json['id'] as String,
      nombres: (json['first_name'] as String?) ?? '',
      apellidos: apellidos,
      dni: (json['dni'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      institucion: (json['institution'] as String?) ?? '',
      cargo: (json['position'] as String?) ?? '',
      rol: Rol.fromRaw(json['role'] as String?),
      estado: EstadoUsuario.fromRaw(json['status'] as String?),
      fechaRegistro: parseApiDate(json['created_at']),
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

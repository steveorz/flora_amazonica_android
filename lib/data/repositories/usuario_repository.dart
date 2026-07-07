import '../../models/usuario.dart';
import '../../models/rol.dart'; // assuming these exist, actually rol is in constants, let's use String or EstadoUsuario properly.
import '../../../core/constants/estado_registro.dart'; // and EstadoUsuario
import '../../../core/constants/rol.dart';
import '../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class UsuarioRepository {
  Future<List<Usuario>> listar();
  Future<Usuario> get(String id);
  Future<void> actualizarEstado(String id, EstadoUsuario nuevo);
  Future<void> actualizarRol(String id, Rol nuevo);
}

class RealUsuarioRepository implements UsuarioRepository {
  final APIClient apiClient = APIClient.shared;

  @override
  Future<List<Usuario>> listar() async {
    final List<dynamic> records = await apiClient.request(endpoint: "/usuarios");
    return records.map((r) => Usuario.fromJson(r)).toList();
  }

  @override
  Future<Usuario> get(String id) async {
    final record = await apiClient.request(endpoint: "/usuarios/$id");
    return Usuario.fromJson(record);
  }

  @override
  Future<void> actualizarEstado(String id, EstadoUsuario nuevo) async {
    final body = {"status": nuevo.name};
    await apiClient.request(endpoint: "/usuarios/$id/estado", method: "PATCH", body: body);
  }

  @override
  Future<void> actualizarRol(String id, Rol nuevo) async {
    final body = {"role": nuevo.name};
    await apiClient.request(endpoint: "/usuarios/$id/rol", method: "PATCH", body: body);
  }
}

final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  return RealUsuarioRepository();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/rol.dart';
import '../../core/network/api_client.dart';
import '../models/usuario.dart';

abstract class UsuarioRepository {
  Future<List<Usuario>> listar();
  Future<Usuario> get(String id);
  Future<void> actualizarEstado(String id, EstadoUsuario nuevo);
  Future<void> actualizarRol(String id, Rol nuevo);
  Future<void> actualizarDeviceToken(String token);
}

class RealUsuarioRepository implements UsuarioRepository {
  @override
  Future<List<Usuario>> listar() async {
    final json = await apiClient.get('/usuarios');
    if (json is! List) return const [];
    return json.map((e) => Usuario.fromDto(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Usuario> get(String id) async {
    final json = await apiClient.get('/usuarios/$id');
    return Usuario.fromDto(json as Map<String, dynamic>);
  }

  @override
  Future<void> actualizarEstado(String id, EstadoUsuario nuevo) async {
    await apiClient.patch('/usuarios/$id/estado', body: {'status': nuevo.name});
  }

  @override
  Future<void> actualizarRol(String id, Rol nuevo) async {
    await apiClient.patch('/usuarios/$id/rol', body: {'role': nuevo.name});
  }

  @override
  Future<void> actualizarDeviceToken(String token) async {
    await apiClient.post('/usuarios/device-token', body: {'device_token': token});
  }
}

final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) => RealUsuarioRepository());

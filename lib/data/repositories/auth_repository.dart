import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/rol.dart';
import '../../core/network/api_client.dart';
import '../models/usuario.dart';

/// Espejo de `AuthError` (iOS). `cuentaPendiente` no es un fallo de login:
/// lleva el usuario para que la app pueda mostrar la pantalla C-08.
class AuthError implements Exception {
  final String message;
  final bool isPending;
  final Usuario? pendingUser;

  const AuthError(this.message, {this.isPending = false, this.pendingUser});

  static const credencialesInvalidas = AuthError('Email o contraseña incorrectos.');
  static const emailNoEncontrado = AuthError('No encontramos una cuenta con ese email.');
  static const emailYaRegistrado = AuthError('Este email ya está registrado.');
  static const sesionInvalida = AuthError('La sesión expiró. Vuelve a iniciar sesión.');
  static const generico = AuthError('Algo salió mal. Inténtalo de nuevo.');

  @override
  String toString() => message;
}

class RegistroForm {
  String nombres = '';
  String apellidos = '';
  String email = '';
  String password = '';
}

abstract class AuthRepository {
  Future<bool> emailExists(String email);
  Future<(String token, Usuario usuario)> login({required String email, required String password});
  Future<Usuario> validate({String? token});
  Future<Usuario> register(RegistroForm form);
  Future<void> requestPasswordReset(String email);
  Future<void> resetPassword({required String email, required String nueva});
  Future<void> changePassword({
    required String email,
    required String actual,
    required String nueva,
  });
}

class RealAuthRepository implements AuthRepository {
  @override
  Future<bool> emailExists(String email) async {
    try {
      final response = await apiClient.post('/auth/check-email', body: {'email': email});
      return (response is Map && response['exists'] == true);
    } catch (_) {
      // Igual que iOS: ante un fallo de red asumimos que no existe, para no
      // bloquear al usuario que intenta crear su cuenta.
      return false;
    }
  }

  @override
  Future<(String token, Usuario usuario)> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        '/auth/login',
        body: {'email': email, 'password': password},
      );
      final token = response['access_token'] as String;
      final usuario = Usuario.fromDto(response['user'] as Map<String, dynamic>);
      return (token, usuario);
    } on ApiRequestFailed catch (e) {
      // 403 = cuenta creada pero aún no activada por un administrador.
      // El backend no devuelve el usuario en ese caso, así que construimos
      // uno mínimo con el email tecleado (idéntico al `dummyUser` de iOS).
      if (e.statusCode == 403) {
        throw AuthError(
          'Tu cuenta aún está pendiente de activación.',
          isPending: true,
          pendingUser: Usuario(
            id: '',
            nombres: 'Usuario',
            apellidos: '',
            dni: '',
            email: email,
            institucion: '',
            cargo: '',
            rol: Rol.consultor,
            estado: EstadoUsuario.pendiente,
            fechaRegistro: DateTime.now(),
          ),
        );
      }
      if (e.statusCode == 401 || e.statusCode == 404) {
        throw AuthError.credencialesInvalidas;
      }
      throw AuthError.credencialesInvalidas;
    } on AuthError {
      rethrow;
    } catch (_) {
      throw AuthError.credencialesInvalidas;
    }
  }

  @override
  Future<Usuario> validate({String? token}) async {
    try {
      // Timeout corto (3s como en iOS): restaurar sesión no debe retrasar el
      // arranque; si el backend tarda, preferimos mandar al login.
      final json = await apiClient.get(
        '/auth/profile',
        token: token,
        timeout: const Duration(seconds: 3),
      );
      return Usuario.fromDto(json as Map<String, dynamic>);
    } catch (_) {
      throw AuthError.sesionInvalida;
    }
  }

  @override
  Future<Usuario> register(RegistroForm form) async {
    // El backend separa apellido paterno y materno; la UI pide "apellidos".
    final partes = form.apellidos.trim().split(RegExp(r'\s+'));
    final paterno = partes.isNotEmpty ? partes.first : form.apellidos;
    final materno = partes.length > 1 ? partes.skip(1).join(' ') : '';

    try {
      final json = await apiClient.post('/auth/register', body: {
        'first_name': form.nombres,
        'paternal_last_name': paterno,
        'maternal_last_name': materno,
        'email': form.email,
        'password': form.password,
      });
      return Usuario.fromDto(json as Map<String, dynamic>);
    } on ApiRequestFailed catch (e) {
      if (e.statusCode == 409) throw AuthError.emailYaRegistrado;
      // Mostramos el mensaje del backend si lo hay (p. ej. errores de validación).
      throw AuthError(e.serverMessage ?? AuthError.generico.message);
    } catch (_) {
      throw AuthError.generico;
    }
  }

  // NOTA: en iOS estos tres métodos están vacíos (`// ...`). Los dejamos
  // implementados contra los endpoints esperados pero tolerando 404, para que
  // la UI de recuperación funcione en cuanto el backend los exponga.
  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await apiClient.post('/auth/forgot-password', body: {'email': email});
    } on ApiRequestFailed catch (e) {
      if (e.statusCode == 404) throw AuthError.emailNoEncontrado;
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({required String email, required String nueva}) async {
    await apiClient.post('/auth/reset-password', body: {
      'email': email,
      'new_password': nueva,
    });
  }

  @override
  Future<void> changePassword({
    required String email,
    required String actual,
    required String nueva,
  }) async {
    try {
      await apiClient.patch('/auth/change-password', body: {
        'email': email,
        'current_password': actual,
        'new_password': nueva,
      });
    } on ApiRequestFailed catch (e) {
      if (e.statusCode == 401) {
        throw const AuthError('La contraseña actual no es correcta.');
      }
      throw AuthError(e.serverMessage ?? AuthError.generico.message);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => RealAuthRepository());

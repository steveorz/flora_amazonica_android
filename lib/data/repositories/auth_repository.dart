import '../../models/usuario.dart';
import '../../models/especie.dart'; // For dummy dependency or future use
import '../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthError implements Exception {
  final String message;
  final bool isPending;
  final Usuario? pendingUser;

  AuthError(this.message, {this.isPending = false, this.pendingUser});

  @override
  String toString() => message;
}

class RegistroForm {
  String nombres = "";
  String apellidos = "";
  String email = "";
  String password = "";
}

abstract class AuthRepository {
  Future<bool> emailExists(String email);
  Future<(String token, Usuario usuario)> login({required String email, required String password});
  Future<Usuario> validate();
  Future<Usuario> register(RegistroForm form);
  Future<void> requestPasswordReset(String email);
  Future<void> resetPassword({required String email, required String nueva});
  Future<void> changePassword({required String email, required String actual, required String nueva});
}

class RealAuthRepository implements AuthRepository {
  
  @override
  Future<bool> emailExists(String email) async {
    try {
      final response = await apiClient.post(
        "/auth/check-email",
        body: {"email": email},
      );
      return response['exists'] ?? false;
    } catch (e) {
      return false; 
    }
  }

  @override
  Future<(String token, Usuario usuario)> login({required String email, required String password}) async {
    try {
      final response = await apiClient.post(
        "/auth/login",
        body: {"email": email, "password": password},
      );
      final token = response['access_token'];
      final userJson = response['user'];
      
      final apellidos = userJson['maternal_last_name'] != null 
          ? "${userJson['paternal_last_name']} ${userJson['maternal_last_name']}"
          : userJson['paternal_last_name'];
      
      final usuario = Usuario(
        id: userJson['id'],
        nombres: userJson['first_name'],
        apellidos: apellidos,
        dni: userJson['dni'] ?? "",
        email: userJson['email'],
        institucion: userJson['institution'] ?? "",
        cargo: userJson['position'] ?? "",
        rol: userJson['role'],
        estado: EstadoUsuario.values.firstWhere((e) => e.name == userJson['status'], orElse: () => EstadoUsuario.pendiente),
        fechaRegistro: DateTime.parse(userJson['created_at']),
        avatarUrl: userJson['avatar_url'],
      );

      return (token, usuario);
    } catch (e) {
      if (e is ApiException) {
        if (e.statusCode == 403) {
          final dummyUser = Usuario(
            id: "", nombres: "Usuario", apellidos: "", dni: "", email: email, 
            institucion: "", cargo: "", rol: "consultor", estado: EstadoUsuario.pendiente, 
            fechaRegistro: DateTime.now(), avatarUrl: null
          );
          throw AuthError("Tu cuenta aún está pendiente de activación.", isPending: true, pendingUser: dummyUser);
        }
        if (e.statusCode == 401 || e.statusCode == 404) {
          throw AuthError("Email o contraseña incorrectos.");
        }
      }
      throw AuthError("Algo salió mal. Inténtalo de nuevo.");
    }
  }

  @override
  Future<Usuario> validate() async {
    try {
      final userJson = await apiClient.get("/auth/profile");
      final apellidos = userJson['maternal_last_name'] != null 
          ? "${userJson['paternal_last_name']} ${userJson['maternal_last_name']}"
          : userJson['paternal_last_name'];
          
      return Usuario(
        id: userJson['id'],
        nombres: userJson['first_name'],
        apellidos: apellidos,
        dni: userJson['dni'] ?? "",
        email: userJson['email'],
        institucion: userJson['institution'] ?? "",
        cargo: userJson['position'] ?? "",
        rol: userJson['role'],
        estado: EstadoUsuario.values.firstWhere((e) => e.name == userJson['status'], orElse: () => EstadoUsuario.pendiente),
        fechaRegistro: DateTime.parse(userJson['created_at']),
        avatarUrl: userJson['avatar_url'],
      );
    } catch (e) {
      throw AuthError("La sesión expiró. Vuelve a iniciar sesión.");
    }
  }

  @override
  Future<Usuario> register(RegistroForm form) async {
    final apellidosArr = form.apellidos.split(" ");
    final pat = apellidosArr.isNotEmpty ? apellidosArr.first : form.apellidos;
    final mat = apellidosArr.length > 1 ? apellidosArr.skip(1).join(" ") : null;

    final body = {
      "first_name": form.nombres,
      "paternal_last_name": pat,
      "maternal_last_name": mat,
      "email": form.email,
      "password": form.password
    };

    try {
      final userJson = await apiClient.post("/auth/register", body: body);
      final apellidos = userJson['maternal_last_name'] != null 
          ? "${userJson['paternal_last_name']} ${userJson['maternal_last_name']}"
          : userJson['paternal_last_name'];
          
      return Usuario(
        id: userJson['id'],
        nombres: userJson['first_name'],
        apellidos: apellidos,
        dni: userJson['dni'] ?? "",
        email: userJson['email'],
        institucion: userJson['institution'] ?? "",
        cargo: userJson['position'] ?? "",
        rol: userJson['role'],
        estado: EstadoUsuario.values.firstWhere((e) => e.name == userJson['status'], orElse: () => EstadoUsuario.pendiente),
        fechaRegistro: DateTime.parse(userJson['created_at']),
        avatarUrl: userJson['avatar_url'],
      );
    } catch (e) {
      throw AuthError("Algo salió mal al registrar. Inténtalo de nuevo.");
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> resetPassword({required String email, required String nueva}) async {}

  @override
  Future<void> changePassword({required String email, required String actual, required String nueva}) async {}
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RealAuthRepository();
});

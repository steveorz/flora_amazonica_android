// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/usuario.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/usuario_repository.dart';
import '../constants/rol.dart';
import '../storage/secure_storage.dart';

/// Espejo de `SessionStore` (iOS). Sobrevive a recargas mientras haya un token
/// válido en el almacenamiento seguro.
class SessionState {
  final Usuario? usuario;
  final String? token;

  /// True mientras se intenta restaurar la sesión al arrancar. El router debe
  /// esperar a que termine, o mandaría al login a un usuario ya autenticado.
  final bool restaurando;

  const SessionState({this.usuario, this.token, this.restaurando = true});

  bool get isAutenticado => usuario != null && usuario!.estado == EstadoUsuario.activo;
  bool get isPendiente => usuario?.estado == EstadoUsuario.pendiente;
  Rol? get rol => usuario?.rol;
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._authRepo, this._usuarioRepo) : super(const SessionState()) {
    restoreSession();
  }

  final AuthRepository _authRepo;
  final UsuarioRepository _usuarioRepo;

  Future<void> _syncDeviceToken() async {
    try {
      // final token = await FirebaseMessaging.instance.getToken();
      final token = 'dummy_token_no_firebase';
      if (token != null) {
        await _usuarioRepo.actualizarDeviceToken(token);
      }
    } catch (e) {
      // Ignoramos errores de token silenciosamente
    }
  }

  /// Intenta restaurar la sesión desde el token guardado.
  /// Si el token ya no vale, lo borra y deja al usuario en el login.
  Future<void> restoreSession() async {
    final savedToken = await secureStorage.getToken();
    if (savedToken == null) {
      state = const SessionState(restaurando: false);
      return;
    }
    try {
      final usuario = await _authRepo.validate(token: savedToken);
      state = SessionState(token: savedToken, usuario: usuario, restaurando: false);
      _syncDeviceToken();
    } catch (_) {
      await secureStorage.deleteToken();
      state = const SessionState(restaurando: false);
    }
  }

  Future<bool> emailExists(String email) => _authRepo.emailExists(email);

  /// Devuelve `null` en éxito, o el mensaje de error a mostrar.
  ///
  /// Si la cuenta está pendiente NO es un error: se guarda el usuario sin token
  /// para que el router muestre la pantalla de cuenta inactiva (C-08).
  Future<String?> login(String email, String password) async {
    try {
      final (token, usuario) = await _authRepo.login(email: email, password: password);
      await secureStorage.saveToken(token);
      state = SessionState(token: token, usuario: usuario, restaurando: false);
      _syncDeviceToken();
      return null;
    } on AuthError catch (e) {
      if (e.isPending && e.pendingUser != null) {
        state = SessionState(usuario: e.pendingUser, restaurando: false);
        return null;
      }
      return e.message;
    } catch (_) {
      return AuthError.generico.message;
    }
  }

  Future<void> logout() async {
    await secureStorage.deleteToken();
    state = const SessionState(restaurando: false);
  }

  Future<Usuario> register(RegistroForm form) => _authRepo.register(form);

  Future<void> requestPasswordReset(String email) => _authRepo.requestPasswordReset(email);

  Future<void> resetPassword(String email, String nueva) =>
      _authRepo.resetPassword(email: email, nueva: nueva);

  /// Cambia la contraseña del usuario en sesión.
  Future<void> changePassword(String actual, String nueva) async {
    final email = state.usuario?.email;
    if (email == null) throw AuthError.sesionInvalida;
    await _authRepo.changePassword(email: email, actual: actual, nueva: nueva);
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(ref.watch(authRepositoryProvider), ref.watch(usuarioRepositoryProvider)),
);

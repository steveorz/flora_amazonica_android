import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/usuario.dart';
import '../../data/repositories/auth_repository.dart';
import '../storage/secure_storage.dart';

class SessionState {
  final Usuario? usuario;
  final String? token;

  SessionState({this.usuario, this.token});

  bool get isAutenticado => usuario != null && usuario?.estado == EstadoUsuario.activo;
  bool get isPendiente => usuario?.estado == EstadoUsuario.pendiente;
  String? get rol => usuario?.rol.toString().split('.').last;

  SessionState copyWith({Usuario? usuario, String? token, bool clearToken = false}) {
    return SessionState(
      usuario: usuario ?? this.usuario,
      token: clearToken ? null : (token ?? this.token),
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final AuthRepository _repo;

  SessionNotifier(this._repo) : super(SessionState()) {
    restoreSession();
  }

  Future<void> restoreSession() async {
    final savedToken = await secureStorage.getToken();
    if (savedToken == null) return;
    try {
      final u = await _repo.validate();
      state = SessionState(token: savedToken, usuario: u);
    } catch (e) {
      await secureStorage.deleteToken();
    }
  }

  Future<bool> emailExists(String email) async {
    return await _repo.emailExists(email);
  }

  Future<String?> login(String email, String password) async {
    try {
      final (t, u) = await _repo.login(email: email, password: password);
      await secureStorage.saveToken(t);
      state = SessionState(token: t, usuario: u);
      return null;
    } on AuthError catch (e) {
      if (e.isPending) {
        state = SessionState(usuario: e.pendingUser);
        return null;
      }
      return e.message;
    } catch (e) {
      return "Error genérico";
    }
  }

  void logout() async {
    await secureStorage.deleteToken();
    state = SessionState(usuario: null, token: null);
  }

  Future<Usuario> register(RegistroForm form) async {
    return await _repo.register(form);
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return SessionNotifier(authRepo);
});

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/rol.dart';
import 'core/session/session_provider.dart';
import 'features/auth/account_created_screen.dart';
import 'features/auth/inactive_account_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/new_password_screen.dart';
import 'features/auth/recover_password_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/root_gate.dart';
import 'features/auth/validador_web_screen.dart';

/// Rutas del flujo de autenticación: las únicas accesibles sin sesión.
const _rutasAuth = {
  '/login',
  '/register',
  '/account-created',
  '/recover',
  '/new-password',
};

/// Espejo de la lógica de `RootView` (iOS), expresada como redirects.
final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _SessionListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final path = state.uri.path;

      // Mientras se valida el token guardado, bloqueamos la navegación en '/' temporalmente.
      if (session.restaurando) return '/';

      if (path != '/') {
        FlutterNativeSplash.remove();
      }

      if (session.usuario == null) {
        return _rutasAuth.contains(path) ? null : '/login';
      }

      // Cuenta creada pero aún no activada por un administrador (C-08).
      if (session.isPendiente) return path == '/inactive' ? null : '/inactive';

      // El validador no tiene app nativa: trabaja sobre el frontend web.
      if (session.rol == Rol.validador) {
        return path == '/validador' ? null : '/validador';
      }

      // Sesión válida: fuera de las pantallas de auth o inactivo.
      if (_rutasAuth.contains(path) || path == '/inactive') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (_, state) => RegisterScreen(initialEmail: state.extra as String? ?? ''),
      ),
      GoRoute(path: '/account-created', builder: (_, __) => const AccountCreatedScreen()),
      GoRoute(path: '/recover', builder: (_, __) => const RecoverPasswordScreen()),
      GoRoute(
        path: '/new-password',
        builder: (_, state) => NewPasswordScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/inactive',
        builder: (_, __) {
          final usuario = ref.read(sessionProvider).usuario;
          // El redirect garantiza que hay usuario; el fallback es defensivo.
          if (usuario == null) return const LoginScreen();
          return InactiveAccountScreen(usuario: usuario);
        },
      ),
      GoRoute(
        path: '/validador',
        builder: (_, __) {
          final usuario = ref.read(sessionProvider).usuario;
          if (usuario == null) return const LoginScreen();
          return ValidadorWebScreen(
            usuario: usuario,
            onBack: () => ref.read(sessionProvider.notifier).logout(),
          );
        },
      ),
      GoRoute(path: '/', builder: (_, __) => const RootGate()),
    ],
  );
});

/// Reevalúa los redirects cada vez que cambia la sesión.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    _remove = ref.listen(sessionProvider, (_, __) => notifyListeners()).close;
  }

  late final void Function() _remove;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }
}

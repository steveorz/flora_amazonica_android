import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/session/session_provider.dart';
import 'data/models/usuario.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/inactive_account_screen.dart';
import 'presentation/screens/main_layout_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionState = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _SessionListenable(ref), // Triggers redirect when session changes
    redirect: (context, state) {
      final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register';
      
      // If user is null (not logged in)
      if (sessionState == null) {
        if (!isAuthRoute) {
          return '/login';
        }
        return null;
      }

      // If user is logged in
      if (isAuthRoute) {
        return '/';
      }

      // Route based on state
      if (sessionState.estado == UsuarioEstado.pendiente) {
        if (state.uri.path != '/inactive') {
          return '/inactive';
        }
        return null;
      }

      if (state.uri.path == '/inactive' && sessionState.estado == UsuarioEstado.activo) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return RegisterScreen(initialEmail: email);
        },
      ),
      GoRoute(
        path: '/inactive',
        builder: (context, state) {
          final user = ref.read(sessionProvider);
          if (user == null) return const LoginScreen(); // Should not happen due to redirect
          return InactiveAccountScreen(usuario: user);
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainLayoutScreen(),
      ),
    ],
  );
});

class _SessionListenable extends ChangeNotifier {
  _SessionListenable(ProviderRef ref) {
    ref.listen(sessionProvider, (_, __) {
      notifyListeners();
    });
  }
}

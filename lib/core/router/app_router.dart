import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/main_mobile_layout.dart';
import '../../features/register/presentation/screens/registro_wizard_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/registro',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainMobileLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/registro',
          builder: (context, state) => const RegistroWizardScreen(),
        ),
        GoRoute(
          path: '/catalogo',
          builder: (context, state) => const Scaffold(body: Center(child: Text('Catálogo'))),
        ),
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const Scaffold(body: Center(child: Text('Perfil'))),
        ),
      ],
    ),
  ],
);

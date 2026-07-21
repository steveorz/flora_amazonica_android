import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notificacion_service.dart';
import '../../core/widgets/avisos_destination.dart';
import '../registrador/notificaciones_screen.dart';
import '../shared/profile_screen.dart';
import 'dashboard_admin_screen.dart';
import 'usuarios_screen.dart';

/// Espejo de `AdminShell` (iOS).
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  AdminShellState createState() => AdminShellState();

  static AdminShellState of(BuildContext context) {
    return context.findAncestorStateOfType<AdminShellState>()!;
  }
}

class AdminShellState extends ConsumerState<AdminShell> {
  static const _indiceUsuarios = 1;

  int _indice = 0;
  bool showFab = true;

  bool _handleScrollNotification(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      if (!showFab) setState(() => showFab = true);
    } else if (notification.direction == ScrollDirection.reverse) {
      if (showFab) setState(() => showFab = false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final noLeidas = ref.watch(notificacionServiceProvider).noLeidas;

    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          children: [
            IndexedStack(
              index: _indice,
              children: [
                // La alerta de cuentas pendientes salta a la pestaña Usuarios.
                DashboardAdminScreen(
                  onIrAUsuarios: (r) {
                    if (r != null) {
                      ref.read(filtroRolesAdminProvider.notifier).state = {r};
                    } else {
                      ref.read(filtroRolesAdminProvider.notifier).state = {};
                    }
                    setState(() => _indice = _indiceUsuarios);
                  },
                ),
                UsuariosScreen(),
                const NotificacionesScreen(),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0, right: 14.0),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 250),
                    offset: showFab ? Offset.zero : const Offset(0, -2),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: showFab ? 1.0 : 0.0,
                      child: const ProfileToolbarButton(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          avisosDestination(noLeidas),
        ],
      ),
    );
  }
}

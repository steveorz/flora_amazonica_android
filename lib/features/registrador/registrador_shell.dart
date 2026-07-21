import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/estado_registro.dart';
import '../../core/services/notificacion_service.dart';
import '../../core/widgets/avisos_destination.dart';
import 'home_screen.dart';
import 'mis_registros_screen.dart';
import 'notificaciones_screen.dart';
import '../shared/profile_screen.dart';
import 'wizard/nuevo_registro_screen.dart';

/// Espejo de `RegistradorShell` (iOS). La pestaña central "Nuevo" no navega:
/// presenta el wizard a pantalla completa y deja la selección donde estaba.
class RegistradorShell extends ConsumerStatefulWidget {
  const RegistradorShell({super.key});

  @override
  ConsumerState<RegistradorShell> createState() => RegistradorShellState();

  static RegistradorShellState of(BuildContext context) {
    return context.findAncestorStateOfType<RegistradorShellState>()!;
  }
}

class RegistradorShellState extends ConsumerState<RegistradorShell> {
  int _indice = 0;
  bool showFab = true;
  EstadoRegistro? _filtroPendiente;

  void cambiarTab(int indice, {EstadoRegistro? filtro}) {
    setState(() {
      _filtroPendiente = filtro;
      _indice = indice;
    });
  }

  void _abrirWizard() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => const NuevoRegistroScreen(),
        fullscreenDialog: true,
      ),
    );
  }

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
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          children: [
            IndexedStack(
              index: _indice,
              children: [
                const HomeScreen(),
                MisRegistrosScreen(filtroInicial: _filtroPendiente),
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
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        offset: showFab ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: showFab ? 1.0 : 0.0,
          child: FloatingActionButton.extended(
        onPressed: _abrirWizard,
        backgroundColor: oscuro
            ? const Color(0xFF203B2E) // Verde bosque profundo en modo oscuro
            : const Color(0xFFE2EFE7), // Verde pastel claro en modo claro
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        icon: Icon(
          Icons.add_circle_outline, // Ícono de agregar contorneado
          color: oscuro ? const Color(0xFF81C784) : AppColors.primary,
          size: 22,
        ),
        label: Text(
          "Registrar",
          style: TextStyle(
            color: oscuro ? const Color(0xFF81C784) : AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (idx) => cambiarTab(idx, filtro: null),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Mis registros',
          ),
          avisosDestination(noLeidas),
        ],
      ),
    );
  }
}

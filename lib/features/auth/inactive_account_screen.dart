import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_provider.dart';
import '../../data/models/usuario.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/icono_en_vidrio.dart';

/// C-08: la ven los usuarios cuya cuenta aún no fue activada.
/// Espejo de `InactiveAccountView` (iOS).
class InactiveAccountScreen extends ConsumerWidget {
  const InactiveAccountScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantalla diseñada en negro con texto blanco: no sigue el tema de la app.
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.black.withValues(alpha: 0.4)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                const IconoEnVidrio(icono: Icons.hourglass_top_rounded),
                const SizedBox(height: 22),
                const Text(
                  'Cuenta pendiente',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Hola ${usuario.nombres}, tu cuenta aún espera la activación de un '
                    'administrador. Te avisaremos por correo cuando esté lista.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      title: 'Volver al inicio de sesión',
                      // El logout dispara el redirect del router hacia /login.
                      action: () => ref.read(sessionProvider.notifier).logout(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

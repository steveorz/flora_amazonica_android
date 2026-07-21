import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/app_button.dart';
import '../../design_system/components/icono_en_vidrio.dart';
import 'auth_scaffold.dart';

/// C-05: confirmación de cuenta esperando activación.
/// Espejo de `AccountCreatedView` (iOS).
class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffoldOscuro(
      // Ya no hay vuelta atrás: la cuenta quedó creada.
      mostrarAtras: false,
      child: Column(
        children: [
          const Spacer(),
          const IconoEnVidrio(icono: Icons.mark_email_read_rounded),
          const SizedBox(height: 22),
          const Text(
            'Cuenta creada',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tu cuenta está esperando la activación de un administrador. '
              'Recibirás un correo cuando esté lista.',
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
                action: () => context.go('/login'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

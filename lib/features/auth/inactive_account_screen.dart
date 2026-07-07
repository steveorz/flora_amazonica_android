import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';
import '../../data/models/usuario.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/theme/brand_colors.dart';

class InactiveAccountScreen extends ConsumerWidget {
  final Usuario usuario;
  
  const InactiveAccountScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.black.withOpacity(0.4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.watch_later, // Analog for clock.badge.exclamationmark
                  size: 72,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                "Cuenta pendiente",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  "Hola ${usuario.nombres}, tu cuenta aún espera la activación de un administrador. Te avisaremos por correo cuando esté lista.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    title: "Volver al inicio de sesión",
                    variant: AppButtonVariant.primario,
                    action: () {
                      ref.read(sessionProvider.notifier).logout();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

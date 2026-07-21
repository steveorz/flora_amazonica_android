import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/session_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_text_field.dart';
import '../../design_system/glass/glass_card.dart';
import 'auth_scaffold.dart';

/// C-06: solicitud de recuperación por email. Espejo de `RecoverPasswordView`.
class RecoverPasswordScreen extends ConsumerStatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  ConsumerState<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends ConsumerState<RecoverPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await ref.read(sessionProvider.notifier).requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      context.push('/new-password', extra: _email.text.trim());
    } on AuthError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = AuthError.generico.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffoldOscuro(
      titulo: 'Recuperar',
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: _email,
          builder: (context, _) {
            final puedeEnviar = !_loading && _email.text.trim().isNotEmpty;
            return Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Recuperar contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Te enviaremos un código al correo asociado a tu cuenta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    child: Column(
                      children: [
                        AppTextField(
                          title: 'Email',
                          placeholder: 'tu@correo.pe',
                          controller: _email,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_error!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            title: _loading ? 'Enviando…' : 'Enviar código',
                            enabled: puedeEnviar,
                            action: _enviar,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

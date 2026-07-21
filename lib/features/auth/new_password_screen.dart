import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/session_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_text_field.dart';
import '../../design_system/components/icono_en_vidrio.dart';
import '../../design_system/glass/glass_card.dart';
import 'auth_scaffold.dart';

/// C-07: definición de nueva contraseña. Espejo de `NewPasswordView`.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _error;

  static const _longitudMinima = 8;

  bool get _puedeEnviar =>
      _nueva.text.length >= _longitudMinima && _nueva.text == _confirmar.text;

  @override
  void dispose() {
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await ref.read(sessionProvider.notifier).resetPassword(widget.email, _nueva.text);
      if (mounted) setState(() => _success = true);
    } on AuthError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = AuthError.generico.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Vuelve al login descartando toda la pila del flujo de recuperación.
  void _volverAlLogin() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    return AuthScaffoldOscuro(
      titulo: 'Nueva contraseña',
      // Tras el éxito no tiene sentido volver al formulario.
      mostrarAtras: !_success,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: _success ? _exito() : _formulario(),
        ),
      ),
    );
  }

  Widget _formulario() {
    return ListenableBuilder(
      listenable: Listenable.merge([_nueva, _confirmar]),
      builder: (context, _) {
        final noCoinciden = _confirmar.text.isNotEmpty && _nueva.text != _confirmar.text;
        return Column(
          children: [
            const Text(
              'Define tu nueva contraseña',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Para ${widget.email}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                child: Column(
                  children: [
                    AppTextField(
                      title: 'Nueva contraseña',
                      kind: AppTextFieldKind.password,
                      controller: _nueva,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      title: 'Confirmar contraseña',
                      kind: AppTextFieldKind.password,
                      controller: _confirmar,
                    ),
                    if (noCoinciden) ...[
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Las contraseñas no coinciden',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 8),
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
                        title: _loading ? 'Guardando…' : 'Guardar contraseña',
                        enabled: !_loading && _puedeEnviar,
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
    );
  }

  Widget _exito() {
    return Column(
      children: [
        const IconoEnVidrio(icono: Icons.verified_rounded, tamano: 60),
        const SizedBox(height: 18),
        const Text(
          'Contraseña actualizada',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Ya puedes iniciar sesión con tu nueva contraseña.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: AppButton(title: 'Volver al inicio de sesión', action: _volverAlLogin),
          ),
        ),
      ],
    );
  }
}

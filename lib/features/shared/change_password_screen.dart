import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../design_system/components/app_button.dart';

/// Cambio de contraseña del usuario en sesión. Espejo de `ChangePasswordView` (iOS).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  static const _longitudMinima = 8;

  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  bool _enviando = false;
  String? _error;

  bool get _puedeEnviar =>
      _actual.text.isNotEmpty &&
      _nueva.text.length >= _longitudMinima &&
      _nueva.text == _confirmar.text;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _error = null;
      _enviando = true;
    });
    try {
      await ref.read(sessionProvider.notifier).changePassword(_actual.text, _nueva.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Contraseña actualizada.')));
      Navigator.of(context).pop();
    } on AuthError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = AuthError.generico.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: ListenableBuilder(
        listenable: Listenable.merge([_actual, _nueva, _confirmar]),
        builder: (context, _) {
          final noCoinciden = _confirmar.text.isNotEmpty && _nueva.text != _confirmar.text;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _actual,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nueva,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  helperText: 'Mínimo $_longitudMinima caracteres',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmar,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
              ),
              if (noCoinciden) ...[
                const SizedBox(height: 8),
                Text('Las contraseñas no coinciden',
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  title: _enviando ? 'Guardando…' : 'Guardar contraseña',
                  enabled: !_enviando && _puedeEnviar,
                  action: _enviar,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

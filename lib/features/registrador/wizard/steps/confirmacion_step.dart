import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/app_button.dart';
import '../wizard_provider.dart';

/// R-14: confirmación de envío. Muestra el código de seguimiento generado.
/// Espejo de `ConfirmacionStep` (iOS).
class ConfirmacionStep extends ConsumerWidget {
  const ConfirmacionStep({super.key, required this.args, required this.onCerrar});

  final WizardArgs args;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(wizardProvider(args));
    final theme = Theme.of(context);
    final resultado = estado.resultado;

    if (resultado == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Enviando…'),
          ],
        ),
      );
    }

    final marca = theme.colorScheme.onSurface;

    return Column(
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: marca.withValues(alpha: 0.18),
          ),
          child: Icon(Icons.verified_rounded, size: 72, color: marca),
        ),
        const SizedBox(height: 22),
        Text(
          estado.editandoId == null ? 'Registro enviado' : 'Cambios guardados',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            'Tu registro está ahora en revisión por el validador científico.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 22),
        Text('Código de seguimiento', style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: marca.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            resultado.codigoSeguimiento,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w600),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: SizedBox(
            width: double.infinity,
            child: AppButton(title: 'Listo', action: onCerrar),
          ),
        ),
      ],
    );
  }
}

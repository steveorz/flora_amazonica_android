import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/habito.dart';
import '../../../../core/constants/tipo_vida.dart';
import '../wizard_provider.dart';
import 'step_widgets.dart';

/// R-05: hábito (5 tarjetas, selección única) + tipo de vida.
/// Espejo de `HabitoStep` (iOS).
class HabitoStep extends ConsumerWidget {
  const HabitoStep({super.key, required this.args});

  final WizardArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(wizardProvider(args)).draft;
    final wizard = ref.read(wizardProvider(args).notifier);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const StepHeader(
          titulo: 'Hábito y tipo de vida',
          detalle: 'Tu elección determina el formulario de morfología.',
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5, // ≈ 110 de alto sobre media pantalla
          children: [
            for (final h in Habito.values)
              _TarjetaHabito(
                habito: h,
                seleccionado: draft.habito == h,
                onTap: () => wizard.editar((d) => d.habito = h),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const SizedBox(height: 8),
        Text('Tipo de vida', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Column(
          children: [
            for (final t in TipoVida.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 110,
                  child: _TarjetaTipoVida(
                    tipo: t,
                    seleccionado: draft.tipoVida == t,
                    onTap: () => wizard.editar((d) => d.tipoVida = t),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Foto de la categoría con scrim y sólo la palabra encima. Mismo estilo que
/// las tarjetas de la búsqueda morfológica.
class _TarjetaHabito extends StatelessWidget {
  const _TarjetaHabito({
    required this.habito,
    required this.seleccionado,
    required this.onTap,
  });

  final Habito habito;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final marca = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(habito.categoryAsset, fit: BoxFit.cover),
              // Scrim: más claro cuando está seleccionada, para que la foto luzca.
              ColoredBox(
                color: Colors.black.withValues(alpha: seleccionado ? 0.15 : 0.45),
              ),
              Center(
                child: Text(
                  habito.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1))],
                  ),
                ),
              ),
              if (seleccionado)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle, size: 22, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaTipoVida extends StatelessWidget {
  const _TarjetaTipoVida({
    required this.tipo,
    required this.seleccionado,
    required this.onTap,
  });

  final TipoVida tipo;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(tipo.categoryAsset, fit: BoxFit.cover),
              ColoredBox(
                color: Colors.black.withValues(alpha: seleccionado ? 0.15 : 0.45),
              ),
              Center(
                child: Text(
                  tipo.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1))],
                  ),
                ),
              ),
              if (seleccionado)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle, size: 22, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

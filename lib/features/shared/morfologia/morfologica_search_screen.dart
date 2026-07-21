import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/habito.dart';
import '../../../design_system/components/app_button.dart';
import 'morf_filtros_step.dart';
import 'morfologica_search_store.dart';

/// Contenedor del flujo de búsqueda morfológica (CS-02 → CS-03 → CS-04).
/// Disponible para cualquier rol; se presenta a pantalla completa.
/// Espejo de `MorfologicalSearchView` (iOS).
class MorfologicaSearchScreen extends ConsumerWidget {
  const MorfologicaSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El contenedor observa el store para mantenerlo vivo mientras dure el flujo
    // (es autoDispose y las pantallas hijas van y vienen en el Navigator interno).
    ref.watch(morfSearchProvider);

    return const _MorfHabitoStep();
  }
}

/// CS-02: paso 1 — elegir hábito o "no estoy seguro".
/// Espejo de `MorfHabitoStep` (iOS).
class _MorfHabitoStep extends ConsumerWidget {
  const _MorfHabitoStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final estado = ref.watch(morfSearchProvider);
    final store = ref.read(morfSearchProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificar planta'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        leadingWidth: 80,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('¿Qué tipo de planta es?',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Elige el hábito que mejor se parece a la planta que viste.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              for (final h in Habito.values)
                _TarjetaHabito(
                  habito: h,
                  seleccionado: estado.habito == h,
                  onTap: () => store.setHabito(h),
                ),
              _TarjetaNoSeguro(
                seleccionado: estado.habito == null,
                onTap: () => store.setHabito(null),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            child: AppButton(
              title: 'Siguiente',
              action: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MorfFiltrosStep()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    final theme = Theme.of(context);
    final marca = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: seleccionado ? marca : Colors.transparent, width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(habito.categoryAsset, fit: BoxFit.cover),
              ColoredBox(
                color: Colors.black.withValues(alpha: seleccionado ? 0.2 : 0.5),
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
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(Icons.check_circle, size: 24, color: marca),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaNoSeguro extends StatelessWidget {
  const _TarjetaNoSeguro({required this.seleccionado, required this.onTap});

  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marca = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: seleccionado ? marca : Colors.transparent, width: 3),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline,
                      size: 34,
                      color: seleccionado ? marca : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text('No estoy seguro',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (seleccionado)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, size: 24, color: marca),
              ),
          ],
        ),
      ),
    );
  }
}

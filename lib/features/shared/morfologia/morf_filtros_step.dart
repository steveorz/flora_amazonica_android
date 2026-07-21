import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/especie_service.dart';
import '../../../design_system/components/app_button.dart';
import 'morf_dimensions.dart';
import 'morf_resultados_screen.dart';
import 'morfologica_search_store.dart';

/// CS-03: paso 2 — filtros combinables con contador en vivo.
/// Espejo de `MorfFiltrosStep` (iOS).
class MorfFiltrosStep extends ConsumerStatefulWidget {
  const MorfFiltrosStep({super.key});

  @override
  ConsumerState<MorfFiltrosStep> createState() => _MorfFiltrosStepState();
}

class _MorfFiltrosStepState extends ConsumerState<MorfFiltrosStep> {
  final Set<String> _expandidas = {'Florales'};

  /// Cuántas opciones hay marcadas dentro de una categoría.
  int _seleccionadasEn(String categoria, Map<String, Set<String>> selecciones) {
    var total = 0;
    for (final dim in MorfDimensions.deCategoria(categoria)) {
      total += selecciones[dim.id]?.length ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estado = ref.watch(morfSearchProvider);
    final store = ref.read(morfSearchProvider.notifier);
    final especies = ref.watch(especieServiceProvider).especies;

    // Contador en vivo: cuántas especies coinciden con los filtros actuales.
    final conteo = store.evaluar(especies).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Caracteres')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('¿Qué caracteres viste?',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Marca todo lo que aplique. Puedes combinar de varias secciones.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          for (final categoria in MorfDimensions.categorias)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SeccionCategoria(
                categoria: categoria,
                seleccionadas: _seleccionadasEn(categoria, estado.selecciones),
                expandida: _expandidas.contains(categoria),
                onToggle: (abierta) => setState(() =>
                    abierta ? _expandidas.add(categoria) : _expandidas.remove(categoria)),
                selecciones: estado.selecciones,
                onOpcion: store.toggle,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$conteo',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(conteo == 1 ? 'especie coincide' : 'especies coinciden',
                      style: theme.textTheme.bodySmall),
                ],
              ),
              const Spacer(),
              AppButton(
                title: 'Ver resultados',
                systemImage: Icons.arrow_forward,
                variant: AppButtonVariant.atencion,
                enabled: conteo > 0,
                action: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const MorfResultadosScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeccionCategoria extends StatelessWidget {
  const _SeccionCategoria({
    required this.categoria,
    required this.seleccionadas,
    required this.expandida,
    required this.onToggle,
    required this.selecciones,
    required this.onOpcion,
  });

  final String categoria;
  final int seleccionadas;
  final bool expandida;
  final ValueChanged<bool> onToggle;
  final Map<String, Set<String>> selecciones;
  final void Function(String dimensionId, String opcion) onOpcion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expandida,
          onExpansionChanged: onToggle,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Row(
            children: [
              Text(categoria, style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              )),
              if (seleccionadas > 0) ...[
                const SizedBox(width: 8),
                Badge(
                  label: Text('$seleccionadas'),
                  backgroundColor: theme.colorScheme.primary,
                  textColor: theme.colorScheme.onPrimary,
                ),
              ],
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final dim in MorfDimensions.deCategoria(categoria))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dim.titulo,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        )),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final opcion in dim.opciones)
                          Builder(builder: (context) {
                            final isSelected = selecciones[dim.id]?.contains(opcion.label) ?? false;
                            return FilterChip(
                              label: Text(opcion.label),
                              selected: isSelected,
                              onSelected: (_) => onOpcion(dim.id, opcion.label),
                              showCheckmark: false,
                              shape: const StadiumBorder(),
                              selectedColor: theme.colorScheme.primary,
                              backgroundColor: theme.colorScheme.surface,
                              side: BorderSide.none,
                              labelStyle: TextStyle(
                                color: isSelected 
                                    ? theme.colorScheme.onPrimary 
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

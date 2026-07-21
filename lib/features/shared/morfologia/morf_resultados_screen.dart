import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/especie_service.dart';
import '../../../data/models/especie.dart';
import '../../../design_system/components/empty_state.dart';
import '../../../design_system/components/species_card.dart';
import '../especie/ficha_tecnica_screen.dart';
import 'morfologica_search_store.dart';

enum ModoResultados { lista, galeria }

/// Un filtro aplicado, mostrado como chip que se puede quitar.
class _ChipAplicado {
  final String dimensionId;
  final String opcion;
  final String label;

  /// El chip de hábito no pertenece a ninguna dimensión: no se puede quitar aquí.
  final bool esHabito;

  const _ChipAplicado({
    required this.dimensionId,
    required this.opcion,
    required this.label,
    this.esHabito = false,
  });
}

/// CS-04: resultados ordenados por coincidencias, con vista lista o galería.
/// Espejo de `ResultadosView` (iOS).
class MorfResultadosScreen extends ConsumerStatefulWidget {
  const MorfResultadosScreen({super.key});

  @override
  ConsumerState<MorfResultadosScreen> createState() => _MorfResultadosScreenState();
}

class _MorfResultadosScreenState extends ConsumerState<MorfResultadosScreen> {
  ModoResultados _modo = ModoResultados.lista;

  List<_ChipAplicado> _chips(MorfSearchState estado) {
    return [
      if (estado.habito != null)
        _ChipAplicado(
          dimensionId: 'habito',
          opcion: estado.habito!.name,
          label: estado.habito!.label,
          esHabito: true,
        ),
      for (final entrada in estado.selecciones.entries)
        for (final opcion in entrada.value)
          _ChipAplicado(dimensionId: entrada.key, opcion: opcion, label: opcion),
    ];
  }

  void _abrirFicha(Especie especie) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => FichaTecnicaScreen(especie: especie)),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estado = ref.watch(morfSearchProvider);
    final store = ref.read(morfSearchProvider.notifier);
    final resultados = store.evaluar(ref.watch(especieServiceProvider).especies);
    final chips = _chips(estado);

    return Scaffold(
      appBar: AppBar(title: const Text('Resultados')),
      body: Column(
        children: [
          if (chips.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final chip = chips[i];
                  return InputChip(
                    label: Text(chip.label),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    // El hábito se cambia volviendo al primer paso.
                    onDeleted: chip.esHabito
                        ? null
                        : () => store.limpiar(chip.dimensionId, chip.opcion),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  '${resultados.length} ${resultados.length == 1 ? "especie" : "especies"}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                SegmentedButton<ModoResultados>(
                  segments: const [
                    ButtonSegment(value: ModoResultados.lista, icon: Icon(Icons.list)),
                    ButtonSegment(value: ModoResultados.galeria, icon: Icon(Icons.grid_view)),
                  ],
                  selected: {_modo},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _modo = s.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: resultados.isEmpty
                ? EmptyState(
                    systemImage: Icons.search_off,
                    title: 'Sin resultados',
                    message: 'Afloja algún filtro o cambia de hábito y vuelve a intentar.',
                    actionTitle: 'Quitar filtros',
                    action: store.quitarFiltros,
                  )
                : _modo == ModoResultados.lista
                    ? _Lista(resultados: resultados, onTap: _abrirFicha)
                    : _Galeria(resultados: resultados, onTap: _abrirFicha),
          ),
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.resultados, required this.onTap});

  final List<MorfMatch> resultados;
  final void Function(Especie) onTap;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 40),
      children: [
        Material(
          color: oscuro
              ? Color.lerp(const Color(0xFF121212), Colors.white, 0.08)
              : Color.lerp(const Color(0xFFF0F2F5), Colors.white, 0.50),
          borderRadius: BorderRadius.circular(24),
          elevation: 0.5,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(resultados.length, (i) {
              final m = resultados[i];
              return Column(
                children: [
                  InkWell(
                    onTap: () => onTap(m.especie),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SpeciesCard(
                              especie: m.especie,
                              trailing: const SizedBox.shrink(),
                            ),
                          ),
                          if (m.total > 0) _BadgeCoincidencia(match: m),
                        ],
                      ),
                    ),
                  ),
                  if (i < resultados.length - 1)
                    const Divider(indent: 96, height: 1, thickness: 0.5),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _Galeria extends StatelessWidget {
  const _Galeria({required this.resultados, required this.onTap});

  final List<MorfMatch> resultados;
  final void Function(Especie) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: resultados.length,
      itemBuilder: (context, i) {
        final m = resultados[i];
        return InkWell(
          onTap: () => onTap(m.especie),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SpeciesCard(
                  especie: m.especie,
                  variant: SpeciesCardVariant.galeria,
                ),
              ),
              if (m.total > 0) _BadgeCoincidencia(match: m),
            ],
          ),
        );
      },
    );
  }
}

class _BadgeCoincidencia extends StatelessWidget {
  const _BadgeCoincidencia({required this.match});

  final MorfMatch match;

  @override
  Widget build(BuildContext context) {
    final marca = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: marca.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '${match.coincidencias}/${match.total}',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: marca,
        ),
      ),
    );
  }
}

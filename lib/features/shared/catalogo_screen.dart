import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/estado_registro.dart';
import '../../core/constants/habito.dart';
import '../../core/services/especie_service.dart';
import '../../data/models/especie.dart';
import '../../design_system/components/empty_state.dart';
import '../../design_system/components/species_card.dart';
import '../../design_system/components/mini_registro_card.dart';
import 'especie/ficha_tecnica_screen.dart';

/// Catálogo filtrable / buscable. Lo reutilizan la pestaña Buscar (CS-10) y los
/// chips de familia / tarjetas de hábito del home consultor.
/// Espejo de `CatalogoView` (iOS).
class CatalogoScreen extends ConsumerStatefulWidget {
  const CatalogoScreen({
    super.key,
    this.filtroFamilia,
    this.filtroHabito,
    this.tituloOverride,
    this.soloPublicadas = true,
  });

  final String? filtroFamilia;
  final Habito? filtroHabito;
  final String? tituloOverride;
  final bool soloPublicadas;

  @override
  ConsumerState<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends ConsumerState<CatalogoScreen> {
  final _busqueda = TextEditingController();
  bool _isGrid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(especieServiceProvider).especies.isEmpty) {
        ref.read(especieServiceProvider.notifier).cargar();
      }
    });
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  String get _titulo {
    if (widget.tituloOverride != null) return widget.tituloOverride!;
    if (widget.filtroFamilia != null) return widget.filtroFamilia!;
    if (widget.filtroHabito != null) return widget.filtroHabito!.label;
    return 'Buscar';
  }

  List<Especie> _filtradas(List<Especie> todas) {
    var lista = todas;

    if (widget.soloPublicadas) {
      lista = lista
          .where((e) =>
              e.estado == EstadoRegistro.validado && e.catalogId == null)
          .toList();
    }
    if (widget.filtroFamilia != null) {
      lista = lista.where((e) => e.familia == widget.filtroFamilia).toList();
    }
    if (widget.filtroHabito != null) {
      lista = lista.where((e) => e.habito == widget.filtroHabito).toList();
    }

    final q = _busqueda.text.toLowerCase();
    if (q.isNotEmpty) {
      lista = lista
          .where((e) =>
              e.nombreCientifico.toLowerCase().contains(q) ||
              e.nombreLocal.toLowerCase().contains(q) ||
              e.familia.toLowerCase().contains(q))
          .toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtradas(ref.watch(especieServiceProvider).especies);
    final hayBusqueda = _busqueda.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(_titulo)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Nombre científico, común o familia',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: filtradas.isEmpty
                ? EmptyState(
                    systemImage: Icons.search_off,
                    title: hayBusqueda ? 'Nada coincide' : 'Sin resultados',
                    message: hayBusqueda
                        ? 'Prueba con otro nombre, familia o nombre común.'
                        : 'No hay especies con ese filtro.',
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(especieServiceProvider.notifier).cargar(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => setState(() => _isGrid = !_isGrid),
                                icon: Icon(_isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded, size: 16),
                                label: Text(_isGrid ? 'Ver como lista' : 'Ver como fotos', style: const TextStyle(fontSize: 13)),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _isGrid
                              ? GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.75,
                                  ),
                                  itemCount: filtradas.length,
                                  itemBuilder: (context, i) => MiniRegistroCard(
                                    especie: filtradas[i],
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => FichaTecnicaScreen(especie: filtradas[i]),
                                      ),
                                    ),
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  children: [
                                    Material(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Color.lerp(const Color(0xFF121212), Colors.white, 0.08)
                                          : Color.lerp(const Color(0xFFF0F2F5), Colors.white, 0.50),
                                      borderRadius: BorderRadius.circular(24),
                                      elevation: 0.5,
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        children: List.generate(filtradas.length, (i) {
                                          final e = filtradas[i];
                                          return Column(
                                            children: [
                                              InkWell(
                                                onTap: () => Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) => FichaTecnicaScreen(especie: e),
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                  child: SpeciesCard(
                                                    especie: e,
                                                    trailing: const SizedBox.shrink(),
                                                  ),
                                                ),
                                              ),
                                              if (i < filtradas.length - 1)
                                                const Divider(indent: 96, height: 1, thickness: 0.5),
                                            ],
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

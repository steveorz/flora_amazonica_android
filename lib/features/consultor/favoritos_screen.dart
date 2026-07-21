import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/especie_service.dart';
import '../../data/models/especie.dart';
import '../../design_system/components/empty_state.dart';
import '../../design_system/components/species_card.dart';
import '../../design_system/components/mini_registro_card.dart';
import '../shared/especie/ficha_tecnica_screen.dart';
import '../shared/favoritos/favoritos_store.dart';

enum OrdenFavoritos {
  recientes('Más recientes'),
  antiguos('Más antiguos'),
  nombre('Nombre (A–Z)');

  final String label;
  const OrdenFavoritos(this.label);
}

/// CS-09: especies marcadas como favoritas. Espejo de `FavoritosView` (iOS).
class FavoritosScreen extends ConsumerStatefulWidget {
  const FavoritosScreen({super.key});

  @override
  ConsumerState<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends ConsumerState<FavoritosScreen> {
  bool _isGrid = false;
  OrdenFavoritos _orden = OrdenFavoritos.recientes;
  final Set<String> _seleccionados = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(especieServiceProvider).especies.isEmpty) {
        ref.read(especieServiceProvider.notifier).cargar();
      }
    });
  }

  void _toggleSeleccion(String id) {
    setState(() {
      if (_seleccionados.contains(id)) {
        _seleccionados.remove(id);
      } else {
        _seleccionados.add(id);
      }
    });
  }

  void _eliminarSeleccionados() {
    final notifier = ref.read(favoritosProvider.notifier);
    for (final id in _seleccionados) {
      notifier.toggle(id);
    }
    setState(() {
      _seleccionados.clear();
    });
  }

  List<Especie> _ordenar(List<Especie> favoritosList) {
    final base = List<Especie>.from(favoritosList);
    switch (_orden) {
      case OrdenFavoritos.recientes:
        base.sort((a, b) => b.fechaEnvio.compareTo(a.fechaEnvio));
      case OrdenFavoritos.antiguos:
        base.sort((a, b) => a.fechaEnvio.compareTo(b.fechaEnvio));
      case OrdenFavoritos.nombre:
        base.sort((a, b) =>
            a.nombreCientifico.toLowerCase().compareTo(b.nombreCientifico.toLowerCase()));
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oscuro = theme.brightness == Brightness.dark;
    
    final favoritos = ref.watch(favoritosProvider);
    final listaBase = ref
        .watch(especieServiceProvider)
        .especies
        .where((e) => favoritos.contains(e.id))
        .toList();
    
    final lista = _ordenar(listaBase);

    // Si ya no quedan favoritos que estaban seleccionados, limpiarlos
    _seleccionados.removeWhere((id) => !favoritos.contains(id));

    return Scaffold(
      floatingActionButton: _seleccionados.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _eliminarSeleccionados,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.delete),
              label: Text('Quitar (${_seleccionados.length})'),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              AnimatedPadding(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.only(right: 64, top: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    PopupMenuButton<OrdenFavoritos>(
                      initialValue: _orden,
                      onSelected: (o) => setState(() => _orden = o),
                      itemBuilder: (_) => [
                        for (final o in OrdenFavoritos.values)
                          PopupMenuItem(value: o, child: Text(o.label)),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Row(
                          children: [
                            Text(_orden.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => _isGrid = !_isGrid),
                      icon: Icon(_isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded, size: 16),
                      label: Text(_isGrid ? 'Ver como lista' : 'Ver como fotos', style: const TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        backgroundColor: oscuro ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
              Expanded(
                child: lista.isEmpty
                    ? const EmptyState(
                        systemImage: Icons.favorite_border,
                        title: 'Sin favoritos',
                        message: 'Toca el corazón en cualquier ficha técnica para guardarla aquí.',
                      )
                    : _isGrid 
                        ? GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 100),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 4 / 5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: lista.length,
                            itemBuilder: (context, index) {
                              final e = lista[index];
                              final isSelected = _seleccionados.contains(e.id);
                              
                              return MiniRegistroCard(
                                especie: e,
                                isSelected: isSelected,
                                badge: const SizedBox.shrink(),
                                onTap: () {
                                  if (_seleccionados.isNotEmpty) {
                                    _toggleSeleccion(e.id);
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => FichaTecnicaScreen(especie: e),
                                      ),
                                    );
                                  }
                                },
                                onLongPress: () => _toggleSeleccion(e.id),
                              );
                            },
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 100),
                            children: [
                              Material(
                                color: oscuro
                                    ? Color.lerp(const Color(0xFF121212), Colors.white, 0.08) // AppColors.backgroundDark
                                    : Color.lerp(const Color(0xFFF0F2F5), Colors.white, 0.50), // AppColors.background
                                borderRadius: BorderRadius.circular(24),
                                elevation: 0.5,
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: List.generate(lista.length, (i) {
                                    final e = lista[i];
                                    final isSelected = _seleccionados.contains(e.id);
                                    
                                    Widget tile = InkWell(
                                      onLongPress: () => _toggleSeleccion(e.id),
                                      onTap: () {
                                        if (_seleccionados.isNotEmpty) {
                                          _toggleSeleccion(e.id);
                                        } else {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => FichaTecnicaScreen(especie: e),
                                            ),
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        child: Row(
                                          children: [
                                            if (_seleccionados.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 12),
                                                child: Icon(
                                                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                                                ),
                                              ),
                                            Expanded(
                                              child: SpeciesCard(
                                                especie: e,
                                                trailing: const SizedBox.shrink(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );

                                    return Column(
                                      children: [
                                        tile,
                                        if (i < lista.length - 1)
                                          Divider(
                                            height: 1,
                                            indent: 16 + (_seleccionados.isNotEmpty ? 36.0 : 0.0),
                                            color: oscuro ? Colors.white12 : Colors.black12,
                                          ),
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
    );
  }
}

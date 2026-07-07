import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/especie_service.dart';
import '../../data/models/especie.dart';
import '../../design_system/components/empty_state.dart';
import '../../design_system/components/species_card.dart';

class CatalogoScreen extends ConsumerStatefulWidget {
  final bool soloPublicadas;
  const CatalogoScreen({super.key, this.soloPublicadas = true});

  @override
  ConsumerState<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends ConsumerState<CatalogoScreen> {
  String _search = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final especies = ref.read(especieServiceProvider);
      if (especies.isEmpty) {
        ref.read(especieServiceProvider.notifier).cargar();
      }
    });
  }

  List<Especie> get _filtradas {
    var list = ref.watch(especieServiceProvider);
    if (widget.soloPublicadas) {
      list = list.where((e) => e.estado == EstadoRegistro.publicado || e.estado == EstadoRegistro.validado).toList();
    }
    
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((e) {
        return e.nombreCientifico.toLowerCase().contains(q) ||
               e.nombreLocal.toLowerCase().contains(q) ||
               e.familia.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtradas;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Nombre científico, común o familia",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),
      ),
      body: list.isEmpty
          ? EmptyState(
              systemImage: Icons.search,
              title: _search.isEmpty ? "Sin resultados" : "Nada coincide",
              message: _search.isEmpty 
                ? "No hay especies con ese filtro." 
                : "Prueba con otro nombre, familia o nombre común.",
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final especie = list[index];
                return InkWell(
                  onTap: () {
                    // Navigate to detail
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: SpeciesCard(especie: especie, variant: SpeciesCardVariant.lista),
                  ),
                );
              },
            ),
    );
  }
}

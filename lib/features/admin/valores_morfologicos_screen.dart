import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/valor_morfologico_service.dart';
import '../../data/models/valor_morfologico.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/empty_state.dart';
import '../../design_system/components/error_state.dart';

/// Editor del catálogo de valores morfológicos: ver, alternar activos, crear
/// y borrar entradas. Espejo de `ValoresMorfologicosView` (iOS).
class ValoresMorfologicosScreen extends ConsumerStatefulWidget {
  const ValoresMorfologicosScreen({super.key});

  @override
  ConsumerState<ValoresMorfologicosScreen> createState() =>
      _ValoresMorfologicosScreenState();
}

class _ValoresMorfologicosScreenState extends ConsumerState<ValoresMorfologicosScreen> {
  String? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (ref.read(valorMorfologicoServiceProvider).valores.isEmpty) {
        await ref.read(valorMorfologicoServiceProvider.notifier).cargar();
      }
      if (!mounted) return;
      final categorias = ref.read(valorMorfologicoServiceProvider).categorias;
      if (_categoriaSeleccionada == null && categorias.isNotEmpty) {
        setState(() => _categoriaSeleccionada = categorias.first);
      }
    });
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _confirmarEliminar(ValorMorfologico v) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar este valor?'),
        content: Text(
          'Se borrará "${v.nombre}" del catálogo de ${v.categoria.toLowerCase()}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    await ref.read(valorMorfologicoServiceProvider.notifier).eliminar(v.codigo);
    if (mounted) _aviso('Valor eliminado.');
  }

  Future<void> _abrirNuevo() async {
    final servicio = ref.read(valorMorfologicoServiceProvider.notifier);
    final nuevo = await showModalBottomSheet<ValorMorfologico>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NuevoValorSheet(
        categoriasExistentes: ref.read(valorMorfologicoServiceProvider).categorias,
        categoriaPrellenada: _categoriaSeleccionada,
      ),
    );
    if (nuevo == null) return;
    await servicio.crear(nuevo);
    if (!mounted) return;
    setState(() => _categoriaSeleccionada = nuevo.categoria);
    _aviso('Valor creado.');
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(valorMorfologicoServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Valores morfológicos'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _abrirNuevo)],
      ),
      body: _cuerpo(estado),
    );
  }

  Widget _cuerpo(ValorMorfologicoState estado) {
    if (estado.loading && estado.valores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (estado.error != null && estado.valores.isEmpty) {
      return ErrorStateView(
        kind: estado.error!,
        onRetry: () => ref.read(valorMorfologicoServiceProvider.notifier).cargar(),
      );
    }
    if (estado.valores.isEmpty) {
      return const EmptyState(
        systemImage: Icons.hexagon_outlined,
        title: 'Sin valores cargados',
        message: 'Crea el primer valor para empezar a categorizar.',
      );
    }

    final categorias = estado.categorias;
    final categoria = _categoriaSeleccionada ?? categorias.first;
    final valores = estado.enCategoria(categoria);

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              for (final c in categorias)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: c == categoria,
                    onSelected: (_) => setState(() => _categoriaSeleccionada = c),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(valorMorfologicoServiceProvider.notifier).cargar(),
            child: ListView.builder(
              itemCount: valores.length,
              itemBuilder: (context, i) {
                final v = valores[i];
                return Dismissible(
                  key: ValueKey(v.codigo),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _confirmarEliminar(v);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: SwitchListTile(
                    title: Text(v.nombre),
                    subtitle: Text('Orden ${v.orden}'),
                    value: v.activo,
                    onChanged: (_) =>
                        ref.read(valorMorfologicoServiceProvider.notifier).toggleActivo(v),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Hoja para crear un valor nuevo. Devuelve el valor al cerrarse, o `null`.
class _NuevoValorSheet extends StatefulWidget {
  const _NuevoValorSheet({required this.categoriasExistentes, this.categoriaPrellenada});

  final List<String> categoriasExistentes;
  final String? categoriaPrellenada;

  @override
  State<_NuevoValorSheet> createState() => _NuevoValorSheetState();
}

class _NuevoValorSheetState extends State<_NuevoValorSheet> {
  late final TextEditingController _categoria =
      TextEditingController(text: widget.categoriaPrellenada ?? '');
  final _nombre = TextEditingController();
  final _orden = TextEditingController(text: '0');

  @override
  void dispose() {
    _categoria.dispose();
    _nombre.dispose();
    _orden.dispose();
    super.dispose();
  }

  bool get _valido => _categoria.text.trim().isNotEmpty && _nombre.text.trim().isNotEmpty;

  void _guardar() {
    Navigator.of(context).pop(
      ValorMorfologico(
        categoria: _categoria.text.trim(),
        nombre: _nombre.text.trim(),
        // El backend asigna el id real; hasta entonces sirve el nombre.
        codigo: _nombre.text.trim(),
        orden: int.tryParse(_orden.text) ?? 0,
        activo: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 8,
        // Deja espacio al teclado.
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: ListenableBuilder(
        listenable: Listenable.merge([_categoria, _nombre]),
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nuevo valor', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            if (widget.categoriasExistentes.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                children: [
                  for (final c in widget.categoriasExistentes)
                    ActionChip(
                      label: Text(c),
                      onPressed: () => setState(() => _categoria.text = c),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría / sección'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre del campo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orden,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Orden de visualización'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AppButton(title: 'Crear valor', enabled: _valido, action: _guardar),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/estado_registro.dart';
import '../../core/services/especie_service.dart';
import '../../core/session/session_provider.dart';
import '../../core/storage/draft_storage.dart';
import '../../data/models/especie.dart';
import '../../design_system/components/app_chips.dart';
import '../../design_system/components/empty_state.dart';
import '../../design_system/components/species_card.dart';
import '../../design_system/components/mini_registro_card.dart';
import 'registrador_shell.dart';
import '../shared/profile_screen.dart';
import 'detalle_registro_screen.dart';
import 'wizard/nuevo_registro_screen.dart';

enum OrdenRegistros {
  recientes('Más recientes'),
  antiguos('Más antiguos'),
  nombre('Nombre (A–Z)'),
  estado('Estado');

  final String label;
  const OrdenRegistros(this.label);
}

/// R-02: lista con búsqueda, filtros por estado, pull-to-refresh y swipe
/// para editar/eliminar. Espejo de `MisRegistrosView` (iOS).
class MisRegistrosScreen extends ConsumerStatefulWidget {
  const MisRegistrosScreen({super.key, this.filtroInicial});

  /// Permite llegar ya filtrado, p. ej. desde el resumen del home.
  final EstadoRegistro? filtroInicial;

  @override
  ConsumerState<MisRegistrosScreen> createState() => _MisRegistrosScreenState();
}

class _MisRegistrosScreenState extends ConsumerState<MisRegistrosScreen> {
  late Set<EstadoRegistro> _filtros = widget.filtroInicial != null ? {widget.filtroInicial!} : {};
  final _busqueda = TextEditingController();
  OrdenRegistros _orden = OrdenRegistros.recientes;
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
  void didUpdateWidget(MisRegistrosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filtroInicial != oldWidget.filtroInicial) {
      if (widget.filtroInicial != null) {
        _filtros = {widget.filtroInicial!};
      } else {
        _filtros.clear();
      }
    }
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  /// Validados están cerrados: ya no se tocan.
  bool _puedeEditar(Especie e) {
    return e.estado != EstadoRegistro.validado;
  }

  List<Especie> _filtrados(List<Especie> misRegistros) {
    final q = _busqueda.text.toLowerCase();
    final base = misRegistros.where((e) {
      if (_filtros.isNotEmpty && !_filtros.contains(e.estado)) return false;
      if (q.isEmpty) return true;
      return e.nombreCientifico.toLowerCase().contains(q) ||
          e.nombreLocal.toLowerCase().contains(q) ||
          e.familia.toLowerCase().contains(q);
    }).toList();

    switch (_orden) {
      case OrdenRegistros.recientes:
        base.sort((a, b) => b.fechaEnvio.compareTo(a.fechaEnvio));
      case OrdenRegistros.antiguos:
        base.sort((a, b) => a.fechaEnvio.compareTo(b.fechaEnvio));
      case OrdenRegistros.nombre:
        base.sort((a, b) =>
            a.nombreCientifico.toLowerCase().compareTo(b.nombreCientifico.toLowerCase()));
      case OrdenRegistros.estado:
        base.sort((a, b) => a.estado.index.compareTo(b.estado.index));
    }
    return base;
  }

  Future<void> _confirmarEliminar(Especie e) async {
    final theme = Theme.of(context);
    final oscuro = theme.brightness == Brightness.dark;
    final activeGreen = oscuro ? const Color(0xFF74C69D) : AppColors.primary;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: oscuro ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar este registro?', style: TextStyle(color: activeGreen, fontWeight: FontWeight.bold)),
        content: Text(e.nombreCientifico),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: activeGreen),
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold))
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      if (e.estado == EstadoRegistro.borrador && DraftStorage.get(e.id) != null) {
        await DraftStorage.delete(e.id);
        setState(() {}); // Refrescar para borrar de la UI
      } else {
        await ref.read(especieServiceProvider.notifier).eliminar(e.id);
      }
    }
  }

  void _abrirEdicion(Especie e) {
    final draftLocal = DraftStorage.get(e.id);
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => NuevoRegistroScreen(
          draft: draftLocal,
          especieAEditar: draftLocal == null ? e : null,
        ),
        fullscreenDialog: true,
      ),
    ).then((_) {
      // Al volver, refrescamos por si guardó cambios en el borrador
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(especieServiceProvider);
    final uid = ref.watch(sessionProvider).usuario?.id;
    
    // Combina borradores locales y registros del backend
    final borradoresLocales = DraftStorage.loadAll().map((d) => d.toEspecie()).toList();
    final registrosBackend = uid == null
        ? const <Especie>[]
        : estado.especies.where((e) => e.registradorId == uid).toList();
        
    final misRegistros = [...borradoresLocales, ...registrosBackend];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0), // Espacio normal, el buscador esquivará el ícono
          child: misRegistros.isEmpty && !estado.loading
              ? const EmptyState(
                  systemImage: Icons.inbox_outlined,
                  title: 'Sin registros',
                  message: 'Cuando crees registros aparecerán aquí.',
                )
              : _lista(_filtrados(misRegistros)),
        ),
      ),
    );
  }

  Widget _lista(List<Especie> filtrados) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    
    // Intenta obtener el showFab del shell, si está disponible
    bool showFab = false;
    try {
      showFab = RegistradorShell.of(context).showFab;
    } catch (_) {
      // Si por alguna razón no está en el Shell, asumimos que no hay fab
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(especieServiceProvider.notifier).cargar(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.only(bottom: 12, right: showFab ? 64 : 0),
            child: TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, familia o local',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: oscuro
                    ? Color.lerp(AppColors.backgroundDark, Colors.white, 0.08) // ~8-10% más claro en oscuro
                    : Color.lerp(AppColors.background, Colors.white, 0.60),   // ~10% más claro (casi blanco) en claro
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100), // Forma ovalada (píldora)
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          AppChips<EstadoRegistro?>(
            items: const [null, ...EstadoRegistro.values],
            selection: _filtros.isEmpty ? {null} : _filtros,
            labelFor: (e) => e == null ? 'Todos' : e.label,
            onChanged: (nuevos) {
              setState(() {
                if (nuevos.contains(null) && !_filtros.isEmpty && !nuevos.containsAll(_filtros)) {
                  // Si el null fue agregado recientemente (está en nuevos pero antes no, o el usuario lo tocó)
                  // Dado que AppChips alterna, si 'Todos' no estaba en selection, lo agrega.
                  // Aquí si `nuevos.contains(null)` y antes teníamos estados, limpiamos.
                  // Una forma más segura: Si en _filtros NO estaba null, y ahora SÍ está, el usuario tocó Todos.
                }
                
                bool touchedTodos = !(_filtros.isEmpty) && nuevos.contains(null);
                
                if (touchedTodos || nuevos.isEmpty) {
                  _filtros.clear();
                } else {
                  nuevos.remove(null);
                  _filtros = nuevos.whereType<EstadoRegistro>().toSet();
                }
              });
            },
            scrollable: true,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PopupMenuButton<OrdenRegistros>(
                initialValue: _orden,
                onSelected: (o) => setState(() => _orden = o),
                itemBuilder: (_) => [
                  for (final o in OrdenRegistros.values)
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
          const SizedBox(height: 16),
          if (filtrados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No hay resultados.')),
            )
          else if (_isGrid)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 4 / 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filtrados.length,
              itemBuilder: (context, index) {
                final e = filtrados[index];
                return MiniRegistroCard(
                  especie: e,
                  onTap: () {
                    if (e.estado == EstadoRegistro.borrador && DraftStorage.get(e.id) != null) {
                      _abrirEdicion(e);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => DetalleRegistroScreen(especie: e)),
                      );
                    }
                  }
                );
              },
            )
          else
            Material(
              color: oscuro
                  ? Color.lerp(AppColors.backgroundDark, Colors.white, 0.08)
                  : Color.lerp(AppColors.background, Colors.white, 0.50),
              borderRadius: BorderRadius.circular(24),
              elevation: 0.5,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(filtrados.length, (index) {
                  final e = filtrados[index];
                  return _FilaRegistro(
                    especie: e,
                    puedeEditar: _puedeEditar(e),
                    onAbrir: () {
                      if (e.estado == EstadoRegistro.borrador && DraftStorage.get(e.id) != null) {
                        _abrirEdicion(e);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => DetalleRegistroScreen(especie: e)),
                        );
                      }
                    },
                    onEditar: () => _abrirEdicion(e),
                    onEliminar: () => _confirmarEliminar(e),
                    showDivider: index < filtrados.length - 1,
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

/// Deslizar hacia la izquierda ofrece editar y eliminar, como los
/// `swipeActions` de iOS.
class _FilaRegistro extends StatelessWidget {
  const _FilaRegistro({
    required this.especie,
    required this.puedeEditar,
    required this.onAbrir,
    required this.onEditar,
    required this.onEliminar,
    required this.showDivider,
  });

  final Especie especie;
  final bool puedeEditar;
  final VoidCallback onAbrir;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oscuro = theme.brightness == Brightness.dark;

    final tarjeta = InkWell(
      onTap: onAbrir,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Espaciado cómodo de lista
        child: SpeciesCard(especie: especie),
      ),
    );

    Widget contenido = tarjeta;

    if (puedeEditar) {
      contenido = Dismissible(
        key: ValueKey(especie.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          final accion = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: oscuro ? const Color(0xFF1A1A1A) : Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) {
              final activeGreen = oscuro ? const Color(0xFF74C69D) : AppColors.primary;
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: oscuro ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.edit_outlined, color: activeGreen),
                        title: Text('Editar registro', style: TextStyle(fontWeight: FontWeight.w500, color: activeGreen)),
                        onTap: () => Navigator.pop(ctx, 'editar'),
                      ),
                      ListTile(
                        leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                        title: Text('Eliminar registro', style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.error)),
                        onTap: () => Navigator.pop(ctx, 'eliminar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          if (accion == 'editar') onEditar();
          if (accion == 'eliminar') onEliminar();
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.blueGrey.withOpacity(0.1),
          child: const Icon(Icons.more_horiz),
        ),
        child: tarjeta,
      );
    }

    return Column(
      children: [
        contenido,
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: oscuro ? Colors.white12 : Colors.grey.shade100,
            indent: 76, // Indentación perfecta después de la foto circular
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/rol.dart';
import '../../core/services/usuario_service.dart';
import '../../data/models/usuario.dart';
import '../../design_system/components/empty_state.dart';
import '../../design_system/components/error_state.dart';
import '../../core/session/session_provider.dart';
import 'package:go_router/go_router.dart';
import 'usuario_detalle_screen.dart';
import 'admin_shell.dart';
import '../../core/constants/app_colors.dart';

final filtroRolesAdminProvider = StateProvider<Set<Rol>>((ref) => {});

enum FiltroEstadoUsuario {
  todos('Todos'),
  pendientes('Pendientes'),
  activos('Activos'),
  inactivos('Inactivos');

  final String label;
  const FiltroEstadoUsuario(this.label);
}

/// AM-02: lista de usuarios con búsqueda y chips de filtro.
/// Espejo de `UsuariosView` (iOS).
class UsuariosScreen extends ConsumerStatefulWidget {
  const UsuariosScreen({super.key});

  @override
  ConsumerState<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends ConsumerState<UsuariosScreen> {
  final _busqueda = TextEditingController();
  FiltroEstadoUsuario _filtroEstado = FiltroEstadoUsuario.todos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(usuarioServiceProvider).usuarios.isEmpty) {
        ref.read(usuarioServiceProvider.notifier).cargar();
      }
    });
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  List<Usuario> _filtrados(List<Usuario> todos) {
    var lista = todos;

    lista = switch (_filtroEstado) {
      FiltroEstadoUsuario.todos => lista,
      FiltroEstadoUsuario.pendientes =>
        lista.where((u) => u.estado == EstadoUsuario.pendiente).toList(),
      FiltroEstadoUsuario.activos =>
        lista.where((u) => u.estado == EstadoUsuario.activo).toList(),
      FiltroEstadoUsuario.inactivos =>
        lista.where((u) => u.estado == EstadoUsuario.inactivo).toList(),
    };

    final roles = ref.watch(filtroRolesAdminProvider);
    if (roles.isNotEmpty) {
      lista = lista.where((u) => roles.contains(u.rol)).toList();
    }

    final q = _busqueda.text.toLowerCase();
    if (q.isNotEmpty) {
      lista = lista
          .where((u) =>
              u.nombreCompleto.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.institucion.toLowerCase().contains(q))
          .toList();
    }

    // Los pendientes primero: son los que requieren acción del admin.
    lista = [...lista]..sort((a, b) {
        final aPend = a.estado == EstadoUsuario.pendiente;
        final bPend = b.estado == EstadoUsuario.pendiente;
        if (aPend != bPend) return aPend ? -1 : 1;
        return a.nombreCompleto.compareTo(b.nombreCompleto);
      });
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(usuarioServiceProvider);
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    bool showFab = false;
    try {
      showFab = AdminShell.of(context).showFab;
    } catch (_) {}

    if (estado.loading && estado.usuarios.isEmpty) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (estado.error != null && estado.usuarios.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: ErrorStateView(
            kind: estado.error!,
            onRetry: () => ref.read(usuarioServiceProvider.notifier).cargar(),
          ),
        ),
      );
    }

    final filtrados = _filtrados(estado.usuarios);
    final buscando = _busqueda.text.isNotEmpty;
    final rolesSeleccionados = ref.watch(filtroRolesAdminProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.fromLTRB(16, 12, showFab ? 64 : 16, 8),
            child: TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nombre, email o institución',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: oscuro
                    ? Color.lerp(AppColors.backgroundDark, Colors.white, 0.08)
                    : Color.lerp(AppColors.background, Colors.white, 0.60),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
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
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in FiltroEstadoUsuario.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.label),
                      selected: _filtroEstado == f,
                      onSelected: (_) => setState(() => _filtroEstado = f),
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _filtroEstado == FiltroEstadoUsuario.todos
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final r in Rol.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _BotonRol(
                                rol: r,
                                seleccionado: rolesSeleccionados.contains(r),
                                onTap: () {
                                  final nuevos = Set<Rol>.of(rolesSeleccionados);
                                  nuevos.contains(r) ? nuevos.remove(r) : nuevos.add(r);
                                  ref.read(filtroRolesAdminProvider.notifier).state = nuevos;
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: filtrados.isEmpty
                ? EmptyState(
                    systemImage: Icons.person_search,
                    title: buscando ? 'Nada coincide' : 'Sin coincidencias',
                    message: buscando
                        ? 'Prueba con otro nombre, email o institución.'
                        : 'Prueba a quitar algún filtro.',
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: RefreshIndicator(
                      key: ValueKey('${filtrados.length}_${_filtroEstado.name}_${rolesSeleccionados.length}'),
                      onRefresh: () => ref.read(usuarioServiceProvider.notifier).cargar(),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 40),
                        children: [
                          Material(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Color.lerp(const Color(0xFF121212), Colors.white, 0.08)
                                : Color.lerp(const Color(0xFFF0F2F5), Colors.white, 0.50),
                            borderRadius: BorderRadius.circular(24),
                            elevation: 0.5,
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: List.generate(filtrados.length, (i) {
                                return Column(
                                  children: [
                                    _FilaUsuario(usuario: filtrados[i]),
                                    if (i < filtrados.length - 1)
                                      const Divider(indent: 72, height: 1, thickness: 0.5),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ));
  }
}

class _BotonRol extends StatelessWidget {
  const _BotonRol({required this.rol, required this.seleccionado, required this.onTap});

  final Rol rol;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seleccionado ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
          ),
          color: seleccionado ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        ),
        child: Center(
          child: Text(
            rol.label,
            style: TextStyle(
              color: seleccionado ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaUsuario extends StatelessWidget {
  const _FilaUsuario({required this.usuario});

  final Usuario usuario;

  static Color _colorEstado(EstadoUsuario e) => switch (e) {
        EstadoUsuario.activo => Colors.green,
        EstadoUsuario.pendiente => Colors.orange,
        EstadoUsuario.inactivo => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorEstado(usuario.estado);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => UsuarioDetalleScreen(usuarioId: usuario.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(child: Text(usuario.iniciales)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.nombreCompleto, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(usuario.email, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(usuario.estado.name.toUpperCase(),
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 4),
                Text(usuario.rol.label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

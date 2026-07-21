import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/estado_registro.dart';
import '../../core/constants/rol.dart';
import '../../core/services/especie_service.dart';
import '../../core/services/usuario_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/session/session_provider.dart';
import '../../data/models/usuario.dart';
import 'package:go_router/go_router.dart';

/// AM-01: panel principal del administrador. Alerta de cuentas pendientes,
/// contadores del sistema y accesos rápidos. Espejo de `DashboardAdminView`.
class DashboardAdminScreen extends ConsumerStatefulWidget {
  const DashboardAdminScreen({super.key, required this.onIrAUsuarios});

  final void Function(Rol?) onIrAUsuarios;

  @override
  ConsumerState<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends ConsumerState<DashboardAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarSiHaceFalta());
  }

  Future<void> _cargarSiHaceFalta() async {
    if (ref.read(usuarioServiceProvider).usuarios.isEmpty) {
      await ref.read(usuarioServiceProvider.notifier).cargar();
    }
    if (ref.read(especieServiceProvider).especies.isEmpty) {
      await ref.read(especieServiceProvider.notifier).cargar();
    }
  }

  Future<void> _recargar() async {
    await ref.read(usuarioServiceProvider.notifier).cargar();
    await ref.read(especieServiceProvider.notifier).cargar();
  }

  static IconData _iconoRol(Rol r) => switch (r) {
        Rol.registrador => Icons.edit_note,
        Rol.consultor => Icons.menu_book,
        Rol.administrador => Icons.admin_panel_settings,
        Rol.validador => Icons.verified,
      };

  static Color _colorRol(Rol r) => switch (r) {
        Rol.registrador => AppColors.primary,
        Rol.consultor => Colors.teal,
        Rol.administrador => Colors.purple,
        Rol.validador => Colors.blue,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estadoUsuarios = ref.watch(usuarioServiceProvider);
    final especies = ref.watch(especieServiceProvider).especies;
    final nombre = ref.watch(sessionProvider).usuario?.nombres ?? 'Administrador';
    final pendientes = estadoUsuarios.pendientes;

    int contar(EstadoRegistro e) => especies.where((x) => x.estado == e).length;

    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFF74C69D) : AppColors.primary;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _recargar,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Text('Hola, $nombre',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 4),
              Text('Resumen del catálogo y gestión de usuarios.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              if (pendientes.isNotEmpty) ...[
                const SizedBox(height: 20),
                _AlertaPendientes(
                  pendientes: pendientes,
                  onTap: () => widget.onIrAUsuarios(null),
                ),
              ],
            const SizedBox(height: 20),
            Text('Usuarios por rol',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: [
                for (final r in Rol.values)
                  _TileRol(
                    rol: r,
                    conteo: estadoUsuarios.conteoPorRol[r] ?? 0,
                    icono: _iconoRol(r),
                    color: _colorRol(r),
                    onTap: () => widget.onIrAUsuarios(r),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Estado de registros',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            const SizedBox(height: 10),
            _TarjetaEstado(
              conteo: contar(EstadoRegistro.enRevision),
              etiqueta: EstadoRegistro.enRevision.label,
              imagen: 'assets/images/fondo_en_revision.jpg',
              fallback: EstadoRegistro.enRevision.color(context),
            ),
            const SizedBox(height: 10),
            _TarjetaEstado(
              conteo: contar(EstadoRegistro.validado),
              etiqueta: EstadoRegistro.validado.label,
              imagen: 'assets/images/fondo_validado.jpg',
              fallback: EstadoRegistro.validado.color(context),
            ),
          ],
        ),
      ),
    ));
  }
}

class _AlertaPendientes extends StatelessWidget {
  const _AlertaPendientes({required this.pendientes, required this.onTap});

  final List<Usuario> pendientes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = pendientes.length;
    // Concordancia de número: iOS usa `^[...](inflect: true)`.
    final texto = n == 1 ? '1 cuenta por activar' : '$n cuentas por activar';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 230,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.orange),
              Image.asset('assets/images/fondo_admin_pendientes.jpg', fit: BoxFit.cover),
              // Scrim para que el texto se lea sobre la ilustración.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_forward, size: 16, color: Colors.orange),
                          SizedBox(width: 6),
                          Text('Ver pendientes',
                              style: TextStyle(
                                  color: Colors.orange, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(texto,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Hay nuevos usuarios esperando que les asignes un rol.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
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

/// Tile de color al estilo Recordatorios: icono arriba-izquierda, número grande
/// arriba-derecha, etiqueta abajo.
class _TileRol extends StatelessWidget {
  const _TileRol({
    required this.rol,
    required this.conteo,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  final Rol rol;
  final int conteo;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.75)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, size: 22, color: Colors.white),
              const Spacer(),
              Text('$conteo',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(rol.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaEstado extends StatelessWidget {
  const _TarjetaEstado({
    required this.conteo,
    required this.etiqueta,
    required this.imagen,
    required this.fallback,
  });

  final int conteo;
  final String etiqueta;
  final String imagen;
  final Color fallback;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visualización de registros disponible próximamente. La gestión de estados se realiza desde la versión web.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: SizedBox(
        height: 104,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: fallback),
            Image.asset(imagen, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$conteo',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  Text(etiqueta,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

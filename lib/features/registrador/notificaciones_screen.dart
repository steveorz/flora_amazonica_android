import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/especie_service.dart';
import '../../core/services/notificacion_service.dart';
import '../../core/session/session_provider.dart';
import '../../data/models/notificacion.dart';
import '../../design_system/components/empty_state.dart';
import '../../design_system/components/error_state.dart';
import '../shared/especie/ficha_tecnica_screen.dart';
import '../shared/profile_screen.dart' show ProfileToolbarButton;

/// C-11: pantalla de notificaciones, compartida por todos los roles.
/// Espejo de `NotificacionesView` (iOS).
class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final uid = ref.read(sessionProvider).usuario?.id;
    if (uid == null || uid.isEmpty) return;
    await ref.read(notificacionServiceProvider.notifier).cargar(uid);
  }

  Future<void> _marcarTodas() async {
    final uid = ref.read(sessionProvider).usuario?.id;
    if (uid == null || uid.isEmpty) return;
    await ref.read(notificacionServiceProvider.notifier).marcarTodasLeidas(uid);
  }

  /// Al abrir una notificación se marca leída y, si apunta a un registro,
  /// se navega a su ficha.
  Future<void> _abrir(Notificacion n) async {
    if (!n.leida) {
      await ref.read(notificacionServiceProvider.notifier).marcarLeida(n.id);
    }
    final registroId = n.registroRelacionadoId;
    if (registroId == null || !mounted) return;

    try {
      final especie = await ref.read(especieServiceProvider.notifier).get(registroId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => FichaTecnicaScreen(especie: especie)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el registro.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(notificacionServiceProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _cuerpo(estado)),
          ],
        ),
      ),
    );
  }

  Widget _cuerpo(NotificacionState estado) {
    if (estado.loading && estado.notificaciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (estado.error != null && estado.notificaciones.isEmpty) {
      return ErrorStateView(kind: estado.error!, onRetry: _cargar);
    }
    if (estado.notificaciones.isEmpty) {
      return const EmptyState(
        systemImage: Icons.notifications_off_outlined,
        title: 'Sin notificaciones',
        message: 'Cuando ocurra algo en tus registros o cuenta, te avisamos aquí.',
      );
    }

    final hoy = DateTime.now();
    final deHoy = estado.notificaciones.where((n) {
      final diff = hoy.difference(n.fecha);
      return diff.inDays == 0 && hoy.day == n.fecha.day;
    }).toList();
    final anteriores = estado.notificaciones.where((n) {
      final diff = hoy.difference(n.fecha);
      return !(diff.inDays == 0 && hoy.day == n.fecha.day);
    }).toList();
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _cargar,
      color: Theme.of(context).colorScheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 64, 16, 12),
        children: [
          if (estado.noLeidas > 0)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: _marcarTodas,
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Marcar todas',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          if (deHoy.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
              child: Text(
                'Hoy',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Material(
              color: oscuro
                  ? Color.lerp(AppColors.backgroundDark, Colors.white, 0.08) // 10% más claro en modo oscuro
                  : Color.lerp(AppColors.background, Colors.white, 0.50),   // 10% más claro en modo claro
              borderRadius: BorderRadius.circular(24),
              elevation: 0.5,
              clipBehavior: Clip.antiAlias, // Permite que el splash de selección sea visible y se recorte perfectamente
              child: Column(
                children: List.generate(deHoy.length, (index) {
                  return Dismissible(
                    key: Key(deHoy[index].id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      ref.read(notificacionServiceProvider.notifier).eliminar(deHoy[index].id);
                    },
                    background: Container(
                      color: theme.colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: Icon(Icons.delete, color: theme.colorScheme.onError),
                    ),
                    child: _FilaNotificacion(
                      notificacion: deHoy[index],
                      onTap: () => _abrir(deHoy[index]),
                      showDivider: index < deHoy.length - 1,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (anteriores.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
              child: Text(
                'Anteriores',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Material(
              color: oscuro
                  ? Color.lerp(AppColors.backgroundDark, Colors.white, 0.08) // 10% más claro en modo oscuro
                  : Color.lerp(AppColors.background, Colors.white, 0.50),   // 10% más claro en modo claro
              borderRadius: BorderRadius.circular(24),
              elevation: 0.5,
              clipBehavior: Clip.antiAlias, // Permite que el splash de selección sea visible y se recorte perfectamente
              child: Column(
                children: List.generate(anteriores.length, (index) {
                  return Dismissible(
                    key: Key(anteriores[index].id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      ref.read(notificacionServiceProvider.notifier).eliminar(anteriores[index].id);
                    },
                    background: Container(
                      color: theme.colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: Icon(Icons.delete, color: theme.colorScheme.onError),
                    ),
                    child: _FilaNotificacion(
                      notificacion: anteriores[index],
                      onTap: () => _abrir(anteriores[index]),
                      showDivider: index < anteriores.length - 1,
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaNotificacion extends StatelessWidget {
  const _FilaNotificacion({
    required this.notificacion,
    required this.onTap,
    required this.showDivider,
  });

  final Notificacion notificacion;
  final VoidCallback onTap;
  final bool showDivider;

  static String _hace(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 30) return 'hace ${diff.inDays} d';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final oscuro = theme.brightness == Brightness.dark;
    final n = notificacion;
    final titulo = n.titulo.trim().isNotEmpty ? n.titulo : n.tipo.label;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Avatar circular unificado con la paleta de color de la marca
                 Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: n.tipo.color.withOpacity(oscuro ? 0.20 : 0.12), // Tonalidad del estado con opacidad
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    n.tipo.icon,
                    color: n.tipo.color, // Color del estado original definido en el modelo
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Contenido de texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: n.leida ? FontWeight.w500 : FontWeight.w700,
                          color: colorScheme.onSurface, // Color de texto principal harmonizado
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.call_made, // Flecha arriba-derecha (↗)
                            size: 13,
                            color: colorScheme.onSurfaceVariant, // Color secundario harmonizado
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _hace(n.fecha),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant, // Color secundario harmonizado
                              fontSize: 13,
                            ),
                          ),
                          if (!n.leida) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: n.tipo.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                
                // Chevron derecha gris suave
                Icon(
                  Icons.chevron_right,
                  color: oscuro ? Colors.white30 : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 1,
              color: oscuro ? Colors.white12 : Colors.grey.shade100,
              indent: 74, // Alineado justo donde empieza el texto
            ),
        ],
      ),
    );
  }
}

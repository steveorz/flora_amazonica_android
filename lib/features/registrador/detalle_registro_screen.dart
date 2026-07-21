import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/estado_registro.dart';
import '../../core/services/especie_service.dart';
import '../../core/session/session_provider.dart';
import '../../core/utils/dasometria.dart';
import '../../core/widgets/osm_tiles.dart';
import '../../data/models/especie.dart';
import '../../design_system/components/estado_badge.dart';
import 'wizard/nuevo_registro_screen.dart';

/// R-03: detalle de un registro con mini-mapa, galería, timeline y acciones.
/// Espejo de `DetalleRegistroView` (iOS).
class DetalleRegistroScreen extends ConsumerWidget {
  const DetalleRegistroScreen({super.key, required this.especie});

  final Especie especie;

  /// Sólo el autor puede tocarlo, y sólo si aún no está cerrado.
  bool _puedeEditar(String? usuarioId) {
    if (especie.registradorId != usuarioId) return false;
    return especie.estado != EstadoRegistro.validado;
  }

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar este registro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    await ref.read(especieServiceProvider.notifier).eliminar(especie.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioId = ref.watch(sessionProvider).usuario?.id;
    final editable = _puedeEditar(usuarioId);
    final daso = especie.datosDasometricos;

    final caracteres = especie.caracteres.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final necesitaBanner = especie.estado == EstadoRegistro.observado ||
        especie.estado == EstadoRegistro.rechazado;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          especie.nombreLocal.isEmpty ? especie.nombreCientifico : especie.nombreLocal,
        ),
        actions: [
          if (editable)
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Theme.of(context).colorScheme.surface,
              elevation: 4,
              offset: const Offset(0, 45),
              onSelected: (v) {
                if (v == 'editar') {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => NuevoRegistroScreen(especieAEditar: especie),
                      fullscreenDialog: true,
                    ),
                  );
                } else if (v == 'eliminar') {
                  _confirmarEliminar(context, ref);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Cabecera(especie: especie),
          if (necesitaBanner) ...[
            const SizedBox(height: 16),
            _BannerObservacion(especie: especie),
          ],
          if (especie.fotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Galeria(especie: especie),
          ],
          const SizedBox(height: 16),
          _Seccion(titulo: 'Identificación', filas: [
            ('Autor', especie.autorNombre),
            ('Familia', especie.familia),
            ('Nombre local', especie.nombreLocal),
            ('Distribución', especie.distribucionPaises.join(', ')),
          ]),
          _Seccion(titulo: 'Hábito', filas: [
            ('Hábito', especie.habito.label),
            ('Tipo de vida', especie.tipoVida.label),
          ]),
          if (daso != null)
            _Seccion(titulo: 'Dasométricos', filas: [
              ('Altura', '${Dasometria.formato(daso.altura)} m'),
              ('CAP', '${Dasometria.formato(daso.cap)} cm'),
              ('DAP', '${Dasometria.formato(daso.dap)} cm'),
              ('Diám. copa ‖', '${Dasometria.formato(daso.diamCopaParalelo)} m'),
              ('Diám. copa ⊥', '${Dasometria.formato(daso.diamCopaPerpendicular)} m'),
              ('Inicio copa', '${Dasometria.formato(daso.alturaInicioCopa)} m'),
            ]),
          if (caracteres.isNotEmpty)
            _SeccionCaracteres(caracteres: caracteres),
          _SeccionUbicacion(especie: especie),
          if (especie.historialEstados.isNotEmpty)
            _SeccionHistorial(especie: especie),
        ],
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.especie});
  final Especie especie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(especie.nombreCientifico,
                  style: theme.textTheme.titleLarge?.copyWith(fontStyle: FontStyle.italic)),
              const SizedBox(height: 4),
              Text(especie.codigoSeguimiento,
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
            ],
          ),
        ),
        EstadoBadge(estado: especie.estado),
      ],
    );
  }
}

class _BannerObservacion extends StatelessWidget {
  const _BannerObservacion({required this.especie});
  final Especie especie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esRechazo = especie.estado == EstadoRegistro.rechazado;
    final color = esRechazo ? Colors.red : Colors.orange;

    // El motivo lo deja el validador en el último cambio de estado.
    final motivo = especie.historialEstados.isNotEmpty
        ? especie.historialEstados.last.comentario
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(esRechazo ? Icons.cancel : Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(esRechazo ? 'Registro rechazado' : 'Tiene observaciones',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  motivo?.isNotEmpty == true
                      ? motivo!
                      : 'El validador no dejó un comentario específico.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Galeria extends StatelessWidget {
  const _Galeria({required this.especie});
  final Especie especie;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 208,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: especie.fotos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final foto = especie.fotos[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: foto.url,
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 180,
                    height: 180,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 180,
                    height: 180,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(foto.tipo.label, style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        },
      ),
    );
  }
}

/// Contenedor de sección con el fondo secundario de iOS.
class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.titulo, required this.child});
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo, 
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700, 
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.filas});
  final String titulo;
  final List<(String, String)> filas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Tarjeta(
      titulo: titulo,
      child: Column(
        children: [
          for (final (etiqueta, valor) in filas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(etiqueta,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  Expanded(
                    child: Text(valor.isEmpty ? '—' : valor,
                        textAlign: TextAlign.right, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SeccionCaracteres extends StatelessWidget {
  const _SeccionCaracteres({required this.caracteres});
  final List<MapEntry<String, String>> caracteres;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Tarjeta(
      titulo: 'Caracteres morfológicos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in caracteres)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130, // un poco más de espacio para la etiqueta
                    child: Text(
                      e.key.isEmpty ? e.key : e.key[0].toUpperCase() + e.key.substring(1),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value.isEmpty ? '—' : e.value,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SeccionUbicacion extends StatelessWidget {
  const _SeccionUbicacion({required this.especie});
  final Especie especie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final punto = LatLng(especie.ubicacion.lat, especie.ubicacion.long);

    return _Tarjeta(
      titulo: 'Ubicación',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: punto,
                  initialZoom: 11,
                  // Mini-mapa sólo informativo, como el `allowsHitTesting(false)` de iOS.
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  const OsmTileLayer(),
                  MarkerLayer(markers: [
                    Marker(
                      point: punto,
                      child: Icon(Icons.place, color: theme.colorScheme.onSurface, size: 32),
                    ),
                  ]),
                  const OsmAtribucion(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final (etiqueta, valor) in [
            ('Latitud', especie.ubicacion.lat.toStringAsFixed(5)),
            ('Longitud', especie.ubicacion.long.toStringAsFixed(5)),
            ('Referencia', especie.ubicacion.referencia),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(etiqueta,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  Expanded(
                    child: Text(valor.isEmpty ? '—' : valor,
                        textAlign: TextAlign.right, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SeccionHistorial extends StatelessWidget {
  const _SeccionHistorial({required this.especie});
  final Especie especie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Tarjeta(
      titulo: 'Historial',
      child: Column(
        children: [
          for (final h in especie.historialEstados)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 10, color: h.estado.color(context)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(h.estado.label,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              '${h.fecha.day}/${h.fecha.month}/${h.fecha.year}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (h.comentario?.isNotEmpty == true)
                          Text(h.comentario!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

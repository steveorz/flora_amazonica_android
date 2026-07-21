import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/widgets/osm_tiles.dart';
import '../../../data/models/especie.dart';

/// Un punto donde se ha observado la especie.
class Avistamiento {
  final String id;
  final LatLng punto;
  final String codigo;
  final DateTime fecha;

  /// El avistamiento del propio registro, frente a los de referencia.
  final bool principal;

  const Avistamiento({
    required this.id,
    required this.punto,
    required this.codigo,
    required this.fecha,
    required this.principal,
  });
}

/// CS-08: mapa de distribución de una especie.
/// Espejo de `MapaDistribucionView` (iOS, que usa MapKit).
class MapaDistribucion extends StatefulWidget {
  const MapaDistribucion({super.key, required this.especie, this.pantallaCompleta = false});

  final Especie especie;
  final bool pantallaCompleta;

  @override
  State<MapaDistribucion> createState() => _MapaDistribucionState();
}

class _MapaDistribucionState extends State<MapaDistribucion> {
  Avistamiento? _seleccionado;

  /// Desplazamientos determinísticos (lat, long, días atrás) que iOS usa para
  /// dibujar una distribución de ejemplo alrededor del registro real.
  static const _desplazamientos = [
    (0.12, -0.08, -90),
    (-0.07, 0.11, -150),
    (0.18, 0.04, -45),
  ];

  List<Avistamiento> get _avistamientos {
    final base = widget.especie.ubicacion;
    final ahora = DateTime.now();

    return [
      Avistamiento(
        id: '${widget.especie.id}-0',
        punto: LatLng(base.lat, base.long),
        codigo: widget.especie.codigoSeguimiento,
        fecha: widget.especie.fechaEnvio,
        principal: true,
      ),
      for (var i = 0; i < _desplazamientos.length; i++)
        Avistamiento(
          id: '${widget.especie.id}-${i + 1}',
          punto: LatLng(
            base.lat + _desplazamientos[i].$1,
            base.long + _desplazamientos[i].$2,
          ),
          codigo: 'FAM-${ahora.year}-99${((i + 1) * 17).toString().padLeft(3, '0')}',
          fecha: ahora.add(Duration(days: _desplazamientos[i].$3)),
          principal: false,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marca = theme.colorScheme.onSurface;
    final centro = LatLng(widget.especie.ubicacion.lat, widget.especie.ubicacion.long);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: centro,
            // Zoom amplio: los avistamientos están a ~0.1° de distancia.
            initialZoom: 8.5,
            onTap: (_, __) => setState(() => _seleccionado = null),
          ),
          children: [
            const OsmTileLayer(),
            MarkerLayer(
              markers: [
                for (final av in _avistamientos)
                  Marker(
                    point: av.punto,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => setState(() => _seleccionado = av),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: av.principal ? marca : marca.withValues(alpha: 0.7),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)],
                        ),
                        child: Icon(
                          av.principal ? Icons.eco : Icons.eco_outlined,
                          size: 18,
                          color: theme.colorScheme.surface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const OsmAtribucion(),
          ],
        ),
        if (_seleccionado != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _MiniTarjeta(
              especie: widget.especie,
              avistamiento: _seleccionado!,
              onCerrar: () => setState(() => _seleccionado = null),
            ),
          ),
      ],
    );
  }
}

class _MiniTarjeta extends StatelessWidget {
  const _MiniTarjeta({
    required this.especie,
    required this.avistamiento,
    required this.onCerrar,
  });

  final Especie especie;
  final Avistamiento avistamiento;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = avistamiento.fecha;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: especie.habito.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.eco, color: especie.habito.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    especie.nombreCientifico,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(avistamiento.codigo,
                      style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                  Text('${f.day}/${f.month}/${f.year}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onCerrar),
          ],
        ),
      ),
    );
  }
}

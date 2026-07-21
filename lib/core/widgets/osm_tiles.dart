import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Capa de teselas de OpenStreetMap.
///
/// Sustituye a MapKit, que no existe en Android. OSM exige identificar la app
/// con un `userAgentPackageName`; sin él, sus servidores pueden bloquear las
/// peticiones.
class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'pe.flora.amazonica',
      maxNativeZoom: 19,
    );
  }
}

/// Atribución obligatoria por la licencia de OpenStreetMap.
class OsmAtribucion extends StatelessWidget {
  const OsmAtribucion({super.key});

  @override
  Widget build(BuildContext context) {
    return const RichAttributionWidget(
      attributions: [TextSourceAttribution('OpenStreetMap contributors')],
    );
  }
}

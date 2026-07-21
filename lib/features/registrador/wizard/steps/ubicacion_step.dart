import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/services/especie_service.dart';
import '../../../../core/widgets/osm_tiles.dart';
import '../../../../data/models/especie.dart';
import '../../../../data/models/ubicacion.dart';
import '../../../../design_system/components/app_button.dart';
import '../wizard_provider.dart';
import 'step_widgets.dart';

/// R-11: ubicación con mapa interactivo. La coordenada es el centro del mapa.
/// Espejo de `UbicacionStep` (iOS, que usa MapKit).
class UbicacionStep extends ConsumerStatefulWidget {
  const UbicacionStep({super.key, required this.args});

  final WizardArgs args;

  @override
  ConsumerState<UbicacionStep> createState() => _UbicacionStepState();
}

class _UbicacionStepState extends ConsumerState<UbicacionStep> {
  /// Iquitos: el centro por defecto cuando el borrador aún no tiene coordenada.
  static const _porDefecto = LatLng(-3.7437, -73.2516);

  /// Dos registros a menos de ~90 m se consideran sospechosamente cercanos.
  static const _umbralDuplicado = 0.0008;

  /// Altitud fija que asume iOS al construir la ubicación.
  static const _altitudPorDefecto = 110.0;

  final _mapController = MapController();
  late final TextEditingController _referencia;
  late final TextEditingController _tipoHabitat;

  late LatLng _coordenada;
  Especie? _duplicadoCercano;
  bool _buscandoUbicacion = false;
  String? _errorUbicacion;

  @override
  void initState() {
    super.initState();
    final ubicacion = ref.read(wizardProvider(widget.args)).draft.ubicacion;
    _coordenada = ubicacion != null ? LatLng(ubicacion.lat, ubicacion.long) : _porDefecto;
    _referencia = TextEditingController(text: ubicacion?.referencia ?? '');
    _tipoHabitat = TextEditingController(text: ubicacion?.tipoHabitat ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluarDuplicado());
  }

  @override
  void dispose() {
    _referencia.dispose();
    _tipoHabitat.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _actualizarDraft() {
    ref.read(wizardProvider(widget.args).notifier).editar((d) {
      d.ubicacion = Ubicacion(
        lat: _coordenada.latitude,
        long: _coordenada.longitude,
        referencia: _referencia.text,
        altitud: _altitudPorDefecto,
        tipoHabitat: _tipoHabitat.text,
      );
    });
  }

  /// Avisa si ya existe un registro prácticamente en el mismo punto.
  void _evaluarDuplicado() {
    final draftId = ref.read(wizardProvider(widget.args)).draft.id;
    Especie? encontrado;
    for (final e in ref.read(especieServiceProvider).especies) {
      if (e.id == draftId) continue;
      if ((e.ubicacion.lat - _coordenada.latitude).abs() < _umbralDuplicado &&
          (e.ubicacion.long - _coordenada.longitude).abs() < _umbralDuplicado) {
        encontrado = e;
        break;
      }
    }
    if (mounted) setState(() => _duplicadoCercano = encontrado);
  }

  Future<void> _centrarEnMiUbicacion() async {
    if (_buscandoUbicacion) return;
    setState(() {
      _buscandoUbicacion = true;
      _errorUbicacion = null;
    });
    try {
      final posicion = await LocationProvider.ubicacionActual();
      _coordenada = LatLng(posicion.latitude, posicion.longitude);
      _mapController.move(_coordenada, 14);
      _actualizarDraft();
      _evaluarDuplicado();
    } on LocationException catch (e) {
      if (mounted) setState(() => _errorUbicacion = e.message);
    } finally {
      if (mounted) setState(() => _buscandoUbicacion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const StepHeader(
          titulo: 'Ubicación',
          detalle: 'Centra el mapa en el punto exacto del registro.',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 290,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _coordenada,
                    initialZoom: 11,
                    // Al soltar el mapa, el centro pasa a ser la coordenada.
                    onPositionChanged: (posicion, tieneGesto) {
                      if (!tieneGesto) return;
                      _coordenada = posicion.center;
                    },
                    onMapEvent: (evento) {
                      if (evento is MapEventMoveEnd) {
                        _actualizarDraft();
                        _evaluarDuplicado();
                      }
                    },
                  ),
                  children: const [OsmTileLayer(), OsmAtribucion()],
                ),
                // Pin fijo al centro de la vista, no del mapa.
                IgnorePointer(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.place, size: 34, color: theme.colorScheme.onSurface),
                          Icon(Icons.circle,
                              size: 6,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.75)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Coordenada(titulo: 'Latitud', valor: _coordenada.latitude.toStringAsFixed(5)),
            _Coordenada(titulo: 'Longitud', valor: _coordenada.longitude.toStringAsFixed(5)),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            title: _buscandoUbicacion ? 'Obteniendo ubicación…' : 'Centrar en mi ubicación',
            systemImage: Icons.my_location,
            variant: AppButtonVariant.secundario,
            enabled: !_buscandoUbicacion,
            action: _centrarEnMiUbicacion,
          ),
        ),
        if (_errorUbicacion != null) ...[
          const SizedBox(height: 6),
          Text(_errorUbicacion!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
        ],
        if (_duplicadoCercano != null) ...[
          const SizedBox(height: 14),
          _AvisoDuplicado(especie: _duplicadoCercano!),
        ],
        const SizedBox(height: 14),
        CampoTexto(
          titulo: 'Referencia',
          hint: 'Ej.: Borde sur del aguajal',
          controller: _referencia,
          onChanged: (_) => _actualizarDraft(),
        ),
        const SizedBox(height: 12),
        CampoTexto(
          titulo: 'Tipo de hábitat *',
          hint: 'Ej.: Bosque de tierra firme',
          controller: _tipoHabitat,
          onChanged: (_) => _actualizarDraft(),
        ),
      ],
    );
  }
}

class _Coordenada extends StatelessWidget {
  const _Coordenada({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: theme.textTheme.bodySmall),
        Text(valor,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500, fontFamily: 'monospace')),
      ],
    );
  }
}

class _AvisoDuplicado extends StatelessWidget {
  const _AvisoDuplicado({required this.especie});

  final Especie especie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coordenadas muy cercanas a otro registro',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '${especie.nombreCientifico} — ${especie.codigoSeguimiento}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

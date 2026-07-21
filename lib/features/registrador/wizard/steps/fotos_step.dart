import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/models/foto.dart';
import '../wizard_provider.dart';
import 'step_widgets.dart';

/// R-12: 5 fotos obligatorias, una por tipo. Espejo de `FotosStep` (iOS).
class FotosStep extends ConsumerWidget {
  const FotosStep({super.key, required this.args});

  final WizardArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(wizardProvider(args));
    final theme = Theme.of(context);
    final capturadas = estado.draft.fotosCapturadas.length;
    final total = TipoFoto.values.length;
    final completo = capturadas == total;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const StepHeader(
          titulo: 'Fotografías',
          detalle: 'Captura una foto por cada tipo. Toca cualquier foto para reemplazarla.',
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85, // etiqueta + cuadrado
          children: [
            for (final tipo in TipoFoto.values) _SlotFoto(args: args, tipo: tipo),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              completo ? Icons.check_circle : Icons.photo_library_outlined,
              color: completo ? Colors.green : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text('$capturadas de $total fotos capturadas',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class _SlotFoto extends ConsumerStatefulWidget {
  const _SlotFoto({required this.args, required this.tipo});

  final WizardArgs args;
  final TipoFoto tipo;

  @override
  ConsumerState<_SlotFoto> createState() => _SlotFotoState();
}

class _SlotFotoState extends ConsumerState<_SlotFoto> {
  /// El backend rechaza en silencio los archivos grandes: limitamos el lado
  /// mayor a 1280 px y comprimimos al 70%, igual que iOS.
  static const _ladoMaximo = 1280.0;
  static const _calidadJpeg = 70;

  bool _cargando = false;

  Future<void> _elegirFoto() async {
    setState(() => _cargando = true);
    try {
      final imagen = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: _ladoMaximo,
        maxHeight: _ladoMaximo,
        imageQuality: _calidadJpeg,
      );
      if (imagen == null) return;

      final bytes = await imagen.readAsBytes();
      await ref.read(wizardProvider(widget.args).notifier).guardarFoto(widget.tipo, bytes);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estado = ref.watch(wizardProvider(widget.args));
    final Uint8List? bytes = estado.fotoData[widget.tipo];
    final capturada = estado.draft.fotosCapturadas.contains(widget.tipo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.tipo.label,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Expanded(
          child: GestureDetector(
            onTap: _cargando ? null : _elegirFoto,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bytes != null)
                    Image.memory(bytes, fit: BoxFit.cover)
                  else
                    ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 6),
                          Text('Tocar para agregar',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  if (_cargando)
                    ColoredBox(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  if (capturada && !_cargando)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.verified,
                          color: theme.colorScheme.onSurface, size: 22),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

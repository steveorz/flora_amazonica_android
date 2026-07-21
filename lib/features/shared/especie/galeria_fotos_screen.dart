import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/models/especie.dart';
import 'visor_foto_screen.dart';

/// CS-06: galería completa de fotos de una especie.
/// Espejo de `GaleriaFotosView` (iOS).
class GaleriaFotosScreen extends StatelessWidget {
  const GaleriaFotosScreen({super.key, required this.especie});

  final Especie especie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galería')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: especie.fotos.length,
        itemBuilder: (context, i) {
          final foto = especie.fotos[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VisorFotoScreen(
                  fotos: especie.fotos,
                  indiceInicial: i,
                  autorRegistro: especie.autorNombre,
                ),
                fullscreenDialog: true,
              ),
            ),
            child: Hero(
              tag: foto.id,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: foto.url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

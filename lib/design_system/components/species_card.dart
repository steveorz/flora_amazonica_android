import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/especie.dart';
import '../../core/constants/habito.dart';
import 'estado_badge.dart';

enum SpeciesCardVariant { lista, galeria, mini }

class SpeciesCard extends StatelessWidget {
  final Especie especie;
  final SpeciesCardVariant variant;
  final Widget? trailing;

  const SpeciesCard({
    super.key,
    required this.especie,
    this.variant = SpeciesCardVariant.lista,
    this.trailing,
  });

  Color _getHabitoColor() {
    switch (especie.habito) {
      case Habito.arbol:
        return Colors.green;
      case Habito.arbusto:
        return Colors.orange;
      case Habito.hierba:
        return Colors.lightGreen;
      case Habito.liana:
        return Colors.brown;
      case Habito.palmera:
        return Colors.teal;
    }
  }

  Widget _buildThumbnail(double size, double iconSize) {
    final color = _getHabitoColor();

    // Ícono de hábito tintado: el fallback cuando la especie no tiene foto.
    Widget placeholder() => Center(child: Icon(Icons.eco, color: color, size: iconSize));

    final portada = especie.portadaUrl;
    final finito = size.isFinite;

    return ClipRRect(
      borderRadius: BorderRadius.circular(variant == SpeciesCardVariant.lista ? size / 2 : 10),
      child: SizedBox(
        width: finito ? size : null,
        height: finito ? size : null,
        child: ColoredBox(
          color: color.withValues(alpha: 0.18),
          child: (portada != null && portada.isNotEmpty)
              // Si hay foto de portada la mostramos; si no, el ícono de hábito.
              ? CachedNetworkImage(
                  imageUrl: portada,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => placeholder(),
                  errorWidget: (_, __, ___) => placeholder(),
                )
              : placeholder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case SpeciesCardVariant.lista:
        return _buildLista(context);
      case SpeciesCardVariant.galeria:
        return _buildGaleria(context);
      case SpeciesCardVariant.mini:
        return _buildMini(context);
    }
  }

  Widget _buildLista(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildThumbnail(46, 18),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                especie.displayTitle,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface, // Color principal harmonizado
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
                Text(
                  especie.familia,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant, // Color secundario harmonizado
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (especie.nombreLocal.isNotEmpty)
                  Text(
                    especie.nombreLocal,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
          ),
        ),
        const SizedBox(width: 8),
        trailing ?? EstadoBadge(estado: especie.estado),
      ],
    );
  }

  Widget _buildGaleria(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: _buildThumbnail(double.infinity, 32),
        ),
        const SizedBox(height: 8),
        Text(
          especie.displayTitle,
          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          especie.familia,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMini(BuildContext context) {
    return Row(
      children: [
        _buildThumbnail(36, 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                especie.displayTitle,
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                especie.familia,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../data/models/especie.dart';
import '../../core/constants/habito.dart';
import 'estado_badge.dart';

enum SpeciesCardVariant { lista, galeria, mini }

class SpeciesCard extends StatelessWidget {
  final Especie especie;
  final SpeciesCardVariant variant;

  const SpeciesCard({
    super.key,
    required this.especie,
    this.variant = SpeciesCardVariant.lista,
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
      case Habito.epifita:
        return Colors.purple;
      case Habito.palmera:
        return Colors.teal;
      case Habito.helecho:
        return Colors.green.shade800;
    }
  }

  Widget _buildThumbnail(double size, double iconSize) {
    final color = _getHabitoColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          Icons.eco, // leaf analog
          color: color,
          size: iconSize,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(68, 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  especie.nombreCientifico,
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  especie.familia,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (especie.nombreLocal.isNotEmpty)
                  Text(
                    especie.nombreLocal,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          EstadoBadge(estado: especie.estado),
        ],
      ),
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
          especie.nombreCientifico,
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
                especie.nombreCientifico,
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

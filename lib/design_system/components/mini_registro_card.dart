import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/especie.dart';
import '../../core/constants/estado_registro.dart';

class MiniRegistroCard extends StatelessWidget {
  final Especie especie;
  final VoidCallback onTap;
  final Widget? badge;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const MiniRegistroCard({
    super.key, 
    required this.especie, 
    required this.onTap,
    this.badge,
    this.isSelected = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade300,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (especie.fotos.isNotEmpty && especie.fotos.first.url.isNotEmpty)
            especie.fotos.first.url.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: especie.fotos.first.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade300),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : Image.file(
                    File(especie.fotos.first.url),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                  )
          else
            const Icon(Icons.image_not_supported, color: Colors.grey),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
          
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                badge ?? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: especie.estado.color(context).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    especie.estado.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  especie.displayTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (especie.familia.isNotEmpty)
                  Text(
                    especie.familia,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (especie.nombreLocal.isNotEmpty)
                  Text(
                    especie.nombreLocal,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              splashColor: Colors.black12,
              highlightColor: Colors.black12,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../data/models/foto.dart';
import '../../../core/constants/rol.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/utils/image_watermark_util.dart';

/// CS-07: visor de fotos con zoom (pinch + doble tap) y swipe entre fotos.
/// Espejo de `VisorFotoView` (iOS).
class VisorFotoScreen extends ConsumerStatefulWidget {
  const VisorFotoScreen({
    super.key,
    required this.fotos,
    this.indiceInicial = 0,
    required this.autorRegistro,
  });

  final List<Foto> fotos;
  final int indiceInicial;
  final String autorRegistro;

  @override
  ConsumerState<VisorFotoScreen> createState() => _VisorFotoScreenState();
}

class _VisorFotoScreenState extends ConsumerState<VisorFotoScreen> {
  late final PageController _controller;
  late int _indice;

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial.clamp(0, widget.fotos.length - 1);
    _controller = PageController(initialPage: _indice);
  }

  bool _descargando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _descargarFoto() async {
    setState(() => _descargando = true);
    try {
      final url = widget.fotos[_indice].url;
      final autor = widget.autorRegistro.isEmpty ? 'Desconocido' : widget.autorRegistro;
      await WatermarkService.descargarConMarcaAgua(url, autor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto guardada en la galería con éxito.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _descargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esConsultor = ref.watch(sessionProvider).usuario?.rol == Rol.consultor;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _controller,
            itemCount: widget.fotos.length,
            onPageChanged: (i) => setState(() => _indice = i),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (_, __) => const Center(child: CircularProgressIndicator()),
            builder: (context, i) => PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(widget.fotos[i].url),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              heroAttributes: PhotoViewHeroAttributes(tag: widget.fotos[i].id),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón de descarga solo para Consultor
                  if (esConsultor)
                    _descargando
                        ? Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.4),
                            ),
                            icon: const Icon(Icons.download, color: Colors.white),
                            onPressed: _descargarFoto,
                          )
                  else
                    const SizedBox.shrink(),

                  // Botón de cerrar
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.4),
                    ),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          // Indicador de página y tipo de foto.
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Column(
              children: [
                Text(
                  widget.fotos[_indice].tipo.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.fotos.length; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: i == _indice ? 1 : 0.4),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

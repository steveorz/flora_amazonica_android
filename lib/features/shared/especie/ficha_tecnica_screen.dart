import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/color_promedio.dart';
import '../../../core/utils/dasometria.dart';
import '../../../data/models/especie.dart';
import '../../../data/models/foto.dart';
import '../favoritos/favoritos_store.dart';
import 'galeria_fotos_screen.dart';
import 'mapa_distribucion.dart';
import 'visor_foto_screen.dart';

enum FichaTab {
  nombreLocal('Nombre local'),
  morfologia('Morfología'),
  ecologia('Ecología'),
  mapa('Mapa'),
  galeria('Galería');

  final String label;
  const FichaTab(this.label);
}

/// CS-05: ficha técnica pública de una especie.
///
/// Estilo Apple Music / News+: la foto principal se duplica como fondo
/// full-screen desenfocado. La copia clara arriba se enmascara con un gradiente
/// en el borde inferior para revelar el fondo (que es la misma foto difuminada).
/// Como ambas capas son la misma imagen alineadas, el resultado es una sola
/// pantalla unificada. Espejo de `FichaTecnicaView` (iOS).
class FichaTecnicaScreen extends ConsumerStatefulWidget {
  const FichaTecnicaScreen({super.key, required this.especie});

  final Especie especie;

  @override
  ConsumerState<FichaTecnicaScreen> createState() => _FichaTecnicaScreenState();
}

class _FichaTecnicaScreenState extends ConsumerState<FichaTecnicaScreen> {
  static const _alturaHero = 540.0;

  FichaTab _tab = FichaTab.nombreLocal;
  ColoresAdaptativos _colores = ColoresAdaptativos.porDefecto;

  /// La foto de la planta completa es la portada; si no hay, la primera.
  Foto? get _heroFoto {
    for (final f in widget.especie.fotos) {
      if (f.tipo == TipoFoto.plantaCompleta) return f;
    }
    return widget.especie.fotos.isNotEmpty ? widget.especie.fotos.first : null;
  }

  String get _titulo => widget.especie.nombreCientifico;

  @override
  void initState() {
    super.initState();
    _detectarColores();
  }

  /// Adapta el color de los textos del bloque de info a la foto del hero.
  Future<void> _detectarColores() async {
    final foto = _heroFoto;
    if (foto == null) return;
    try {
      final bytes = await _bytesDeImagen(foto.url);
      if (bytes == null) return;
      final colores = await coloresDesdeImagen(bytes);
      if (colores != null && mounted) setState(() => _colores = colores);
    } catch (_) {
      // Silencioso: quedan los colores por defecto, como en iOS.
    }
  }

  /// Índice del hero dentro de la galería, para abrir el visor en la foto correcta.
  int get _indiceHero {
    final foto = _heroFoto;
    if (foto == null) return 0;
    final i = widget.especie.fotos.indexOf(foto);
    return i < 0 ? 0 : i;
  }

  void _abrirVisor(int i) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => VisorFotoScreen(
        fotos: widget.especie.fotos,
        indiceInicial: i,
        autorRegistro: widget.especie.autorNombre,
      ),
      fullscreenDialog: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final esFavorito = ref.watch(favoritosProvider).contains(widget.especie.id);
    final foto = _heroFoto;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
                child: const BackButton(),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: Icon(esFavorito ? Icons.favorite : Icons.favorite_border,
                        color: esFavorito ? Colors.red : Theme.of(context).colorScheme.onSurface),
                    onPressed: () => ref.read(favoritosProvider.notifier).toggle(widget.especie.id),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _FondoAmbiental(especie: widget.especie, foto: foto),
          SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (foto != null) _Hero(foto: foto, onTap: () => _abrirVisor(_indiceHero)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: _Info(
                    especie: widget.especie,
                    titulo: _titulo,
                    colores: _colores,
                  ),
                ),
                const SizedBox(height: 26),
                _SelectorTabs(actual: _tab, onCambio: (t) => setState(() => _tab = t)),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                  child: _contenidoTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenidoTab() {
    final e = widget.especie;
    return switch (_tab) {
      FichaTab.nombreLocal => _SeccionVidrio(
          titulo: 'Nombre local',
          child: Text(e.nombreLocal.isEmpty ? 'Sin nombre local registrado.' : e.nombreLocal),
        ),
      FichaTab.morfologia => _TabMorfologia(especie: e),
      FichaTab.ecologia => _SeccionVidrio(
          titulo: 'Hábitat y distribución',
          child: _Filas(filas: [
            ('Hábitat', e.ubicacion.tipoHabitat),
            ('Altitud', '${e.ubicacion.altitud.round()} m'),
            ('Tipo de vida', e.tipoVida.label),
            ('Distribución', e.distribucionPaises.join(', ')),
          ]),
        ),
      FichaTab.mapa => _TabMapa(especie: e),
      FichaTab.galeria => _TabGaleria(especie: e, onFoto: _abrirVisor),
    };
  }
}

/// Obtiene los bytes de una imagen ya resuelta por `CachedNetworkImage`,
/// para no descargar la foto una segunda vez sólo para promediar su color.
Future<Uint8List?> _bytesDeImagen(String url) {
  final stream = CachedNetworkImageProvider(url).resolve(ImageConfiguration.empty);
  final completer = Completer<Uint8List?>();
  late final ImageStreamListener listener;

  listener = ImageStreamListener(
    (info, _) async {
      final data = await info.image.toByteData(format: ImageByteFormat.png);
      if (!completer.isCompleted) completer.complete(data?.buffer.asUint8List());
      stream.removeListener(listener);
    },
    onError: (_, __) {
      if (!completer.isCompleted) completer.complete(null);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

/// La misma foto, a pantalla completa y muy desenfocada: es la base de color
/// de toda la pantalla.
class _FondoAmbiental extends StatelessWidget {
  const _FondoAmbiental({required this.especie, required this.foto});

  final Especie especie;
  final Foto? foto;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base de color de hábito: sólo se ve si no hay foto.
        ColoredBox(color: especie.habito.color.withValues(alpha: 0.55)),
        if (foto != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60, tileMode: TileMode.decal),
            child: CachedNetworkImage(
              imageUrl: foto!.url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}

/// La foto nítida, enmascarada abajo para fundirse con el fondo ambiental.
class _Hero extends StatelessWidget {
  const _Hero({required this.foto, required this.onTap});

  final Foto foto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Opaca hasta el 70%; a partir de ahí se desvanece.
          stops: [0.0, 0.70, 1.0],
          colors: [Colors.black, Colors.black, Colors.transparent],
        ).createShader(rect),
        child: SizedBox(
          height: _FichaTecnicaScreenState._alturaHero,
          width: double.infinity,
          child: Hero(
            tag: foto.id,
            child: CachedNetworkImage(
              imageUrl: foto.url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.especie, required this.titulo, required this.colores});

  final Especie especie;
  final String titulo;
  final ColoresAdaptativos colores;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(especie.familia,
            style: TextStyle(
                color: colores.secundario, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 10),
        Text(
          titulo,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colores.primario, fontSize: 32, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (especie.autorNombre.trim().isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.eco, size: 14, color: colores.secundario),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  especie.autorNombre.trim(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colores.secundario, fontSize: 14, height: 1.3, fontWeight: FontWeight.w300),
                ),
              ),
            ]
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _Meta(etiqueta: 'HÁBITO', valor: especie.habito.label, colores: colores),
            _Divisor(colores: colores),
            _Meta(
                etiqueta: 'ALTITUD',
                valor: '${especie.ubicacion.altitud.round()} m',
                colores: colores),
            _Divisor(colores: colores),
            _Meta(etiqueta: 'VIDA', valor: especie.tipoVida.label, colores: colores),
          ],
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.etiqueta, required this.valor, required this.colores});

  final String etiqueta;
  final String valor;
  final ColoresAdaptativos colores;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(etiqueta,
              style: TextStyle(
                color: colores.secundario,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 4),
          Text(valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: colores.primario, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor({required this.colores});
  final ColoresAdaptativos colores;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: colores.primario.withValues(alpha: 0.25),
    );
  }
}

class _SelectorTabs extends StatelessWidget {
  const _SelectorTabs({required this.actual, required this.onCambio});

  final FichaTab actual;
  final ValueChanged<FichaTab> onCambio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final t in FichaTab.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onCambio(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: t == actual
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    t.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: t == actual
                          ? theme.colorScheme.surface
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta translúcida: el equivalente de `.ultraThinMaterial` de iOS.
class _SeccionVidrio extends StatelessWidget {
  const _SeccionVidrio({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: theme.colorScheme.surface.withValues(alpha: 0.65),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo, 
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Filas extends StatelessWidget {
  const _Filas({required this.filas});
  final List<(String, String)> filas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (etiqueta, valor) in filas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(etiqueta,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(valor.isEmpty ? '—' : valor,
                      textAlign: TextAlign.right, 
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TabMorfologia extends StatelessWidget {
  const _TabMorfologia({required this.especie});
  final Especie especie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = especie.datosDasometricos;
    final caracteres = especie.caracteres.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: [
        if (d != null)
          _SeccionVidrio(
            titulo: 'Datos dasométricos',
            child: _Filas(filas: [
              ('Altura', '${Dasometria.formato(d.altura)} m'),
              ('CAP', '${Dasometria.formato(d.cap)} cm'),
              ('DAP', '${Dasometria.formato(d.dap)} cm'),
              (
                'Diám. copa',
                '${Dasometria.formato(d.diamCopaParalelo)} × '
                    '${Dasometria.formato(d.diamCopaPerpendicular)} m'
              ),
            ]),
          ),
        if (d != null && caracteres.isNotEmpty) const SizedBox(height: 12),
        if (caracteres.isNotEmpty)
          _SeccionVidrio(
            titulo: 'Caracteres',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in caracteres)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key.isEmpty ? e.key : e.key[0].toUpperCase() + e.key.substring(1),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(e.value, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TabMapa extends StatelessWidget {
  const _TabMapa({required this.especie});
  final Especie especie;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 320,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: MapaDistribucion(especie: especie),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.open_in_full),
          label: const Text('Ver mapa completo'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Distribución')),
                body: MapaDistribucion(especie: especie, pantallaCompleta: true),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabGaleria extends StatelessWidget {
  const _TabGaleria({required this.especie, required this.onFoto});

  final Especie especie;
  final ValueChanged<int> onFoto;

  @override
  Widget build(BuildContext context) {
    if (especie.fotos.isEmpty) {
      return const _SeccionVidrio(
        titulo: 'Galería',
        child: Text('Esta especie aún no tiene fotos.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: especie.fotos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final foto = especie.fotos[i];
              return GestureDetector(
                onTap: () => onFoto(i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: foto.url,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox(width: 140, height: 140),
                      ),
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(foto.tipo.label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Ver galería completa'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => GaleriaFotosScreen(especie: especie)),
          ),
        ),
      ],
    );
  }
}

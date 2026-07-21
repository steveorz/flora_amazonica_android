import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/estado_registro.dart';
import '../../core/constants/habito.dart';
import '../../core/services/especie_service.dart';
import '../../data/models/especie.dart';
import '../../data/models/foto.dart';
import '../shared/profile_screen.dart';
import 'consultor_shell.dart';
import 'favoritos_screen.dart';
import '../shared/morfologia/morfologica_search_screen.dart';
import '../shared/catalogo_screen.dart';
import '../shared/especie/ficha_tecnica_screen.dart';
import '../../design_system/components/app_chips.dart';
import '../../design_system/components/empty_state.dart';
import '../../design_system/components/species_card.dart';
import '../../design_system/components/mini_registro_card.dart';

/// CS-01: home del consultor. Espejo de `HomeConsultorView` (iOS).
class HomeConsultorScreen extends ConsumerStatefulWidget {
  const HomeConsultorScreen({super.key});

  @override
  ConsumerState<HomeConsultorScreen> createState() => _HomeConsultorScreenState();
}

class _HomeConsultorScreenState extends ConsumerState<HomeConsultorScreen> {
  static const _alturaNovedad = 540.0;
  static const _maxNovedades = 10;
  
  late PageController _pageController;
  Timer? _timer;
  int _currentPageReal = 0;

  final _busquedaController = TextEditingController();
  final _busquedaFocus = FocusNode();
  bool _isGridBusqueda = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 10000);
    _iniciarAutoPlay();
    _busquedaFocus.addListener(() => setState(() {}));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(especieServiceProvider).especies.isEmpty) {
        ref.read(especieServiceProvider.notifier).cargar();
      }
    });
  }

  void _iniciarAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _busquedaFocus.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  bool get _isSearching => _busquedaController.text.isNotEmpty;

  List<Especie> _resultadosBusqueda(List<Especie> todas) {
    final q = _busquedaController.text.toLowerCase();
    if (q.isEmpty) return const [];
    return todas
        .where((e) => e.estado == EstadoRegistro.validado)
        .where((e) =>
            e.nombreCientifico.toLowerCase().contains(q) ||
            e.nombreLocal.toLowerCase().contains(q) ||
            e.familia.toLowerCase().contains(q))
        .toList();
  }

  /// Sólo registros de campo validados: las entradas del catálogo
  /// puro (las que no tienen registrador o están marcadas) se listan abajo en "Plantas".
  List<Especie> _registrosRecientes(List<Especie> todas) {
    return todas
        .where((e) =>
          e.estado == EstadoRegistro.validado &&
          e.catalogId == null)
      .toList();
  }

  void _abrirFicha(Especie e) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => FichaTecnicaScreen(especie: e)),
      );

  void _abrirCatalogo({String? familia, Habito? habito}) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CatalogoScreen(filtroFamilia: familia, filtroHabito: habito),
        ),
      );



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todas = ref.watch(especieServiceProvider).especies;
    final publicadas = _registrosRecientes(todas);

    final novedades = [...publicadas]
      ..sort((a, b) => b.fechaEnvio.compareTo(a.fechaEnvio));
    final familias = publicadas.map((e) => e.familia).toSet().toList()..sort();

    return Scaffold(
      // El carrusel va full-bleed detrás de la barra de estado; el botón de
      // perfil flota encima, como la toolbar transparente de iOS.
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              SizedBox(
                height: _alturaNovedad + 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: _alturaNovedad,
                      child: novedades.isEmpty 
                        ? const Center(child: CircularProgressIndicator()) 
                        : Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                onPageChanged: (idx) {
                                  setState(() {
                                    _currentPageReal = idx % novedades.take(_maxNovedades).length;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final limitedNovedades = novedades.take(_maxNovedades).toList();
                                  if (limitedNovedades.isEmpty) return const SizedBox();
                                  final realIndex = index % limitedNovedades.length;
                                  final e = limitedNovedades[realIndex];
                                  return GestureDetector(
                                    onTap: () => _abrirFicha(e),
                                    child: _TarjetaNovedad(especie: e),
                                  );
                                },
                              ),
                              // Indicadores (dots)
                              if (novedades.isNotEmpty)
                                Positioned(
                                  bottom: 32, // Bajamos los puntitos justo sobre el buscador
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      novedades.take(_maxNovedades).length,
                                      (i) => AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        height: 6,
                                        width: _currentPageReal == i ? 20 : 6,
                                        decoration: BoxDecoration(
                                          color: _currentPageReal == i 
                                              ? Colors.white 
                                              : Colors.white.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                    ),
                  // Buscador superpuesto en la separación (Glassmorphism)
                  Positioned(
                    bottom: 0, // Está dentro del SizedBox de _alturaNovedad + 24
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                          child: Container(
                            color: theme.cardColor.withValues(alpha: 0.85),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              child: TextField(
                                controller: _busquedaController,
                                focusNode: _busquedaFocus,
                                onChanged: (_) => setState(() {}),
                                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  filled: false,
                                  hintText: 'Nombre científico, común o familia...',
                                  hintStyle: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                    fontSize: 15,
                                  ),
                                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: false,
                                  contentPadding: EdgeInsets.zero,
                                  suffixIcon: _isSearching
                                      ? IconButton(
                                          icon: const Icon(Icons.close, size: 20),
                                          color: theme.colorScheme.onSurfaceVariant,
                                          onPressed: () {
                                            _busquedaController.clear();
                                            _busquedaFocus.unfocus();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSearching ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            secondChild: _buildResultadosView(todas),
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TarjetaMorfologica(
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MorfologicaSearchScreen(),
                        fullscreenDialog: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Explorar por familia',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      )),
                ),
                const SizedBox(height: 8),
                AppChips<String>(
                  items: familias,
                  selection: const {},
                  labelFor: (f) => f,
                  onChanged: (nuevos) {
                    if (nuevos.isNotEmpty) {
                      _abrirCatalogo(familia: nuevos.first);
                    }
                  },
                  scrollable: true,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Explorar por hábitos',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      )),
                ),
                const SizedBox(height: 8),
                for (final h in Habito.values)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: GestureDetector(
                      onTap: () => _abrirCatalogo(habito: h),
                      child: _TarjetaCategoria(habito: h),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildResultadosView(List<Especie> todas) {
    if (_busquedaController.text.isEmpty) {
      return const SizedBox(height: 100);
    }
    
    final resultados = _resultadosBusqueda(todas);
    if (resultados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: EmptyState(
          systemImage: Icons.search_off,
          title: 'Nada coincide',
          message: 'Prueba con otro nombre, familia o nombre común.',
        ),
      );
    }

    final theme = Theme.of(context);
    final oscuro = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 40),
      child: Material(
        color: oscuro
            ? Color.lerp(const Color(0xFF121212), Colors.white, 0.08)
            : Color.lerp(const Color(0xFFF0F2F5), Colors.white, 0.50),
        borderRadius: BorderRadius.circular(24),
        elevation: 0.5,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(resultados.length, (i) {
            final e = resultados[i];
            return Column(
              children: [
                InkWell(
                  onTap: () => _abrirFicha(e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: SpeciesCard(
                      especie: e,
                      trailing: const SizedBox.shrink(),
                    ),
                  ),
                ),
                if (i < resultados.length - 1)
                  const Divider(indent: 96, height: 1, thickness: 0.5),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _TarjetaNovedad extends StatelessWidget {
  const _TarjetaNovedad({required this.especie});

  final Especie especie;

  /// La portada de la novedad es la foto de planta completa, si existe.
  Foto? get _portada {
    for (final f in especie.fotos) {
      if (f.tipo == TipoFoto.plantaCompleta) return f;
    }
    return especie.fotos.isNotEmpty ? especie.fotos.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final foto = _portada;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (foto != null)
          CachedNetworkImage(
            imageUrl: foto.url,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _Fallback(especie: especie),
            placeholder: (_, __) => _Fallback(especie: especie),
          )
        else
          _Fallback(especie: especie),
        // Scrim para que el texto sea legible sobre la foto.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
            ),
          ),
        ),
        // Gradient Blur para difuminar la base
        Positioned(
          bottom: -1,
          left: 0,
          right: 0,
          height: 180, // Área de transición más grande para un difuminado suave
          child: ClipRect(
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.0, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 52), // Más espacio debajo para los dots
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('RECIÉN AÑADIDA',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    )),
                const SizedBox(height: 5),
                Text(
                  especie.nombreCientifico,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${especie.familia} · ${especie.habito.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.especie});
  final Especie especie;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: especie.habito.color.withValues(alpha: 0.35),
      child: Center(child: Icon(Icons.eco, size: 44, color: especie.habito.color)),
    );
  }
}

class _TarjetaMorfologica extends StatelessWidget {
  const _TarjetaMorfologica({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          // La imagen dicta el tamaño del Card automáticamente
          Image.asset(
            'assets/images/morfologica_bg.jpeg',
            width: double.infinity,
            fit: BoxFit.contain, // Esto hace que respete el tamaño/proporción de la imagen original
          ),
          // Sombra suave para que el texto sea legible
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Búsqueda morfológica',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Identifica plantas por sus características visuales',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
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

class _TarjetaCategoria extends StatelessWidget {
  const _TarjetaCategoria({required this.habito});
  final Habito habito;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(habito.categoryAsset, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  habito.label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/especie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';
import '../../core/services/especie_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/estado_registro.dart';
import '../../core/storage/draft_storage.dart';
import '../../design_system/components/mini_registro_card.dart';
import '../../design_system/components/species_card.dart';
import '../shared/profile_screen.dart';
import 'detalle_registro_screen.dart';
import 'mis_registros_screen.dart';
import 'registrador_shell.dart';
import 'wizard/nuevo_registro_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(especieServiceProvider).especies.isEmpty) {
        ref.read(especieServiceProvider.notifier).cargar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final usuario = session.usuario;
    // Derivado del estado observado: `ref.read` no reconstruiría al llegar
    // especies nuevas.
    final registrosBackend = ref
        .watch(especieServiceProvider)
        .especies
        .where((e) => e.registradorId == (usuario?.id ?? ''))
        .toList();
        
    final borradoresLocales = DraftStorage.loadAll().map((d) => d.toEspecie()).toList();
    
    final misRegistros = [...borradoresLocales, ...registrosBackend];
    // Ordenar los más recientes primero
    misRegistros.sort((a, b) => b.fechaEnvio.compareTo(a.fechaEnvio));
    
    // Contar estados
    int validadoCount = 0;
    int revisionCount = 0;
    int observadoCount = 0;
    int borradorCount = borradoresLocales.length; // Los del backend raramente son borradores puros, pero igual sumamos
    for (var r in registrosBackend) {
      if (r.estado == EstadoRegistro.validado) validadoCount++;
      else if (r.estado == EstadoRegistro.enRevision) revisionCount++;
      else if (r.estado == EstadoRegistro.observado) observadoCount++;
      else if (r.estado == EstadoRegistro.borrador) borradorCount++;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeGreen = isDark ? const Color(0xFF74C69D) : AppColors.primary;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(especieServiceProvider.notifier).cargar();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0), // Extra top padding to avoid floating profile button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hola, ${usuario?.nombres ?? 'Investigador'}",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: activeGreen),
              ),
              const SizedBox(height: 4),
              const Text(
                "Documenta una nueva especie del bosque.",
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 22),
              
              // Crear Card (Wizard)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NuevoRegistroScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/wizard_bg.jpg'),
                        fit: BoxFit.cover,
                      ),
                      color: const Color(0xFF63B896), // Fallback green
                    ),
                    child: Stack(
                      children: [
                         Positioned.fill(
                           child: DecoratedBox(
                             decoration: BoxDecoration(
                               gradient: LinearGradient(
                                 colors: [
                                   Colors.black.withOpacity(0.15), // Sutil velo oscuro arriba
                                   Colors.black.withOpacity(0.85)  // Oscuridad pronunciada abajo
                                 ],
                                 begin: Alignment.topCenter,
                                 end: Alignment.bottomCenter,
                                 stops: const [0.2, 1.0],
                               ),
                             ),
                           ),
                         ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                "Crear nuevo registro", 
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontSize: 28, 
                                  fontWeight: FontWeight.w800,
                                )
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Wizard de 7 pasos con guardado automático.", 
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95), 
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                )
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 22),
              Text("Resumen", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: activeGreen)),
              const SizedBox(height: 8),
              
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _statCard(context, "En revisión", revisionCount, EstadoRegistro.enRevision.color(context), "assets/images/en_revision.png", () {
                        _abrirMisRegistros(EstadoRegistro.enRevision);
                      })),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard(context, "Observados", observadoCount, EstadoRegistro.observado.color(context), "assets/images/observados.png", () {
                        _abrirMisRegistros(EstadoRegistro.observado);
                      })),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _statCard(context, "Validados", validadoCount, EstadoRegistro.validado.color(context), "assets/images/validados.png", () {
                        _abrirMisRegistros(EstadoRegistro.validado);
                      })),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard(context, "Borradores", borradorCount, EstadoRegistro.borrador.color(context), "assets/images/borradores.png", () {
                        _abrirMisRegistros(EstadoRegistro.borrador);
                      })),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Tus últimos registros", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: activeGreen)),
                  if (misRegistros.length > 6)
                    TextButton(
                      onPressed: () => _abrirMisRegistros(null),
                      child: Text(
                        "Ver todo",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF63B896) // Verde claro y brillante para modo oscuro
                              : AppColors.primary, // Verde bosque para modo claro
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (misRegistros.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18.0),
                  child: Text("Aún no tienes registros.", style: TextStyle(color: Colors.grey, fontSize: 15)),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 4 / 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: misRegistros.length > 6 ? 6 : misRegistros.length,
                  itemBuilder: (context, index) {
                    final e = misRegistros[index];
                    return MiniRegistroCard(
                      especie: e, 
                      onTap: () {
                        if (e.estado == EstadoRegistro.borrador && DraftStorage.get(e.id) != null) {
                          // Si es borrador local, abrir el wizard para editar
                          final draftLocal = DraftStorage.get(e.id);
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute<void>(
                              builder: (_) => NuevoRegistroScreen(
                                draft: draftLocal,
                                especieAEditar: draftLocal == null ? e : null,
                              ),
                              fullscreenDialog: true,
                            ),
                          ).then((_) {
                            // Al volver, refrescamos la UI por si hubo cambios en el borrador
                            setState(() {});
                          });
                        } else {
                          // Registro real, abrir detalles
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DetalleRegistroScreen(especie: e),
                            ),
                          );
                        }
                      }
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Abre "Mis registros" ya filtrado por el estado tocado en el resumen.
  void _abrirMisRegistros(EstadoRegistro? filtro) {
    RegistradorShell.of(context).cambiarTab(1, filtro: filtro);
  }

  Widget _statCard(BuildContext context, String title, int value, Color color, String imagePath, VoidCallback onTap) {
    final hsl = HSLColor.fromColor(color);
    final darkColor = hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.4),
            ],
            stops: const [0.4, 0.85],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$value",
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.w800, 
                      color: darkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13, 
                      color: Colors.white, 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

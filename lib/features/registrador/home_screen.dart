import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';
import '../../core/services/especie_service.dart';
import '../../data/models/especie.dart';
import '../../design_system/components/species_card.dart';
import '../../design_system/theme/brand_colors.dart';
import '../../design_system/components/profile_avatar_view.dart';
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
      final especies = ref.read(especieServiceProvider);
      if (especies.isEmpty) {
        ref.read(especieServiceProvider.notifier).cargar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(sessionProvider);
    final especies = ref.watch(especieServiceProvider);
    final misRegistros = ref.read(especieServiceProvider.notifier).registrosDe(usuario?.id ?? '');
    
    // Contar estados
    int validadoCount = 0;
    int revisionCount = 0;
    int observadoCount = 0;
    for (var r in misRegistros) {
      if (r.estado == EstadoRegistro.validado) validadoCount++;
      else if (r.estado == EstadoRegistro.enRevision) revisionCount++;
      else if (r.estado == EstadoRegistro.observado) observadoCount++;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
        actions: [
          if (usuario != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ProfileAvatarView(user: usuario, size: 32),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(especieServiceProvider.notifier).cargar();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hola, ${usuario?.nombres ?? 'Investigador'}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                "Documenta una nueva especie del bosque.",
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 22),
              
              // Crear Card (Wizard)
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NuevoRegistroScreen(),
                      fullscreenDialog: true,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 230,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [Colors.green.shade800, Colors.black87],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Placeholder for Image("fondo_crear_registro")
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Colors.transparent, Colors.black54],
                              begin: Alignment.center,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text("Comenzar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text("Crear nuevo registro", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text("Wizard de 7 pasos con guardado automático.", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 22),
              const Text("Resumen", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: [
                  _statCard("En revisión", revisionCount, BrandColors.estadoEnRevision),
                  _statCard("Observados", observadoCount, BrandColors.estadoObservado),
                  _statCard("Validados", validadoCount, BrandColors.estadoValidado),
                  _statCard("Borradores", 0, Colors.grey),
                ],
              ),
              
              const SizedBox(height: 22),
              const Text("Tus últimos registros", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              if (misRegistros.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18.0),
                  child: Text("Aún no tienes registros.", style: TextStyle(color: Colors.grey, fontSize: 15)),
                )
              else
                Column(
                  children: misRegistros.take(4).map((e) {
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SpeciesCard(especie: e, variant: SpeciesCardVariant.lista),
                          ),
                        ),
                        if (e != misRegistros.take(4).last)
                          const Divider(),
                      ],
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$value",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

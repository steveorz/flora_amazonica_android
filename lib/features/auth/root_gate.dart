import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/rol.dart';
import '../../core/services/especie_service.dart';
import '../../core/services/notificacion_service.dart';
import '../../core/session/session_provider.dart';
import '../admin/admin_shell.dart';
import '../consultor/consultor_shell.dart';
import '../registrador/registrador_shell.dart';
import 'loading_screen.dart';

/// Espejo del bloque `datosPreparados` de `RootView` (iOS).
///
/// Tras el login mantiene el splash mientras se traen las especies y se
/// precalientan las portadas, para que el home aparezca completo y no se vean
/// fotos cargando. Luego elige el shell según el rol.
class RootGate extends ConsumerStatefulWidget {
  const RootGate({super.key});

  @override
  ConsumerState<RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<RootGate> {
  static const _duracionMinima = Duration(milliseconds: 900);

  bool _datosPreparados = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _prepararDatos();
    });
  }

  Future<void> _prepararDatos() async {
    final inicio = DateTime.now();

    final especies = ref.read(especieServiceProvider.notifier);
    if (ref.read(especieServiceProvider).especies.isEmpty) {
      await especies.cargar();
    }
    await _prefetchPortadas();

    // Las notificaciones alimentan el badge de la barra desde el primer frame.
    final usuarioId = ref.read(sessionProvider).usuario?.id;
    if (usuarioId != null && usuarioId.isNotEmpty) {
      await ref.read(notificacionServiceProvider.notifier).cargar(usuarioId);
    }

    final transcurrido = DateTime.now().difference(inicio);
    final restante = _duracionMinima - transcurrido;
    if (restante > Duration.zero) await Future<void>.delayed(restante);

    if (mounted) {
      setState(() => _datosPreparados = true);
    }
  }

  /// Precalienta las portadas en la caché de imágenes: al entrar al home ya
  /// están listas. Un timeout corto evita que una foto lenta bloquee la entrada.
  Future<void> _prefetchPortadas() async {
    final urls = ref
        .read(especieServiceProvider)
        .especies
        .map((e) => e.portadaUrl)
        .whereType<String>()
        .toSet();

    await Future.wait(
      urls.map((url) async {
        try {
          await precacheImage(NetworkImage(url), context)
              .timeout(const Duration(seconds: 8));
        } catch (_) {
          // Una portada que no llega no debe impedir entrar a la app.
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_datosPreparados) return const LoadingScreen();

    return switch (ref.watch(sessionProvider).rol) {
      Rol.registrador => const RegistradorShell(),
      Rol.consultor => const ConsultorShell(),
      Rol.administrador => const AdminShell(),
      // El validador nunca llega aquí: el router lo manda a /validador.
      Rol.validador || null => const LoadingScreen(),
    };
  }
}

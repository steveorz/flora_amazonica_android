import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Motor único de reproducción para todo el flujo de auth.
///
/// Espejo de `VideoFondoMotor` (iOS, Features/Auth/FondoVideoAuth.swift).
/// Existe un solo par de controllers que **todas** las pantallas comparten:
/// así el fotograma es idéntico en splash, login, registro y recuperación, y la
/// transición entre pantallas se ve perfectamente continua.
///
/// Un segundo antes del final del clip comienza el fundido cruzado al siguiente.
class VideoFondoMotor with WidgetsBindingObserver {
  VideoFondoMotor._();
  static final VideoFondoMotor compartido = VideoFondoMotor._();

  static const _nombres = [
    'assets/videos/login_fondo_1.mp4',
    'assets/videos/login_fondo_2.mp4',
  ];

  /// Duración del fundido cruzado entre clips.
  static const Duration fundido = Duration(milliseconds: 1000);

  final List<VideoPlayerController> _players = [];
  List<VideoPlayerController> get players => List.unmodifiable(_players);

  /// Índice del clip visible. Las vistas escuchan esto para cruzar sus capas
  /// todas a la vez (equivale a la Notification `clipCambio` de iOS).
  final ValueNotifier<int> actual = ValueNotifier(0);

  /// Se completa cuando los clips están listos para pintarse.
  Future<void>? _preparacion;

  bool _cambiando = false;

  /// Carga los clips una sola vez; llamadas posteriores devuelven el mismo Future.
  Future<void> preparar() {
    return _preparacion ??= _prepararUnaVez();
  }

  Future<void> _prepararUnaVez() async {
    WidgetsBinding.instance.addObserver(this);

    for (final nombre in _nombres) {
      final player = VideoPlayerController.asset(nombre);
      try {
        await player.initialize();
      } catch (_) {
        // Un clip que no carga no debe dejar la pantalla en negro: seguimos
        // con los que sí cargaron (con uno solo, el motor simplemente repite).
        await player.dispose();
        continue;
      }
      await player.setVolume(0);
      // No usamos setLooping: el salto al siguiente clip lo controlamos
      // nosotros para poder cruzar el fundido justo antes del final.
      player.addListener(() => _vigilarFinDeClip(player));
      _players.add(player);
    }

    if (_players.isNotEmpty) {
      actual.value = 0;
      await _players.first.play();
    }
  }

  /// Dispara el cambio cuando falta `fundido` para terminar el clip visible.
  void _vigilarFinDeClip(VideoPlayerController player) {
    if (_players.isEmpty || _cambiando) return;
    if (player != _players[actual.value]) return;

    final value = player.value;
    if (!value.isInitialized || !value.isPlaying) return;

    final restante = value.duration - value.position;
    if (restante <= fundido && restante > Duration.zero) {
      _pasarAlSiguienteClip();
    }
  }

  Future<void> _pasarAlSiguienteClip() async {
    if (_cambiando) return;
    _cambiando = true;

    // Con un solo clip disponible, simplemente se repite.
    if (_players.length < 2) {
      await _players.first.seekTo(Duration.zero);
      await _players.first.play();
      _cambiando = false;
      return;
    }

    final anterior = actual.value;
    final siguiente = (anterior + 1) % _players.length;

    await _players[siguiente].seekTo(Duration.zero);
    await _players[siguiente].play();

    // Todas las vistas conectadas cruzan sus capas a la vez.
    actual.value = siguiente;

    // Terminado el fundido, el clip anterior queda pausado y listo desde cero.
    await Future<void>.delayed(fundido + const Duration(milliseconds: 100));
    if (actual.value == siguiente) {
      await _players[anterior].pause();
      await _players[anterior].seekTo(Duration.zero);
    }
    _cambiando = false;
  }

  /// Android pausa el video al pasar a segundo plano; se reanuda al volver.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) reanudar();
  }

  void reanudar() {
    if (_players.isEmpty) return;
    final player = _players[actual.value];
    if (player.value.isInitialized && !player.value.isPlaying) player.play();
  }

  /// Sólo al cerrar la app: el motor vive tanto como el flujo de auth.
  Future<void> liberar() async {
    WidgetsBinding.instance.removeObserver(this);
    for (final p in _players) {
      await p.dispose();
    }
    _players.clear();
    _preparacion = null;
  }
}

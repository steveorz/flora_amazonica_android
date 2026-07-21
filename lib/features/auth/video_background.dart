import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_fondo_motor.dart';

/// Vista de video conectada al motor compartido: cada pantalla tiene sus
/// propias capas, pero todas leen el mismo fotograma del motor.
///
/// Espejo de `VideoFondoAuth` / `VideoFondoUIView` (iOS).
class VideoFondoAuth extends StatefulWidget {
  const VideoFondoAuth({super.key});

  @override
  State<VideoFondoAuth> createState() => _VideoFondoAuthState();
}

class _VideoFondoAuthState extends State<VideoFondoAuth> {
  late final Future<void> _listo = VideoFondoMotor.compartido.preparar();

  @override
  Widget build(BuildContext context) {
    final motor = VideoFondoMotor.compartido;

    return FutureBuilder<void>(
      future: _listo,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || motor.players.isEmpty) {
          return const ColoredBox(color: Colors.black);
        }

        return ValueListenableBuilder<int>(
          valueListenable: motor.actual,
          builder: (context, actual, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                for (var i = 0; i < motor.players.length; i++)
                  // El fundido cruzado: la capa entrante sube a 1 mientras la
                  // saliente baja a 0, ambas en la misma ventana de tiempo.
                  AnimatedOpacity(
                    opacity: i == actual ? 1 : 0,
                    duration: VideoFondoMotor.fundido,
                    curve: Curves.easeInOut,
                    child: _VideoCubriendo(controller: motor.players[i]),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Equivale a `videoGravity = .resizeAspectFill`: llena la pantalla recortando
/// lo que sobre, sin deformar el video.
class _VideoCubriendo extends StatelessWidget {
  const _VideoCubriendo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

/// Filtro que unifica el look del video en todo el flujo de auth:
/// tinte verde selva (más denso arriba y abajo) y viñeta hacia los bordes.
/// Espejo de `FiltroVideoAuth` (iOS).
class FiltroVideoAuth extends StatelessWidget {
  const FiltroVideoAuth({super.key});

  static const _verdeSuperior = Color(0xFF031A0F); // rgb(0.01, 0.10, 0.06)
  static const _verdeInferior = Color(0xFF001208); // rgb(0.00, 0.07, 0.04)

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.40, 1.0],
              colors: [
                _verdeSuperior.withValues(alpha: 0.55),
                _verdeSuperior.withValues(alpha: 0.12),
                _verdeInferior.withValues(alpha: 0.50),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              // iOS: startRadius 160 → endRadius 560 sobre la diagonal.
              stops: const [0.3, 1.0],
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.42)],
            ),
          ),
        ),
      ],
    );
  }
}

/// Fondo de las pantallas que derivan del login (registro, recuperación,
/// cuenta creada) y del splash: el mismo video —sincronizado por el motor
/// compartido— totalmente desenfocado, con el mismo filtro cinematográfico
/// y un velo extra de legibilidad.
///
/// Espejo de `FondoAuthDesenfocado` (iOS).
class FondoAuthDesenfocado extends StatelessWidget {
  const FondoAuthDesenfocado({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Colors.black),
        VideoFondoAuth(),
        // `.ultraThinMaterial` de iOS: desenfoque + una capa translúcida.
        _Desenfoque(sigma: 30),
        FiltroVideoAuth(),
        ColoredBox(color: Color(0x1F000000)), // black.opacity(0.12)
      ],
    );
  }
}

/// Fondo del login: el video nítido, sólo con el filtro cinematográfico.
/// Espejo de la composición de `LoginView`.
class FondoAuthNitido extends StatelessWidget {
  const FondoAuthNitido({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Colors.black),
        VideoFondoAuth(),
        _FiltroBlurGradual(),
        FiltroVideoAuth(),
      ],
    );
  }
}

class _FiltroBlurGradual extends StatelessWidget {
  const _FiltroBlurGradual();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0.0),
          ],
          stops: const [0.0, 0.65], // Se desvanece un poco más arriba de la mitad
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35), // Blur mucho más pronunciado
          child: ColoredBox(color: Colors.black.withOpacity(0.4)), // Velo oscuro gradual que acompaña al blur
        ),
      ),
    );
  }
}

class _Desenfoque extends StatelessWidget {
  const _Desenfoque({required this.sigma});

  final double sigma;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: ColoredBox(color: Colors.white.withValues(alpha: 0.06)),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'video_background.dart';

/// Andamiaje compartido por las pantallas derivadas del login (registro,
/// recuperación, nueva contraseña, cuenta creada): el video desenfocado de
/// fondo, barra transparente y todo el contenido renderizado en oscuro para que
/// el vidrio y los textos sean legibles.
///
/// Equivale a la combinación `FondoAuthDesenfocado()` +
/// `.environment(\.colorScheme, .dark)` + `.toolbarColorScheme(.dark)` de iOS.
class AuthScaffoldOscuro extends StatelessWidget {
  const AuthScaffoldOscuro({
    super.key,
    required this.child,
    this.titulo,
    this.mostrarAtras = true,
  });

  final Widget child;
  final String? titulo;
  final bool mostrarAtras;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: mostrarAtras,
          foregroundColor: Colors.white,
          title: titulo != null ? Text(titulo!) : null,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const FondoAuthDesenfocado(),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}

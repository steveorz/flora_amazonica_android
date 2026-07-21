import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Colores de texto legibles sobre una foto, conservando su tinte.
/// Equivale al par `infoPrimary` / `infoSecondary` de `FichaTecnicaView` (iOS).
class ColoresAdaptativos {
  final Color primario;
  final Color secundario;

  const ColoresAdaptativos(this.primario, this.secundario);

  static const porDefecto = ColoresAdaptativos(Colors.white, Colors.white70);
}

/// Calcula el color promedio de la **mitad inferior** de una imagen y devuelve
/// un par de colores de texto legibles sobre ella.
///
/// Sólo se samplea la mitad inferior porque es la zona que queda detrás del
/// bloque de texto. Igual que iOS, se elige un tono casi blanco o casi negro
/// del mismo matiz del fondo: contrasta lo necesario sin romper la armonía.
///
/// La imagen se decodifica reducida (64 px de ancho) porque para un promedio
/// no hace falta más y así no se bloquea el hilo de UI.
Future<ColoresAdaptativos?> coloresDesdeImagen(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
    final frame = await codec.getNextFrame();
    final imagen = frame.image;

    final datos = await imagen.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (datos == null) return null;

    final ancho = imagen.width;
    final alto = imagen.height;
    final pixeles = datos.buffer.asUint8List();

    // Mitad inferior de la imagen tal como se ve en pantalla.
    final desdeFila = alto ~/ 2;

    var sumaR = 0, sumaG = 0, sumaB = 0, total = 0;
    for (var y = desdeFila; y < alto; y++) {
      for (var x = 0; x < ancho; x++) {
        final i = (y * ancho + x) * 4;
        // Ignora los píxeles casi transparentes: no aportan color real.
        if (pixeles[i + 3] < 8) continue;
        sumaR += pixeles[i];
        sumaG += pixeles[i + 1];
        sumaB += pixeles[i + 2];
        total++;
      }
    }
    imagen.dispose();
    if (total == 0) return null;

    final promedio = Color.fromARGB(255, sumaR ~/ total, sumaG ~/ total, sumaB ~/ total);
    return _coloresParaFondo(promedio);
  } catch (_) {
    // Silencioso: se quedan los colores por defecto, como en iOS.
    return null;
  }
}

/// Linealización sRGB de la fórmula de luminancia relativa del W3C.
double _linealizar(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

ColoresAdaptativos _coloresParaFondo(Color fondo) {
  final luminancia = 0.2126 * _linealizar(fondo.r) +
      0.7152 * _linealizar(fondo.g) +
      0.0722 * _linealizar(fondo.b);

  final hsl = HSLColor.fromColor(fondo);

  // Fondo oscuro → casi blanco; fondo claro → casi negro. En ambos casos se
  // conserva un rastro del matiz original.
  final primario = luminancia < 0.5
      ? HSLColor.fromAHSL(1, hsl.hue, math.min(hsl.saturation * 0.25, 0.10), 0.96).toColor()
      : HSLColor.fromAHSL(1, hsl.hue, math.min(hsl.saturation * 0.35, 0.20), 0.10).toColor();

  return ColoresAdaptativos(primario, primario.withValues(alpha: 0.72));
}

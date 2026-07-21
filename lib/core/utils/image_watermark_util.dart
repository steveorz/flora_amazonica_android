import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class WatermarkService {
  static const int _limiteDiario = 20;

  static Future<bool> puedeDescargar() async {
    final prefs = await SharedPreferences.getInstance();
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'descargas_$hoy';
    final conteo = prefs.getInt(key) ?? 0;
    return conteo < _limiteDiario;
  }

  static Future<void> incrementarDescarga() async {
    final prefs = await SharedPreferences.getInstance();
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'descargas_$hoy';
    final conteo = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, conteo + 1);
  }

  static Future<void> descargarConMarcaAgua(String url, String autor) async {
    if (!await puedeDescargar()) {
      throw Exception('Has alcanzado el límite diario de $_limiteDiario descargas.');
    }

    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        throw Exception('No se otorgaron permisos para guardar en la galería.');
      }
    }

    // Descargar imagen
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('Error al descargar la imagen original.');
    }

    // Decodificar imagen
    final codec = await ui.instantiateImageCodec(resp.bodyBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Preparar canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    
    // Dibujar imagen original
    canvas.drawImageRect(image, rect, rect, Paint());

    // Configurar texto de marca de agua
    final texto = '© $autor - FlorAmaz';
    final fontSize = (image.width * 0.04).clamp(16.0, 100.0);
    
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2)),
        Shadow(color: Colors.black, blurRadius: 10, offset: Offset(-2, -2)),
      ],
    );

    final textSpan = TextSpan(text: texto, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: image.width.toDouble() - 20);

    // Dibujar fondo semi transparente para el texto (opcional, para mayor legibilidad)
    final textX = image.width - textPainter.width - 20;
    final textY = image.height - textPainter.height - 20;

    final bgRect = Rect.fromLTWH(textX - 10, textY - 10, textPainter.width + 20, textPainter.height + 20);
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.4);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(8)), bgPaint);

    // Dibujar texto
    textPainter.paint(canvas, Offset(textX, textY));

    // Convertir de vuelta a imagen
    final picture = recorder.endRecording();
    final newImage = await picture.toImage(image.width, image.height);
    final byteData = await newImage.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // Guardar archivo temporal
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/floramaz_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(pngBytes);

    // Guardar en galería
    await Gal.putImage(tempFile.path, album: 'FlorAmaz');

    // Limpiar archivo temporal e incrementar
    await tempFile.delete();
    await incrementarDescarga();
  }
}

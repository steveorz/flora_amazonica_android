import 'dart:io';
import 'package:image/image.dart';

void main() {
  final image = decodeImage(File('assets/images/logo_floramaz.png').readAsBytesSync())!;
  // We want to add about 40% padding around it.
  // Current max dimension is ~1024.
  // New dimension: 1800x1800.
  final newSize = 1800;
  final padded = Image(width: newSize, height: newSize);
  
  // padded is automatically initialized to 0 (transparent) in image package 4.x?
  // Wait, in image 4.x, we should fill it with transparent color just to be sure.
  fill(padded, color: ColorRgba8(0, 0, 0, 0));
  
  final dx = (newSize - image.width) ~/ 2;
  final dy = (newSize - image.height) ~/ 2;
  
  compositeImage(padded, image, dstX: dx, dstY: dy);
  
  File('assets/images/logo_floramaz_padded.png').writeAsBytesSync(encodePng(padded));
  print('Image padded successfully!');
}

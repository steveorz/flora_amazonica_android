import 'dart:io';
import 'package:image/image.dart';

void main() {
  final image = decodeImage(File('assets/images/logo_floramaz.png').readAsBytesSync())!;
  final newSize = 1800;
  // VERY IMPORTANT: numChannels: 4 for transparency!
  final padded = Image(width: newSize, height: newSize, numChannels: 4);
  
  // Fill with fully transparent pixels
  fill(padded, color: ColorRgba8(0, 0, 0, 0));
  
  final dx = (newSize - image.width) ~/ 2;
  final dy = (newSize - image.height) ~/ 2;
  
  compositeImage(padded, image, dstX: dx, dstY: dy);
  
  File('assets/images/logo_floramaz_padded2.png').writeAsBytesSync(encodePng(padded));
  print('Image padded successfully!');
}

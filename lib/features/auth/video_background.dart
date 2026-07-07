import 'dart:ui';
import 'package:flutter/material.dart';

/// Replaces VideoFondoAuth.swift for now with a static, cinematic background.
/// We apply the same dark-green jungle gradient and vignette.
class AuthBackground extends StatelessWidget {
  final bool blurred;

  const AuthBackground({super.key, this.blurred = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black),
        
        // Cinematic filter: jungle green tint + vignette
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0x8C031A0F), // 0.55 opacity, roughly RGB(3, 26, 15)
                Color(0x1F031A0F), // 0.12 opacity
                Color(0x8000120A), // 0.50 opacity
              ],
              stops: [0.0, 0.40, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Colors.transparent, Colors.black87],
              center: Alignment.center,
              radius: 1.5,
            ),
          ),
        ),
        
        if (blurred) ...[
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withOpacity(0.3), // extra veil
              ),
            ),
          ),
        ],
      ],
    );
  }
}

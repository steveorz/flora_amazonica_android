import 'dart:ui';
import 'package:flutter/material.dart';

enum AppToastKind { exito, error, info }

extension AppToastKindExtension on AppToastKind {
  Color get color {
    switch (this) {
      case AppToastKind.exito:
        return Colors.blue;
      case AppToastKind.error:
        return Colors.red;
      case AppToastKind.info:
        return Colors.blue;
    }
  }

  IconData get systemImage {
    switch (this) {
      case AppToastKind.exito:
        return Icons.check_circle;
      case AppToastKind.error:
        return Icons.cancel;
      case AppToastKind.info:
        return Icons.info;
    }
  }
}

class AppToast extends StatelessWidget {
  final AppToastKind kind;
  final String message;

  const AppToast({
    super.key,
    required this.kind,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kind.color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(kind.systemImage, color: kind.color),
              const SizedBox(width: 10),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

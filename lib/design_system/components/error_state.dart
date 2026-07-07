import 'package:flutter/material.dart';
import 'empty_state.dart';

enum AppErrorKind { sinConexion, servidor, sinPermisos }

extension AppErrorKindExtension on AppErrorKind {
  IconData get systemImage {
    switch (this) {
      case AppErrorKind.sinConexion:
        return Icons.wifi_off;
      case AppErrorKind.servidor:
        return Icons.cloud_off;
      case AppErrorKind.sinPermisos:
        return Icons.lock;
    }
  }

  String get title {
    switch (this) {
      case AppErrorKind.sinConexion:
        return "Sin conexión";
      case AppErrorKind.servidor:
        return "Error del servidor";
      case AppErrorKind.sinPermisos:
        return "Sin permisos";
    }
  }

  String get message {
    switch (this) {
      case AppErrorKind.sinConexion:
        return "Revisa tu conexión a internet e inténtalo de nuevo.";
      case AppErrorKind.servidor:
        return "Algo salió mal. Vuelve a intentar en un momento.";
      case AppErrorKind.sinPermisos:
        return "No tienes permisos para ver este contenido.";
    }
  }
}

class ErrorState extends StatelessWidget {
  final AppErrorKind kind;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.kind,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      systemImage: kind.systemImage,
      title: kind.title,
      message: kind.message,
      actionTitle: onRetry != null ? "Reintentar" : null,
      action: onRetry,
    );
  }
}

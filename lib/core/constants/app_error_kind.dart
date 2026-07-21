import 'package:flutter/material.dart';

/// Espejo de `AppErrorKind` (iOS, DesignSystem/Components/ErrorState.swift).
/// Es el tipo de error que exponen los Services a la UI.
enum AppErrorKind {
  sinConexion,
  servidor,
  sinPermisos;

  IconData get icon => switch (this) {
        AppErrorKind.sinConexion => Icons.wifi_off_rounded,
        AppErrorKind.servidor => Icons.cloud_off_rounded,
        AppErrorKind.sinPermisos => Icons.lock_rounded,
      };

  String get title => switch (this) {
        AppErrorKind.sinConexion => 'Sin conexión',
        AppErrorKind.servidor => 'Error del servidor',
        AppErrorKind.sinPermisos => 'Sin permisos',
      };

  String get message => switch (this) {
        AppErrorKind.sinConexion =>
          'Revisa tu conexión a internet e inténtalo de nuevo.',
        AppErrorKind.servidor => 'Algo salió mal. Vuelve a intentar en un momento.',
        AppErrorKind.sinPermisos => 'No tienes permisos para ver este contenido.',
      };
}

import 'package:flutter/material.dart';

/// Pestaña "Avisos" con el contador de no leídas.
/// Los tres shells la comparten, igual que `.badge(notificaciones.noLeidas)` en iOS.
NavigationDestination avisosDestination(int noLeidas) {
  Widget conBadge(IconData icono) => Badge(
        isLabelVisible: noLeidas > 0,
        label: Text('$noLeidas'),
        child: Icon(icono),
      );

  return NavigationDestination(
    icon: conBadge(Icons.notifications_none),
    selectedIcon: conBadge(Icons.notifications),
    label: 'Avisos',
  );
}

import 'package:flutter/material.dart';

import '../../core/constants/app_error_kind.dart';
import 'empty_state.dart';

export '../../core/constants/app_error_kind.dart';

/// Estado de error con acción de reintento. Espejo de `ErrorState` (iOS).
///
/// El tipo de error vive en `core/constants/app_error_kind.dart`, que es lo que
/// exponen los Services; esta pantalla sólo lo pinta.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.kind, this.onRetry});

  final AppErrorKind kind;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      systemImage: kind.icon,
      title: kind.title,
      message: kind.message,
      actionTitle: onRetry != null ? 'Reintentar' : null,
      action: onRetry,
    );
  }
}

import 'package:flutter/material.dart';

enum AppButtonVariant { primario, atencion, secundario, terciario, destructivo, icono }

class AppButton extends StatelessWidget {
  final String title;
  final IconData? systemImage;
  final AppButtonVariant variant;
  final VoidCallback action;

  /// Equivale a `.disabled(...)` en SwiftUI: con `false` el botón se apaga.
  final bool enabled;

  const AppButton({
    super.key,
    this.title = "",
    this.systemImage,
    this.variant = AppButtonVariant.primario,
    required this.action,
    this.enabled = true,
  });

  /// `null` apaga el botón en todos los widgets de Material.
  VoidCallback? get _onPressed => enabled ? action : null;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primario:
        return FilledButton(
          onPressed: _onPressed,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: _buildLabel(),
        );
      case AppButtonVariant.atencion:
        return FilledButton(
          onPressed: _onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: _buildLabel(),
        );
      case AppButtonVariant.secundario:
        return FilledButton.tonal(
          onPressed: _onPressed,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: _buildLabel(),
        );
      case AppButtonVariant.terciario:
        return TextButton(
          onPressed: _onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: _buildLabel(),
        );
      case AppButtonVariant.destructivo:
        return FilledButton(
          onPressed: _onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: _buildLabel(),
        );
      case AppButtonVariant.icono:
        return IconButton(
          onPressed: _onPressed,
          icon: Icon(systemImage ?? Icons.circle),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
    }
  }

  Widget _buildLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (systemImage != null) Icon(systemImage, size: 20),
        if (systemImage != null && title.isNotEmpty) const SizedBox(width: 6),
        if (title.isNotEmpty) Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

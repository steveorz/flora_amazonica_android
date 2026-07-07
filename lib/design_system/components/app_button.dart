import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

enum AppButtonVariant { primario, atencion, secundario, terciario, destructivo, icono }

class AppButton extends StatelessWidget {
  final String title;
  final IconData? systemImage;
  final AppButtonVariant variant;
  final VoidCallback action;

  const AppButton({
    super.key,
    this.title = "",
    this.systemImage,
    this.variant = AppButtonVariant.primario,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primario:
        return ElevatedButton(
          onPressed: action,
          style: ElevatedButton.styleFrom(
            backgroundColor: BrandColors.brandPrimary,
            foregroundColor: BrandColors.onBrand,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            elevation: 0,
          ),
          child: _buildLabel(),
        );
      case AppButtonVariant.atencion:
        return ElevatedButton(
          onPressed: action,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            elevation: 0,
          ),
          child: _buildLabel(),
        );
      case AppButtonVariant.secundario:
        return FilledButton.tonal(
          onPressed: action,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          child: _buildLabel(),
        );
      case AppButtonVariant.terciario:
        return TextButton(
          onPressed: action,
          style: TextButton.styleFrom(
            foregroundColor: BrandColors.brandPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          child: _buildLabel(),
        );
      case AppButtonVariant.destructivo:
        return ElevatedButton(
          onPressed: action,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            elevation: 0,
          ),
          child: _buildLabel(),
        );
      case AppButtonVariant.icono:
        return IconButton(
          onPressed: action,
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

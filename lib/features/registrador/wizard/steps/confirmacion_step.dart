import 'package:flutter/material.dart';
import '../../../../../design_system/theme/brand_colors.dart';
import '../../../../../design_system/components/app_button.dart';

class ConfirmacionStep extends StatelessWidget {
  const ConfirmacionStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: BrandColors.brandPrimary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: BrandColors.brandPrimary,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "¡Registro enviado!",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Tu registro ha sido enviado exitosamente y ahora se encuentra En Revisión. Un validador botánico revisará la información pronto.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 48),
          AppButton(
            title: "Volver a Inicio",
            variant: AppButtonVariant.primario,
            action: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

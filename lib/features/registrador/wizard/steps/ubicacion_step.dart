import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../wizard_provider.dart';
import '../../../../../design_system/components/app_text_field.dart';
import '../../../../../design_system/components/app_button.dart';

class UbicacionStep extends ConsumerWidget {
  const UbicacionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardProvider);
    final notifier = ref.read(wizardProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ubicación", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Define las coordenadas y referencia del registro.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 18),
          
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text("Mapa no implementado aún", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 18),
          
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  title: "Latitud *",
                  placeholder: "-3.7437",
                  kind: AppTextFieldKind.numeric,
                  initialValue: state.draft.lat?.toString() ?? '',
                  onChanged: (v) {
                    state.draft.lat = double.tryParse(v);
                    notifier.forceUpdate();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  title: "Longitud *",
                  placeholder: "-73.2516",
                  kind: AppTextFieldKind.numeric,
                  initialValue: state.draft.lng?.toString() ?? '',
                  onChanged: (v) {
                    state.draft.lng = double.tryParse(v);
                    notifier.forceUpdate();
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          AppButton(
            title: "Obtener mi ubicación",
            systemImage: Icons.my_location,
            variant: AppButtonVariant.secundario,
            action: () {
              // Mock location for now
              state.draft.lat = -3.7437;
              state.draft.lng = -73.2516;
              notifier.forceUpdate();
            },
          ),
          
          const SizedBox(height: 24),
          AppTextField(
            title: "Referencia",
            placeholder: "Ej.: Borde sur del aguajal",
            initialValue: state.draft.referencia,
            onChanged: (v) => state.draft.referencia = v,
          ),
          
          const SizedBox(height: 12),
          AppTextField(
            title: "Tipo de hábitat *",
            placeholder: "Ej.: Bosque de tierra firme",
            initialValue: state.draft.tipoHabitat,
            onChanged: (v) {
              state.draft.tipoHabitat = v;
              notifier.forceUpdate();
            },
          ),
        ],
      ),
    );
  }
}

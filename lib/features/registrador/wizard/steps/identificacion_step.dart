import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../wizard_provider.dart';
import '../../../../core/services/especie_service.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/components/app_chips.dart';

class IdentificacionStep extends ConsumerStatefulWidget {
  const IdentificacionStep({super.key});

  @override
  ConsumerState<IdentificacionStep> createState() => _IdentificacionStepState();
}

class _IdentificacionStepState extends ConsumerState<IdentificacionStep> {
  final List<String> _paises = [
    "Perú", "Brasil", "Bolivia", "Ecuador", "Colombia",
    "Venezuela", "Guyana", "Surinam"
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wizardProvider);
    final notifier = ref.read(wizardProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Taxonomía", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AppTextField(
            title: "Nombre científico *",
            placeholder: "Ej.: Cedrela odorata",
            initialValue: state.draft.nombreCientifico,
            onChanged: (v) {
              state.draft.nombreCientifico = v;
              notifier.forceUpdate(); // Triggers UI validation
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            title: "Autor",
            placeholder: "Tu nombre",
            initialValue: state.draft.autorNombre,
            onChanged: (v) => state.draft.autorNombre = v,
          ),
          const SizedBox(height: 12),
          AppTextField(
            title: "Familia *",
            placeholder: "Ej.: Meliaceae",
            initialValue: state.draft.familia,
            onChanged: (v) {
              state.draft.familia = v;
              notifier.forceUpdate();
            },
          ),
          const SizedBox(height: 24),
          const Text("Detalle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AppTextField(
            title: "Nombre local *",
            placeholder: "Ej.: Cedro",
            initialValue: state.draft.nombreLocal,
            onChanged: (v) {
              state.draft.nombreLocal = v;
              notifier.forceUpdate();
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            title: "Descripción",
            placeholder: "Notas generales de la especie...",
            kind: AppTextFieldKind.multiline,
            initialValue: state.draft.descripcion,
            onChanged: (v) => state.draft.descripcion = v,
          ),
          const SizedBox(height: 24),
          const Text("Distribución por países *", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Marca todos los países donde se ha reportado la especie.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          AppChips<String>(
            items: _paises,
            selection: Set.from(state.draft.distribucionPaises),
            labelFor: (s) => s,
            onChanged: (newSelection) {
              state.draft.distribucionPaises = newSelection.toList();
              notifier.forceUpdate();
            },
          ),
        ],
      ),
    );
  }
}

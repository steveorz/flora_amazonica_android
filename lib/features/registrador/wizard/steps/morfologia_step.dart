import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../wizard_provider.dart';
import '../../../../../data/models/especie.dart';
import '../../../../../design_system/components/app_text_field.dart';

class MorfologiaStep extends ConsumerWidget {
  const MorfologiaStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardProvider);
    final notifier = ref.read(wizardProvider.notifier);
    
    final esArbol = state.draft.habito == Habito.arbol;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Morfología", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(
            "Características de ${state.draft.habito?.toString().split('.').last.toLowerCase() ?? 'la especie'}.",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 18),
          
          if (esArbol)
            _DasometricosForm(state: state, notifier: notifier),
            
          const SizedBox(height: 24),
          const Text("Campos Dinámicos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text("Aquí irán los campos morfológicos dinámicos obtenidos del backend basados en el hábito.", style: TextStyle(color: Colors.grey)),
          
          // Placeholder for dynamic morphology fields
          const SizedBox(height: 12),
          AppTextField(
            title: "Descripción adicional",
            placeholder: "Agregue detalles morfológicos...",
            kind: AppTextFieldKind.multiline,
            initialValue: state.draft.caracteres['descripcion'] ?? '',
            onChanged: (v) {
              state.draft.caracteres['descripcion'] = v;
            },
          ),
        ],
      ),
    );
  }
}

class _DasometricosForm extends StatelessWidget {
  final WizardState state;
  final WizardNotifier notifier;
  
  const _DasometricosForm({required this.state, required this.notifier});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Datos dasométricos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AppTextField(
            title: "Altura total (m)",
            placeholder: "0",
            kind: AppTextFieldKind.numeric,
            initialValue: state.draft.altura?.toString() ?? '',
            onChanged: (v) => state.draft.altura = double.tryParse(v),
          ),
          const SizedBox(height: 12),
          AppTextField(
            title: "CAP (cm)",
            placeholder: "0",
            kind: AppTextFieldKind.numeric,
            initialValue: state.draft.cap?.toString() ?? '',
            onChanged: (v) {
              state.draft.cap = double.tryParse(v);
              notifier.forceUpdate();
            },
          ),
          const SizedBox(height: 12),
          // DAP Calculation box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("DAP calculado", style: TextStyle(fontWeight: FontWeight.w600)),
                      Text("DAP = CAP / π", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text(
                  "${_calculateDap(state.draft.cap)} cm",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            title: "Diámetro copa paralelo (m)",
            placeholder: "0",
            kind: AppTextFieldKind.numeric,
            initialValue: state.draft.diamCopaParalelo?.toString() ?? '',
            onChanged: (v) => state.draft.diamCopaParalelo = double.tryParse(v),
          ),
          const SizedBox(height: 12),
          AppTextField(
            title: "Diámetro copa perpendicular (m)",
            placeholder: "0",
            kind: AppTextFieldKind.numeric,
            initialValue: state.draft.diamCopaPerpendicular?.toString() ?? '',
            onChanged: (v) => state.draft.diamCopaPerpendicular = double.tryParse(v),
          ),
          const SizedBox(height: 12),
          AppTextField(
            title: "Altura inicio copa (m)",
            placeholder: "0",
            kind: AppTextFieldKind.numeric,
            initialValue: state.draft.alturaInicioCopa?.toString() ?? '',
            onChanged: (v) => state.draft.alturaInicioCopa = double.tryParse(v),
          ),
        ],
      ),
    );
  }
  
  String _calculateDap(double? cap) {
    if (cap == null || cap == 0) return "0.0";
    return (cap / 3.14159).toStringAsFixed(2);
  }
}

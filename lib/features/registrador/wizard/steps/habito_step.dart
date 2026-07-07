import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../wizard_provider.dart';
import '../../../../../data/models/especie.dart';
import '../../../../../design_system/theme/brand_colors.dart';
import '../../../../../design_system/components/app_radio_group.dart';

class HabitoStep extends ConsumerWidget {
  const HabitoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardProvider);
    final notifier = ref.read(wizardProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hábito y tipo de vida", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Tu elección determina el formulario de morfología.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 18),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: Habito.values.length,
            itemBuilder: (context, index) {
              final h = Habito.values[index];
              return _buildCard(h, state, notifier);
            },
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text("Tipo de vida", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          AppRadioGroup<TipoVida>(
            title: "",
            items: TipoVida.values,
            selection: state.draft.tipoVida,
            labelFor: (tv) => tv.toString().split('.').last.toUpperCase(),
            onChanged: (newVal) {
              if (newVal != null) {
                state.draft.tipoVida = newVal;
                notifier.forceUpdate();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Habito h, WizardState state, WizardNotifier notifier) {
    final selected = state.draft.habito == h;
    final label = h.toString().split('.').last.toUpperCase();

    return InkWell(
      onTap: () {
        state.draft.habito = h;
        notifier.forceUpdate();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? BrandColors.brandPrimary.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          border: Border.all(color: selected ? BrandColors.brandPrimary : Colors.transparent, width: 3),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: selected ? BrandColors.brandPrimary : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

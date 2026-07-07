import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../wizard_provider.dart';
import '../../../../../design_system/theme/brand_colors.dart';

class ResumenStep extends ConsumerWidget {
  const ResumenStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardProvider);
    final notifier = ref.read(wizardProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Resumen del registro", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Revisa los datos antes de enviar. Serán evaluados por un validador botánico.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 18),
          
          _buildCard(
            context: context,
            title: "1. Taxonomía",
            icon: Icons.eco,
            onEdit: () => notifier.irA(1),
            children: [
              _buildRow("Nombre científico", state.draft.nombreCientifico),
              _buildRow("Familia", state.draft.familia),
              _buildRow("Nombre local", state.draft.nombreLocal),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildCard(
            context: context,
            title: "2. Hábito",
            icon: Icons.category,
            onEdit: () => notifier.irA(2),
            children: [
              _buildRow("Hábito", state.draft.habito?.toString().split('.').last.toUpperCase() ?? ''),
              _buildRow("Tipo de vida", state.draft.tipoVida.toString().split('.').last.toUpperCase()),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildCard(
            context: context,
            title: "3. Morfología",
            icon: Icons.list_alt,
            onEdit: () => notifier.irA(3),
            children: [
              if (state.draft.altura != null) _buildRow("Altura (m)", state.draft.altura.toString()),
              if (state.draft.cap != null) _buildRow("CAP (cm)", state.draft.cap.toString()),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildCard(
            context: context,
            title: "4. Ubicación",
            icon: Icons.map,
            onEdit: () => notifier.irA(4),
            children: [
              _buildRow("Coordenadas", "${state.draft.lat}, ${state.draft.lng}"),
              _buildRow("Hábitat", state.draft.tipoHabitat),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildCard(
            context: context,
            title: "5. Fotografías",
            icon: Icons.photo_library,
            onEdit: () => notifier.irA(5),
            children: [
              _buildRow("Capturadas", "${state.draft.fotosData.length} de 5 requeridas"),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: BrandColors.brandPrimary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Editar", style: TextStyle(color: BrandColors.brandPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Expanded(
            child: Text(value.isEmpty ? "-" : value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

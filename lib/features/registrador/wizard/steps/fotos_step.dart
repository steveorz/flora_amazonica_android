import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../wizard_provider.dart';
import '../../../../../data/models/especie.dart';
import '../../../../../design_system/theme/brand_colors.dart';

class FotosStep extends ConsumerWidget {
  const FotosStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Fotografías", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Captura una foto por cada tipo. Toca cualquier foto para reemplazarla.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 18),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: TipoFoto.values.length,
            itemBuilder: (context, index) {
              final tipo = TipoFoto.values[index];
              return _FotoSlotView(tipo: tipo);
            },
          ),
          
          const SizedBox(height: 24),
          _buildContador(state),
        ],
      ),
    );
  }

  Widget _buildContador(WizardState state) {
    final total = TipoFoto.values.length;
    final n = state.draft.fotosData.length;
    final completo = n == total;
    
    return Row(
      children: [
        Icon(
          completo ? Icons.check_circle : Icons.photo_library,
          color: completo ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          "$n de $total fotos capturadas",
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }
}

class _FotoSlotView extends ConsumerStatefulWidget {
  final TipoFoto tipo;
  const _FotoSlotView({required this.tipo});

  @override
  ConsumerState<_FotoSlotView> createState() => _FotoSlotViewState();
}

class _FotoSlotViewState extends ConsumerState<_FotoSlotView> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      
      final notifier = ref.read(wizardProvider.notifier);
      final state = ref.read(wizardProvider);
      
      state.draft.fotosData[widget.tipo] = bytes;
      notifier.forceUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wizardProvider);
    final Uint8List? data = state.draft.fotosData[widget.tipo];
    final capturada = data != null;
    final label = widget.tipo.toString().split('.').last.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Expanded(
          child: InkWell(
            onTap: _takePhoto,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: capturada ? Colors.black : Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                image: capturada ? DecorationImage(
                  image: MemoryImage(data),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: !capturada ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.grey, size: 32),
                    SizedBox(height: 4),
                    Text("Tocar para agregar", style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ) : Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.green, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

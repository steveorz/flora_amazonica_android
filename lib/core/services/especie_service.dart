import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/especie.dart';
import '../../data/repositories/especie_repository.dart';

class EspecieService extends Notifier<List<Especie>> {
  @override
  List<Especie> build() {
    return [];
  }

  Future<void> cargar() async {
    try {
      final repository = ref.read(especieRepositoryProvider);
      final list = await repository.obtenerEspecies();
      state = list;
    } catch (e) {
      // Handle error appropriately
      print("Error loading species: $e");
    }
  }

  List<Especie> registrosDe(String usuarioId) {
    return state.where((e) => e.registradorId == usuarioId).toList();
  }
}

final especieServiceProvider = NotifierProvider<EspecieService, List<Especie>>(() {
  return EspecieService();
});

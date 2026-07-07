import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/especie.dart';
import '../../../data/repositories/especie_repository.dart';
import '../../../core/services/especie_service.dart';

class EspecieDraft {
  String? id;
  String catalogId = "";
  String nombreCientifico = "";
  String autorNombre = "";
  String familia = "";
  String nombreLocal = "";
  String descripcion = "";
  List<String> distribucionPaises = [];
  
  Habito? habito;
  TipoVida tipoVida = TipoVida.silvestre;
  
  // Ubicacion
  double? lat;
  double? lng;
  String referencia = "";
  String tipoHabitat = "";
  
  // Fotos (Type -> Data)
  Map<TipoFoto, Uint8List> fotosData = {};
  
  // Morfologia dinamica
  Map<String, String> caracteres = {};
  
  // Dasometricos (if tree)
  double? altura;
  double? cap;
  double? diamCopaParalelo;
  double? diamCopaPerpendicular;
  double? alturaInicioCopa;
}

class WizardState {
  final int pasoActual;
  final int totalPasos = 7;
  final EspecieDraft draft;
  final bool enviando;
  final String? error;
  
  // Dynamic fields
  final List<dynamic> camposDinamicos;
  final bool cargandoCampos;

  WizardState({
    required this.pasoActual,
    required this.draft,
    this.enviando = false,
    this.error,
    this.camposDinamicos = const [],
    this.cargandoCampos = false,
  });

  WizardState copyWith({
    int? pasoActual,
    EspecieDraft? draft,
    bool? enviando,
    String? error,
    List<dynamic>? camposDinamicos,
    bool? cargandoCampos,
  }) {
    return WizardState(
      pasoActual: pasoActual ?? this.pasoActual,
      draft: draft ?? this.draft,
      enviando: enviando ?? this.enviando,
      error: error ?? this.error,
      camposDinamicos: camposDinamicos ?? this.camposDinamicos,
      cargandoCampos: cargandoCampos ?? this.cargandoCampos,
    );
  }
}

class WizardNotifier extends AutoDisposeNotifier<WizardState> {
  @override
  WizardState build() {
    return WizardState(pasoActual: 1, draft: EspecieDraft());
  }

  void avanzar() {
    if (state.pasoActual < state.totalPasos) {
      state = state.copyWith(pasoActual: state.pasoActual + 1);
    }
  }

  void retroceder() {
    if (state.pasoActual > 1) {
      state = state.copyWith(pasoActual: state.pasoActual - 1);
    }
  }

  void irA(int paso) {
    if (paso >= 1 && paso <= state.totalPasos) {
      state = state.copyWith(pasoActual: paso);
    }
  }

  bool pasoCompleto(int paso) {
    switch (paso) {
      case 1:
        return state.draft.nombreCientifico.isNotEmpty &&
               state.draft.familia.isNotEmpty &&
               state.draft.nombreLocal.isNotEmpty &&
               state.draft.distribucionPaises.isNotEmpty;
      case 2:
        return state.draft.habito != null;
      case 3:
        // Morph logic validation (mocked to true for now)
        return true;
      case 4:
        return state.draft.lat != null && state.draft.lng != null && state.draft.tipoHabitat.isNotEmpty;
      case 5:
        // Require all 5 photo types
        return state.draft.fotosData.length == TipoFoto.values.length;
      default:
        return true;
    }
  }

  Future<void> enviar(String registradorId) async {
    state = state.copyWith(enviando: true, error: null);
    try {
      final repo = ref.read(especieRepositoryProvider);
      await repo.crearRegistro(state.draft, registradorId);
      
      // Terminado con éxito:
      state = state.copyWith(enviando: false, pasoActual: 7);
      
      // Recargar especies global
      ref.read(especieServiceProvider.notifier).cargar();
      
    } catch (e) {
      state = state.copyWith(enviando: false, error: e.toString());
    }
  }
  
  void forceUpdate() {
    state = state.copyWith();
  }
}

final wizardProvider = AutoDisposeNotifierProvider<WizardNotifier, WizardState>(() {
  return WizardNotifier();
});

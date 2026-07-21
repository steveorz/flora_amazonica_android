import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/estado_registro.dart';
import '../../../core/constants/habito.dart';
import '../../../core/services/especie_service.dart';
import '../../../core/storage/draft_storage.dart';
import '../../../data/models/campo_morfologico.dart';
import '../../../data/models/especie.dart';
import '../../../data/models/especie_draft.dart';
import '../../../data/models/foto.dart';
import '../../../data/repositories/especie_repository.dart';
import '../../../data/repositories/valor_morfologico_repository.dart';

/// Estado observable del wizard de nuevo registro.
/// Espejo de `RegistroWizardStore` (iOS).
///
/// - `draft` tiene los datos persistibles (se guardan como borrador).
/// - `fotoData` tiene las imágenes capturadas en memoria; los bytes van a disco
///   por separado (ver [DraftStorage]).
class WizardState {
  static const totalPasos = 7;

  final EspecieDraft draft;
  final Map<TipoFoto, Uint8List> fotoData;
  final int pasoActual;

  /// Si es edición, el id del registro existente que se está modificando.
  final String? editandoId;

  final bool enviando;
  final String? errorEnvio;
  final Especie? resultado;

  // Formulario morfológico dinámico
  final List<CampoMorfologico> camposDinamicos;
  final bool cargandoCampos;
  final String? errorCampos;

  /// Hábito para el que ya se cargaron los campos, para no repedirlos.
  final String? habitoCargado;

  const WizardState({
    required this.draft,
    this.fotoData = const {},
    this.pasoActual = 1,
    this.editandoId,
    this.enviando = false,
    this.errorEnvio,
    this.resultado,
    this.camposDinamicos = const [],
    this.cargandoCampos = false,
    this.errorCampos,
    this.habitoCargado,
  });

  WizardState copyWith({
    EspecieDraft? draft,
    Map<TipoFoto, Uint8List>? fotoData,
    int? pasoActual,
    bool? enviando,
    String? errorEnvio,
    bool clearErrorEnvio = false,
    Especie? resultado,
    List<CampoMorfologico>? camposDinamicos,
    bool? cargandoCampos,
    String? errorCampos,
    bool clearErrorCampos = false,
    String? habitoCargado,
  }) {
    return WizardState(
      draft: draft ?? this.draft,
      fotoData: fotoData ?? this.fotoData,
      pasoActual: pasoActual ?? this.pasoActual,
      editandoId: editandoId,
      enviando: enviando ?? this.enviando,
      errorEnvio: clearErrorEnvio ? null : (errorEnvio ?? this.errorEnvio),
      resultado: resultado ?? this.resultado,
      camposDinamicos: camposDinamicos ?? this.camposDinamicos,
      cargandoCampos: cargandoCampos ?? this.cargandoCampos,
      errorCampos: clearErrorCampos ? null : (errorCampos ?? this.errorCampos),
      habitoCargado: habitoCargado ?? this.habitoCargado,
    );
  }
}

class WizardNotifier extends StateNotifier<WizardState> {
  WizardNotifier(this._ref, {EspecieDraft? draft, Especie? especie})
      : super(_estadoInicial(draft: draft, especie: especie)) {
    if (draft != null) _recuperarFotos(draft.id);
  }

  final Ref _ref;

  static WizardState _estadoInicial({EspecieDraft? draft, Especie? especie}) {
    if (especie != null) {
      // Edición: las fotos ya existen como URLs; el wizard puede sobreescribirlas.
      return WizardState(draft: EspecieDraft.fromEspecie(especie), editandoId: especie.id);
    }
    if (draft != null) {
      return WizardState(
        draft: draft,
        pasoActual: draft.pasoActual.clamp(1, WizardState.totalPasos),
      );
    }
    return WizardState(draft: EspecieDraft());
  }

  /// Al retomar un borrador, las fotos vuelven desde disco.
  Future<void> _recuperarFotos(String draftId) async {
    final fotos = await DraftStorage.loadPhotos(draftId);
    if (fotos.isNotEmpty && mounted) state = state.copyWith(fotoData: fotos);
  }

  // MARK: - Mutación del draft

  /// Aplica un cambio al draft y notifica. El draft es mutable (como el struct
  /// `var draft` de iOS), así que basta con reemplazar la referencia del estado.
  void editar(void Function(EspecieDraft) cambio) {
    cambio(state.draft);
    state = state.copyWith(draft: state.draft);
  }

  // MARK: - Navegación

  void avanzar() {
    final siguiente = (state.pasoActual + 1).clamp(1, WizardState.totalPasos);
    state.draft.pasoActual = siguiente;
    state = state.copyWith(pasoActual: siguiente);
    guardarBorradorLocal();
  }

  void retroceder() {
    final anterior = (state.pasoActual - 1).clamp(1, WizardState.totalPasos);
    state.draft.pasoActual = anterior;
    state = state.copyWith(pasoActual: anterior);
  }

  void irA(int paso) {
    final destino = paso.clamp(1, WizardState.totalPasos);
    state.draft.pasoActual = destino;
    state = state.copyWith(pasoActual: destino);
  }

  // MARK: - Fotos

  Future<void> guardarFoto(TipoFoto tipo, Uint8List bytes) async {
    state.draft.fotosCapturadas.add(tipo);
    state = state.copyWith(fotoData: {...state.fotoData, tipo: bytes});
    // A disco: si la app muere, el borrador conserva la foto.
    await DraftStorage.savePhoto(state.draft.id, tipo, bytes);
    await guardarBorradorLocal();
  }

  Future<void> quitarFoto(TipoFoto tipo) async {
    state.draft.fotosCapturadas.remove(tipo);
    final fotos = Map<TipoFoto, Uint8List>.of(state.fotoData)..remove(tipo);
    state = state.copyWith(fotoData: fotos);
    await guardarBorradorLocal();
  }

  // MARK: - Formulario dinámico

  /// Pide al backend los caracteres morfológicos que corresponden al hábito.
  /// No se repite si ya están cargados para ese mismo hábito.
  Future<void> cargarCamposDinamicos(Habito habito) async {
    if (state.habitoCargado == habito.name && state.camposDinamicos.isNotEmpty) return;

    state = state.copyWith(cargandoCampos: true, clearErrorCampos: true);
    try {
      final campos = await _ref
          .read(valorMorfologicoRepositoryProvider)
          .obtenerCamposDinamicos(habito.name);
      state = state.copyWith(
        camposDinamicos: campos,
        cargandoCampos: false,
        habitoCargado: habito.name,
      );
    } catch (e) {
      state = state.copyWith(
        cargandoCampos: false,
        errorCampos: 'Error al cargar el formulario: $e',
      );
    }
  }

  // MARK: - Borrador

  Future<void> guardarBorradorLocal() async {
    state.draft.fechaActualizacion = DateTime.now();
    await DraftStorage.upsert(state.draft);
  }

  Future<void> descartarBorrador() => DraftStorage.delete(state.draft.id);

  // MARK: - Envío

  Future<void> enviar(String registradorId) async {
    final draft = state.draft;
    final habito = draft.habito;
    final tipoVida = draft.tipoVida;
    final ubicacion = draft.ubicacion;

    if (habito == null || tipoVida == null || ubicacion == null) {
      state = state.copyWith(errorEnvio: 'Faltan datos obligatorios.');
      return;
    }

    state = state.copyWith(enviando: true, clearErrorEnvio: true);
    final ahora = DateTime.now();
    final service = _ref.read(especieServiceProvider.notifier);

    try {
      // Sólo las fotos con bytes se suben; en edición, las ya subidas
      // llegan sin `localData` y el repositorio las ignora.
      final fotos = [
        for (final tipo in draft.fotosCapturadas)
          if (state.fotoData[tipo] != null)
            Foto(
              id: '${tipo.value}-${ahora.microsecondsSinceEpoch}',
              tipo: tipo,
              url: '',
              autor: 'Registrador',
              fecha: ahora,
              localData: state.fotoData[tipo],
            ),
      ];

      final editandoId = state.editandoId;
      if (editandoId != null) {
        final actual = await service.get(editandoId);
        final nuevo = actual.copyWith(
          catalogId: draft.catalogId,
          nombreCientifico: draft.nombreCientifico,
          autorNombre: draft.autorNombre,
          familia: draft.familia,
          nombreLocal: draft.nombreLocal,
          habito: habito,
          tipoVida: tipoVida,
          distribucionPaises: draft.distribucionPaises,
          caracteres: draft.caracteres,
          datosDasometricos: draft.datosDasometricos,
          ubicacion: ubicacion,
          estado: EstadoRegistro.enRevision,
          fotos: fotos.isNotEmpty ? fotos : actual.fotos,
          historialEstados: [
            ...actual.historialEstados,
            HistorialEstado(
              id: '${ahora.microsecondsSinceEpoch}',
              estado: EstadoRegistro.enRevision,
              fecha: ahora,
              usuarioId: registradorId,
              comentario: 'Editado por el registrador',
            ),
          ],
        );
        final resultado = await service.actualizar(nuevo);
        await descartarBorrador();
        state = state.copyWith(enviando: false, resultado: resultado);
      } else {
        final especie = Especie(
          id: draft.id,
          catalogId: draft.catalogId,
          nombreCientifico: draft.nombreCientifico,
          autorNombre: draft.autorNombre,
          familia: draft.familia,
          nombreLocal: draft.nombreLocal,
          habito: habito,
          tipoVida: tipoVida,
          distribucionPaises: draft.distribucionPaises,
          caracteres: draft.caracteres,
          datosDasometricos: draft.datosDasometricos,
          ubicacion: ubicacion,
          fotos: fotos,
          estado: EstadoRegistro.enRevision,
          codigoSeguimiento: generarCodigoSeguimiento(),
          registradorId: registradorId,
          fechaEnvio: ahora,
          historialEstados: [
            HistorialEstado(
              id: '${ahora.microsecondsSinceEpoch}',
              estado: EstadoRegistro.enRevision,
              fecha: ahora,
              usuarioId: registradorId,
            ),
          ],
        );
        final resultado = await service.crear(especie);
        await descartarBorrador();
        state = state.copyWith(enviando: false, resultado: resultado);
      }
    } catch (e) {
      state = state.copyWith(enviando: false, errorEnvio: 'No se pudo enviar: $e');
    }
  }

  // MARK: - Validaciones por paso

  bool pasoCompleto(int paso) {
    final d = state.draft;
    switch (paso) {
      case 1: // Identificación
        return d.nombreCientifico.isNotEmpty &&
            d.familia.isNotEmpty &&
            d.nombreLocal.isNotEmpty &&
            d.distribucionPaises.isNotEmpty;
      case 2: // Hábito y tipo de vida
        return d.habito != null && d.tipoVida != null;
      case 3: // Morfología
        // Árboles y palmeras exigen dasometría; el resto, al menos un carácter.
        return d.caracteres.isNotEmpty ||
            ((d.habito == Habito.arbol || d.habito == Habito.palmera) &&
                d.datosDasometricos != null);
      case 4: // Ubicación
        return d.ubicacion != null && d.ubicacion!.tipoHabitat.isNotEmpty;
      case 5: // Fotos: se exigen todos los tipos
        return d.fotosCapturadas.length >= TipoFoto.values.length;
      case 6:
      case 7:
        return true;
      default:
        return false;
    }
  }
}

/// El wizard vive mientras la pantalla esté abierta. Los argumentos permiten
/// abrirlo en blanco, retomando un borrador o editando un registro existente.
final wizardProvider =
    StateNotifierProvider.autoDispose.family<WizardNotifier, WizardState, WizardArgs>(
  (ref, args) => WizardNotifier(ref, draft: args.draft, especie: args.especie),
);

/// Identidad del wizard: dos aperturas con el mismo borrador comparten estado.
class WizardArgs {
  final EspecieDraft? draft;
  final Especie? especie;

  const WizardArgs({this.draft, this.especie});
  const WizardArgs.nuevo() : draft = null, especie = null;

  @override
  bool operator ==(Object other) =>
      other is WizardArgs && other.draft?.id == draft?.id && other.especie?.id == especie?.id;

  @override
  int get hashCode => Object.hash(draft?.id, especie?.id);
}

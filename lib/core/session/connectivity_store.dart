import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un registro o acción esperando a que vuelva la conexión.
/// Espejo de `EnvioPendiente` (iOS).
@immutable
class EnvioPendiente {
  final String id;
  final String titulo;
  final String detalle;
  final DateTime fecha;

  const EnvioPendiente({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.fecha,
  });
}

@immutable
class ConectividadState {
  final bool online;
  final List<EnvioPendiente> pendientes;

  const ConectividadState({this.online = true, this.pendientes = const []});

  ConectividadState copyWith({bool? online, List<EnvioPendiente>? pendientes}) {
    return ConectividadState(
      online: online ?? this.online,
      pendientes: pendientes ?? this.pendientes,
    );
  }
}

/// Espejo de `ConnectivityStore` (iOS), pero con conectividad **real**:
/// en iOS estaba simulada y sólo el admin podía alternarla desde Configuración.
/// Aquí escuchamos al sistema y dejamos [forzarOffline] para poder probar la UI.
class ConectividadNotifier extends StateNotifier<ConectividadState> {
  ConectividadNotifier() : super(const ConectividadState()) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Cuando es true, la app se comporta como offline aunque haya red.
  bool _override = false;

  Future<void> _init() async {
    _aplicar(await Connectivity().checkConnectivity());
    _sub = Connectivity().onConnectivityChanged.listen(_aplicar);
  }

  void _aplicar(List<ConnectivityResult> resultados) {
    if (_override) return;
    final hayRed = resultados.any((r) => r != ConnectivityResult.none);
    if (hayRed != state.online) state = state.copyWith(online: hayRed);
  }

  void encolar(EnvioPendiente envio) {
    state = state.copyWith(pendientes: [...state.pendientes, envio]);
  }

  void vaciarCola() => state = state.copyWith(pendientes: const []);

  /// Interruptor manual para probar los estados offline de la UI.
  void forzarOffline(bool offline) {
    _override = offline;
    if (offline) {
      state = state.copyWith(online: false);
    } else {
      _init();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final conectividadProvider =
    StateNotifierProvider<ConectividadNotifier, ConectividadState>(
  (ref) => ConectividadNotifier(),
);

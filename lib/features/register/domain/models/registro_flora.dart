class RegistroFlora {
  final String id;
  final String usuarioId;
  final EstadoRegistro estado; // BORRADOR, REVISION, OBSERVADO, VALIDADO, RECHAZADO
  final Taxonomia taxonomia;
  final Dasometria morfologia;
  final UbicacionGPS ubicacion;
  final FotografiasRegistro fotografias;
  final DateTime fechaRegistro;
  final String? motivoObservacion;

  RegistroFlora({
    required this.id,
    required this.usuarioId,
    required this.estado,
    required this.taxonomia,
    required this.morfologia,
    required this.ubicacion,
    required this.fotografias,
    required this.fechaRegistro,
    this.motivoObservacion,
  });
}

enum EstadoRegistro { borrador, enRevision, observado, validado, rechazado }

class Taxonomia {
  final String nombreCientifico;
  final String familia;

  Taxonomia({required this.nombreCientifico, required this.familia});
}

class Dasometria {
  final String habito; // Árbol, Arbusto, Hierba, Liana
  final double? cap; // Solo para Árbol
  final double? dap; // DAP calculado

  Dasometria({required this.habito, this.cap, this.dap});
}

class UbicacionGPS {
  final double latitud;
  final double longitud;

  UbicacionGPS({required this.latitud, required this.longitud});
}

class FotografiasRegistro {
  final String urlHoja;
  final String urlFlor;
  final String urlFruto;
  final String urlPlantaCompleta;
  final String urlTalloCorteza;

  FotografiasRegistro({
    required this.urlHoja,
    required this.urlFlor,
    required this.urlFruto,
    required this.urlPlantaCompleta,
    required this.urlTalloCorteza,
  });
}

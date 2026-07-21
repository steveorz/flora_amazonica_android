import 'package:geolocator/geolocator.dart';

/// Espejo de `LocationError` (iOS, Core/Location/LocationProvider.swift).
sealed class LocationException implements Exception {
  const LocationException();
  String get message;
  @override
  String toString() => message;
}

class LocationDenied extends LocationException {
  const LocationDenied();
  @override
  String get message =>
      'Permite el acceso a tu ubicación en Ajustes para usar esta función.';
}

class LocationUnavailable extends LocationException {
  const LocationUnavailable();
  @override
  String get message => 'No se pudo obtener tu ubicación. Inténtalo de nuevo.';
}

/// Lectura puntual del GPS. Equivale a `LocationProvider.ubicacionActual()`,
/// que en iOS pide el permiso automáticamente la primera vez.
abstract final class LocationProvider {
  static Future<Position> ubicacionActual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable();
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    // `deniedForever` sólo se resuelve desde los Ajustes del sistema:
    // mismo caso que `authorizationRestricted` en iOS.
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      throw const LocationDenied();
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationUnavailable();
    }
  }
}

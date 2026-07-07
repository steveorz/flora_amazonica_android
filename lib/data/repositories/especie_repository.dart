import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../models/especie.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../features/registrador/wizard/wizard_provider.dart';

abstract class EspecieRepository {
  Future<List<Especie>> obtenerEspecies();
  Future<Especie> crearRegistro(EspecieDraft draft, String registradorId);
}

class RealEspecieRepository implements EspecieRepository {
  
  @override
  Future<List<Especie>> obtenerEspecies() async {
    List<Especie> all = [];
    
    // Fetch records
    try {
      final recordsJson = await apiClient.get("/especies");
      if (recordsJson is List) {
        all.addAll(recordsJson.map((e) => _mapToEspecie(e)).toList());
      }
    } catch (e) {
      print("Error fetching records: $e");
    }

    // Fetch catalog
    try {
      final catalogJson = await apiClient.get("/catalogo/especies");
      if (catalogJson is List) {
        all.addAll(catalogJson.map((e) => _mapCatalogToEspecie(e)).toList());
      }
    } catch (e) {
      print("Error fetching catalog: $e");
    }

    return all;
  }

  @override
  Future<Especie> crearRegistro(EspecieDraft draft, String registradorId) async {
    final body = {
      "scientific_name": draft.nombreCientifico,
      "family": draft.familia,
      "habit": draft.habito?.toString().split('.').last,
      "country_distribution": draft.distribucionPaises,
      "height": draft.altura,
      "crown_diameter": draft.diamCopaParalelo,
      "cap": draft.cap,
      "longitude": draft.lng,
      "latitude": draft.lat,
      "morphological_data": draft.caracteres,
      "is_draft": false,
      "author_name": draft.autorNombre,
      "life_type": draft.tipoVida.toString().split('.').last,
      "description": draft.descripcion,
      "species_catalog_id": draft.catalogId.isEmpty ? null : draft.catalogId,
    };

    final response = await apiClient.post("/especies", body: body);
    final especieId = response['id'];
    
    // Upload Photos
    final token = await secureStorage.getToken();
    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
    };

    for (var entry in draft.fotosData.entries) {
      final tipo = entry.key;
      final data = entry.value;

      final url = Uri.parse("${apiClient.baseUrl}/especies/fotos");
      var request = http.MultipartRequest("POST", url)
        ..headers.addAll(headers)
        ..fields['species_record_id'] = especieId
        ..fields['photo_type'] = tipo.toString().split('.').last
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          data,
          filename: 'foto_${tipo.name}.jpg',
        ));

      try {
        final streamedResponse = await request.send();
        final res = await http.Response.fromStream(streamedResponse);
        if (res.statusCode >= 300) {
          print("Error uploading photo ${tipo.name}: ${res.body}");
        }
      } catch (e) {
        print("Error uploading photo ${tipo.name}: $e");
      }
    }

    return _mapToEspecie(response);
  }

  Especie _mapToEspecie(dynamic json) {
    return Especie(
      id: json['id'],
      nombreCientifico: json['scientific_name'] ?? "Desconocido",
      autorNombre: json['author_name'] ?? "",
      familia: json['family'] ?? "Desconocida",
      nombreLocal: json['observation_notes'] ?? "",
      habito: Habito.values.firstWhere((e) => e.toString().split('.').last == json['habit'], orElse: () => Habito.arbol),
      tipoVida: TipoVida.values.firstWhere((e) => e.toString().split('.').last == json['life_type'], orElse: () => TipoVida.terrestre),
      distribucionPaises: (json['country_distribution'] as List?)?.map((e) => e.toString()).toList() ?? [],
      descripcion: json['description'] ?? "",
      caracteres: {}, // Ignored for simplicity in frontend list
      datosDasometricos: null, // Ignored for simplicity in frontend list
      ubicacion: Ubicacion(
        lat: json['latitude'] ?? -12.0, 
        long: json['longitude'] ?? -77.0, 
        referencia: "", altitud: 0.0, tipoHabitat: ""
      ),
      fotos: [], // Should map from json['photos'] if needed
      estado: EstadoRegistro.values.firstWhere((e) => e.name == json['status'], orElse: () => EstadoRegistro.enRevision),
      codigoSeguimiento: json['tracking_code'] ?? "",
      registradorId: json['registrar_id'] ?? "",
      fechaEnvio: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : DateTime.now(),
      historialEstados: [],
    );
  }

  Especie _mapCatalogToEspecie(dynamic json) {
    return Especie(
      id: json['id'],
      catalogId: json['id'],
      nombreCientifico: json['scientific_name'] ?? "Desconocido",
      autorNombre: "",
      familia: json['family'] ?? "Desconocida",
      nombreLocal: "Sin nombre común",
      habito: Habito.arbol,
      tipoVida: TipoVida.terrestre,
      distribucionPaises: [],
      descripcion: "Especie base del catálogo oficial importado.",
      caracteres: {},
      datosDasometricos: null,
      ubicacion: Ubicacion(lat: 0.0, long: 0.0, referencia: "", altitud: 0.0, tipoHabitat: ""),
      fotos: [],
      estado: (json['is_active'] ?? true) ? EstadoRegistro.validado : EstadoRegistro.borrador,
      codigoSeguimiento: "CAT-\(json['id'].substring(0, 6))",
      registradorId: "",
      fechaEnvio: DateTime.now(),
      historialEstados: [],
    );
  }
}

final especieRepositoryProvider = Provider<EspecieRepository>((ref) {
  return RealEspecieRepository();
});

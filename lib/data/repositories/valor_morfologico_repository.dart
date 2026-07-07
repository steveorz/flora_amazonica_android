import '../../models/valor_morfologico.dart';
import '../../models/campo_morfologico.dart';
import '../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ValorMorfologicoRepository {
  Future<List<ValorMorfologico>> listar();
  Future<List<CampoMorfologico>> obtenerCamposDinamicos(String habito);
  Future<void> actualizar(ValorMorfologico valor);
  Future<void> crear(ValorMorfologico valor);
  Future<void> eliminar(String codigo);
}

class RealValorMorfologicoRepository implements ValorMorfologicoRepository {
  final APIClient apiClient = APIClient.shared;

  @override
  Future<List<ValorMorfologico>> listar() async {
    final List<dynamic> records = await apiClient.request(endpoint: "/morfologia");
    return records.map((r) => ValorMorfologico(
      categoria: r['section'] ?? "",
      nombre: r['field_name'] ?? "",
      codigo: r['id'],
      orden: r['display_order'] ?? 0,
      activo: r['is_active'] ?? true,
    )).toList();
  }

  @override
  Future<List<CampoMorfologico>> obtenerCamposDinamicos(String habito) async {
    final List<dynamic> dtos = await apiClient.request(endpoint: "/morfologia");
    final habitoNormalizado = habito.toLowerCase(); // simplified folding
    
    final filtrados = dtos.where((dto) {
      final h = (dto['habit'] as String?)?.toLowerCase() ?? "";
      final active = dto['is_active'] as bool? ?? true;
      return active && h == habitoNormalizado;
    }).toList();

    Map<String, CampoMorfologico> camposDict = {};

    for (var dto in filtrados) {
      final section = dto['section'] as String?;
      final fieldName = dto['field_name'] as String?;
      final optionValue = dto['option_value'] as String?;
      
      if (section == null || fieldName == null || optionValue == null) continue;

      final key = "$section-$fieldName";
      final opcion = OpcionMorfologica(id: dto['id'], valor: optionValue, orden: dto['display_order'] ?? 0);

      if (camposDict.containsKey(key)) {
        if (optionValue.trim().isNotEmpty && optionValue != "N/A") {
          camposDict[key]!.opciones.add(opcion);
        }
      } else {
        List<OpcionMorfologica> opciones = [];
        if (optionValue.trim().isNotEmpty && optionValue != "N/A") {
          opciones.add(opcion);
        }

        camposDict[key] = CampoMorfologico(
          seccion: section,
          nombre: fieldName,
          tipoSeleccion: dto['selection_type'] ?? "single",
          tipoCampo: dto['field_type'] ?? "option",
          requerido: dto['is_required'] ?? false,
          orden: dto['display_order'] ?? 0,
          opciones: opciones,
        );
      }
    }

    final campos = camposDict.values.toList();
    for (var c in campos) {
      c.opciones.sort((a, b) => a.orden.compareTo(b.orden));
    }
    campos.sort((a, b) => a.orden.compareTo(b.orden));

    return campos;
  }

  @override
  Future<void> crear(ValorMorfologico valor) async {
    final body = {
      "habit": "Árbol",
      "section": valor.categoria,
      "field_name": valor.nombre,
      "option_value": "N/A",
      "selection_type": "single",
      "is_required": false,
      "display_order": valor.orden,
      "is_active": valor.activo
    };
    await apiClient.request(endpoint: "/morfologia", method: "POST", body: body);
  }

  @override
  Future<void> actualizar(ValorMorfologico valor) async {
    final body = {"is_active": valor.activo};
    await apiClient.request(endpoint: "/morfologia/${valor.codigo}/estado", method: "PATCH", body: body);
  }

  @override
  Future<void> eliminar(String codigo) async {
    final body = {"is_active": false};
    await apiClient.request(endpoint: "/morfologia/$codigo/estado", method: "PATCH", body: body);
  }
}

final valorMorfologicoRepositoryProvider = Provider<ValorMorfologicoRepository>((ref) {
  return RealValorMorfologicoRepository();
});

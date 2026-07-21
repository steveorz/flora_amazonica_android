import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../models/campo_morfologico.dart';
import '../models/valor_morfologico.dart';

abstract class ValorMorfologicoRepository {
  Future<List<ValorMorfologico>> listar();
  Future<List<CampoMorfologico>> obtenerCamposDinamicos(String habito);
  Future<void> crear(ValorMorfologico valor);
  Future<void> actualizar(ValorMorfologico valor);
  Future<void> eliminar(String codigo);
}

/// Quita tildes y pasa a minúsculas. Equivale a
/// `folding(options: .diacriticInsensitive).lowercased()` en iOS.
///
/// Hace falta porque el backend guarda el hábito con tilde ("Árbol") mientras
/// que el enum `Habito` lo emite sin ella ("arbol").
String _plegar(String s) {
  const conTilde = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
  const sinTilde = 'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC';
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    final idx = conTilde.indexOf(ch);
    buffer.write(idx >= 0 ? sinTilde[idx] : ch);
  }
  return buffer.toString().toLowerCase();
}

class RealValorMorfologicoRepository implements ValorMorfologicoRepository {
  @override
  Future<List<ValorMorfologico>> listar() async {
    final json = await apiClient.get('/morfologia');
    if (json is! List) return const [];
    return json.map((e) {
      final dto = e as Map<String, dynamic>;
      return ValorMorfologico(
        categoria: dto['section'] as String? ?? '',
        nombre: dto['field_name'] as String? ?? '',
        codigo: dto['id'] as String,
        orden: dto['display_order'] as int? ?? 0,
        activo: dto['is_active'] as bool? ?? true,
      );
    }).toList();
  }

  /// Arma el formulario dinámico del wizard para un hábito.
  ///
  /// Pedimos TODOS los campos sin filtro de hábito en la URL porque el backend
  /// tiene un bug con la sensibilidad a los acentos; filtramos en el cliente.
  /// (Mismo workaround y mismo comentario que en iOS.)
  @override
  Future<List<CampoMorfologico>> obtenerCamposDinamicos(String habito) async {
    final json = await apiClient.get('/morfologia');
    if (json is! List) return const [];

    final habitoNormalizado = _plegar(habito);

    // 1. Activos, y cuyo hábito coincida ignorando acentos y mayúsculas.
    final filtrados = json.cast<Map<String, dynamic>>().where((dto) {
      final h = dto['habit'] as String?;
      if (h == null) return false;
      return (dto['is_active'] as bool? ?? true) && _plegar(h) == habitoNormalizado;
    });

    // 2. Agrupar por (sección, field_name). Cada fila del backend es UNA opción.
    final campos = <String, CampoMorfologico>{};
    for (final dto in filtrados) {
      final seccion = dto['section'] as String?;
      final nombre = dto['field_name'] as String?;
      final valorOpcion = dto['option_value'] as String?;
      if (seccion == null || nombre == null || valorOpcion == null) continue;

      // "N/A" y las cadenas vacías son marcadores del backend para campos que
      // no son de opción (number/text): no deben convertirse en opciones.
      final esOpcionReal = valorOpcion.trim().isNotEmpty && valorOpcion != 'N/A';
      final opcion = OpcionMorfologica(
        id: dto['id'] as String,
        valor: valorOpcion,
        orden: dto['display_order'] as int? ?? 0,
      );

      final key = '$seccion-$nombre';
      final existente = campos[key];
      if (existente != null) {
        if (esOpcionReal) existente.opciones.add(opcion);
      } else {
        campos[key] = CampoMorfologico(
          seccion: seccion,
          nombre: nombre,
          tipoSeleccion: dto['selection_type'] as String? ?? 'single',
          tipoCampo: dto['field_type'] as String? ?? 'option',
          requerido: dto['is_required'] as bool? ?? false,
          orden: dto['display_order'] as int? ?? 0,
          opciones: esOpcionReal ? [opcion] : [],
        );
      }
    }

    // 3. Ordenar opciones dentro de cada campo, y los campos entre sí.
    final resultado = campos.values.toList();
    for (final campo in resultado) {
      campo.opciones.sort((a, b) => a.orden.compareTo(b.orden));
    }
    resultado.sort((a, b) => a.orden.compareTo(b.orden));
    return resultado;
  }

  @override
  Future<void> crear(ValorMorfologico valor) async {
    await apiClient.post('/morfologia', body: {
      'habit': 'Árbol', // Placeholder del panel de Admin, igual que en iOS.
      'section': valor.categoria,
      'field_name': valor.nombre,
      'option_value': 'N/A',
      'selection_type': 'single',
      'is_required': false,
      'display_order': valor.orden,
      'is_active': valor.activo,
    });
  }

  /// El backend sólo expone alternar el estado activo.
  @override
  Future<void> actualizar(ValorMorfologico valor) async {
    await apiClient.patch('/morfologia/${valor.codigo}/estado', body: {'is_active': valor.activo});
  }

  /// Borrado lógico: se desactiva, no se elimina.
  @override
  Future<void> eliminar(String codigo) async {
    await apiClient.patch('/morfologia/$codigo/estado', body: {'is_active': false});
  }
}

final valorMorfologicoRepositoryProvider =
    Provider<ValorMorfologicoRepository>((ref) => RealValorMorfologicoRepository());

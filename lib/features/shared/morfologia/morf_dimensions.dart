/// Una opción concreta dentro de una dimensión morfológica.
///
/// Cada opción tiene varios `stems` (raíces) que se buscan como substrings en
/// los caracteres y la descripción de la especie. Así se matchean variaciones
/// de género y número del español ("amarillo" / "amarillenta").
class MorfOpcion {
  final String label;
  final List<String> stems;

  const MorfOpcion(this.label, this.stems);

  String get id => label;
}

class MorfDimension {
  final String id;
  final String categoria;
  final String titulo;
  final List<MorfOpcion> opciones;

  const MorfDimension({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.opciones,
  });
}

/// Dimensiones y opciones para la búsqueda morfológica.
/// Espejo de `MorfDimensions` (iOS).
abstract final class MorfDimensions {
  static const categorias = ['Florales', 'Fruto', 'Semilla', 'Vegetativo'];

  static const todas = <MorfDimension>[
    // ─── Florales ───
    MorfDimension(id: 'color_flor', categoria: 'Florales', titulo: 'Color de flor', opciones: [
      MorfOpcion('Blanco', ['blanc']),
      MorfOpcion('Amarillo', ['amarill']),
      MorfOpcion('Rosa', ['rosa', 'rosad']),
      MorfOpcion('Rojo', ['roj']),
      MorfOpcion('Morado', ['morad', 'violet']),
      MorfOpcion('Verde', ['verd']),
      MorfOpcion('Naranja', ['naranj']),
      MorfOpcion('Crema', ['crem']),
    ]),
    MorfDimension(
        id: 'inflorescencia',
        categoria: 'Florales',
        titulo: 'Inflorescencia',
        opciones: [
          MorfOpcion('Panícula', ['panícul', 'paníc']),
          MorfOpcion('Racimo', ['racim']),
          MorfOpcion('Espiga', ['espig']),
          MorfOpcion('Umbela', ['umbel']),
          MorfOpcion('Cabezuela', ['cabezuel']),
          MorfOpcion('Solitaria', ['solitar']),
        ]),

    // ─── Fruto ───
    MorfDimension(id: 'color_fruto', categoria: 'Fruto', titulo: 'Color de fruto', opciones: [
      MorfOpcion('Verde', ['verd']),
      MorfOpcion('Amarillo', ['amarill']),
      MorfOpcion('Rojo', ['roj']),
      MorfOpcion('Negro', ['negr', 'oscur']),
      MorfOpcion('Marrón', ['marró', 'pard', 'café']),
      MorfOpcion('Naranja', ['naranj']),
      MorfOpcion('Morado', ['morad', 'violet']),
    ]),
    MorfDimension(id: 'tipo_fruto', categoria: 'Fruto', titulo: 'Tipo de fruto', opciones: [
      MorfOpcion('Seco', ['cápsul', 'legumbr', 'sámar', 'leñoso', 'leñosa']),
      MorfOpcion('Carnoso', ['drup', 'carnos', 'baya']),
      MorfOpcion('Cápsula', ['cápsul']),
      MorfOpcion('Drupa', ['drup']),
      MorfOpcion('Legumbre', ['legumbr']),
      MorfOpcion('Sámara', ['sámar']),
    ]),
    MorfDimension(
        id: 'tamano_fruto',
        categoria: 'Fruto',
        titulo: 'Tamaño de fruto',
        opciones: [
          MorfOpcion('Pequeño', ['pequeñ']),
          MorfOpcion('Mediano', ['median']),
          MorfOpcion('Grande', ['grand']),
        ]),

    // ─── Semilla ───
    MorfDimension(
        id: 'tipo_semilla',
        categoria: 'Semilla',
        titulo: 'Tipo de semilla',
        opciones: [
          MorfOpcion('Alada', ['alad', ' ala']),
          MorfOpcion('Fibrosa', ['fibr']),
          MorfOpcion('Aromática', ['aromát']),
          MorfOpcion('Redonda', ['redond', 'globos', 'esféric']),
        ]),

    // ─── Vegetativo ───
    MorfDimension(id: 'tipo_hoja', categoria: 'Vegetativo', titulo: 'Tipo de hoja', opciones: [
      MorfOpcion('Simple', ['simple']),
      MorfOpcion('Compuesta', ['compuesta', 'pinnad', 'palmad']),
      MorfOpcion('Pinnada', ['pinnad']),
      MorfOpcion('Palmada', ['palmad', 'palmar']),
      MorfOpcion('Opuesta', ['opuest']),
      MorfOpcion('Alterna', ['altern']),
    ]),
    MorfDimension(
        id: 'exudado',
        categoria: 'Vegetativo',
        titulo: 'Color de exudado / látex',
        opciones: [
          MorfOpcion('Transparente', ['transparent', 'incoloro']),
          MorfOpcion('Blanco', ['látex blanc', 'savia blanc']),
          MorfOpcion('Rojo', ['látex roj', 'savia roj', 'sangre']),
          MorfOpcion('Amarillo', ['látex amarill', 'resina amarill']),
        ]),
    MorfDimension(
        id: 'espinas',
        categoria: 'Vegetativo',
        titulo: 'Espinas / aguijones',
        opciones: [
          MorfOpcion('Presentes', ['espin', 'aguijo']),
        ]),
  ];

  static List<MorfDimension> deCategoria(String categoria) =>
      todas.where((d) => d.categoria == categoria).toList();
}

import 'package:flutter/material.dart';

enum Habito {
  arbol,
  palmera,
  arbusto,
  liana,
  hierba;

  /// iOS cae a `.arbol` cuando el backend manda un hábito desconocido o nulo.
  static Habito fromRaw(String? raw) => Habito.values.firstWhere(
        (e) => e.name == raw?.toLowerCase(),
        orElse: () => Habito.arbol,
      );

  /// Ruta del asset con la foto representativa de la categoría.
  String get categoryAsset => 'assets/images/${name}_category.jpg';

  String get label {
    switch (this) {
      case Habito.arbol:
        return "Árbol";
      case Habito.palmera:
        return "Palmera";
      case Habito.arbusto:
        return "Arbusto";
      case Habito.liana:
        return "Liana";
      case Habito.hierba:
        return "Hierba";
    }
  }

  Color get color {
    switch (this) {
      case Habito.arbol:
        return Colors.blue;
      case Habito.palmera:
        return Colors.yellow;
      case Habito.arbusto:
        return Colors.tealAccent; // mint equivalent
      case Habito.liana:
        return Colors.brown;
      case Habito.hierba:
        return Colors.teal;
    }
  }

  String get categoryImage {
    switch (this) {
      case Habito.arbol:
        return "arbol_category";
      case Habito.palmera:
        return "palmera_category";
      case Habito.arbusto:
        return "arbusto_category";
      case Habito.liana:
        return "liana_category";
      case Habito.hierba:
        return "hierba_category";
    }
  }
}

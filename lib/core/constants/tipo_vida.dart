enum TipoVida {
  terrestre,
  epifita,
  parasita;

  /// iOS cae a `.terrestre` cuando el backend manda un tipo desconocido o nulo.
  static TipoVida fromRaw(String? raw) => TipoVida.values.firstWhere(
        (e) => e.name == raw?.toLowerCase(),
        orElse: () => TipoVida.terrestre,
      );

  String get label {
    switch (this) {
      case TipoVida.terrestre:
        return "Terrestre";
      case TipoVida.epifita:
        return "Epífita";
      case TipoVida.parasita:
        return "Parásita";
    }
  }
  String get categoryAsset {
    switch (this) {
      case TipoVida.terrestre:
        return 'assets/images/terrestre.png';
      case TipoVida.epifita:
        return 'assets/images/epifita.png';
      case TipoVida.parasita:
        return 'assets/images/parasita.png';
    }
  }
}

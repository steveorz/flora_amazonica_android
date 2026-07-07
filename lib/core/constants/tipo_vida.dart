enum TipoVida {
  terrestre,
  epifita,
  parasita;

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
}

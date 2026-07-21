enum Rol {
  registrador,
  consultor,
  administrador,
  validador;

  /// El backend envía el rol en minúsculas; iOS cae a `.consultor` si no coincide.
  static Rol fromRaw(String? raw) => Rol.values.firstWhere(
        (e) => e.name == raw?.toLowerCase(),
        orElse: () => Rol.consultor,
      );

  String get label {
    switch (this) {
      case Rol.registrador:
        return "Registrador";
      case Rol.consultor:
        return "Consultor";
      case Rol.administrador:
        return "Administrador";
      case Rol.validador:
        return "Validador";
    }
  }
}

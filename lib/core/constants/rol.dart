enum Rol {
  registrador,
  consultor,
  administrador,
  validador;

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

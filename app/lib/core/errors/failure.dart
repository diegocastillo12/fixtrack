sealed class Failure {
  const Failure(this.mensaje);

  final String mensaje;
}

final class SinConexion extends Failure {
  const SinConexion() : super('Sin conexión. Revise su red.');
}

final class TiempoAgotado extends Failure {
  const TiempoAgotado() : super('El servidor tardó demasiado.');
}

final class NoAutorizado extends Failure {
  const NoAutorizado() : super('Su sesión expiró.');
}

final class SinPermiso extends Failure {
  const SinPermiso() : super('No tiene permiso para esta acción.');
}

final class NoEncontrado extends Failure {
  const NoEncontrado() : super('No se encontró lo solicitado.');
}

final class ErrorValidacion extends Failure {
  const ErrorValidacion(super.mensaje);
}

final class Conflicto extends Failure {
  const Conflicto() : super('El recurso cambió. Actualice e intente de nuevo.');
}

final class DemasiadasPeticiones extends Failure {
  const DemasiadasPeticiones()
    : super('Demasiadas solicitudes. Espere un momento.');
}

final class ErrorServidor extends Failure {
  const ErrorServidor() : super('Error del servidor. Intente más tarde.');
}

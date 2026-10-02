import 'incidencia.dart';

class IncidenciaValidator {
  bool esValida(Incidencia incidencia) {
    return incidencia.titulo.trim().isNotEmpty &&
        incidencia.descripcion.trim().isNotEmpty &&
        incidencia.estado.trim().isNotEmpty;
  }
}
import 'incidencia.dart';

abstract class IncidenciaRepository {
  Future<List<Incidencia>> obtenerIncidencias();
}
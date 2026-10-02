import '../domain/incidencia.dart';
import 'incidencia_dto.dart';

class IncidenciaMapper {
  static Incidencia toDomain(IncidenciaDto dto) {
    return Incidencia(
      id: dto.id,
      titulo: dto.titulo,
      descripcion: dto.descripcion,
      estado: dto.estado,
    );
  }
}
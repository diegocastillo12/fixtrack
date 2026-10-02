class IncidenciaDto {
  final Object id;
  final String titulo;
  final String descripcion;
  final String estado;

  const IncidenciaDto({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.estado,
  });

  factory IncidenciaDto.fromJson(Map<String, dynamic> json) {
    return IncidenciaDto(
      id: json['id'] as Object,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      estado: json['estado'] as String,
    );
  }
}
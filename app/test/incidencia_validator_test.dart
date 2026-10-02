import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/incidencias/domain/incidencia.dart';
import 'package:app/features/incidencias/domain/incidencia_validator.dart';

void main() {
  final validator = IncidenciaValidator();

  test('incidencia valida devuelve true', () {
    const incidencia = Incidencia(
      id: 1,
      titulo: 'Falla en lector QR',
      descripcion: 'El lector no responde',
      estado: 'Pendiente',
    );

    expect(validator.esValida(incidencia), isTrue);
  });

  test('incidencia sin titulo devuelve false', () {
    const incidencia = Incidencia(
      id: 1,
      titulo: '',
      descripcion: 'El lector no responde',
      estado: 'Pendiente',
    );

    expect(validator.esValida(incidencia), isFalse);
  });
}
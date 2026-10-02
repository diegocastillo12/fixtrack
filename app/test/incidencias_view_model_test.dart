import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/incidencias/domain/incidencia.dart';
import 'package:app/features/incidencias/domain/incidencia_repository.dart';
import 'package:app/features/incidencias/presentation/incidencias_view_model.dart';

class FakeRepositoryExito implements IncidenciaRepository {
  @override
  Future<List<Incidencia>> obtenerIncidencias() async {
    return const [
      Incidencia(
        id: 1,
        titulo: 'Incidencia de prueba',
        descripcion: 'Descripción de prueba',
        estado: 'Pendiente',
      ),
    ];
  }
}

class FakeRepositoryVacio implements IncidenciaRepository {
  @override
  Future<List<Incidencia>> obtenerIncidencias() async {
    return [];
  }
}

class FakeRepositoryError implements IncidenciaRepository {
  @override
  Future<List<Incidencia>> obtenerIncidencias() async {
    throw Exception('Error de prueba');
  }
}

void main() {
  test('carga incidencias correctamente', () async {
    final viewModel = IncidenciasViewModel(FakeRepositoryExito());

    await viewModel.cargarIncidencias();

    expect(viewModel.estado, IncidenciasEstado.exito);
    expect(viewModel.incidencias.length, 1);
  });

  test('muestra estado vacio cuando no hay incidencias', () async {
    final viewModel = IncidenciasViewModel(FakeRepositoryVacio());

    await viewModel.cargarIncidencias();

    expect(viewModel.estado, IncidenciasEstado.vacio);
    expect(viewModel.incidencias, isEmpty);
  });

  test('muestra estado error cuando falla el repositorio', () async {
    final viewModel = IncidenciasViewModel(FakeRepositoryError());

    await viewModel.cargarIncidencias();

    expect(viewModel.estado, IncidenciasEstado.error);
    expect(viewModel.mensajeError, isNotEmpty);
  });
}
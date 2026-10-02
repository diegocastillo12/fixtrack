import 'package:flutter/foundation.dart';
import '../domain/incidencia.dart';
import '../domain/incidencia_repository.dart';

enum IncidenciasEstado {
  inicial,
  cargando,
  exito,
  vacio,
  error,
}

class IncidenciasViewModel extends ChangeNotifier {
  final IncidenciaRepository repository;

  IncidenciasViewModel(this.repository);

  IncidenciasEstado estado = IncidenciasEstado.inicial;
  List<Incidencia> incidencias = [];
  String mensajeError = '';

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> cargarIncidencias() async {
    if (_disposed) return;

    estado = IncidenciasEstado.cargando;
    mensajeError = '';
    notifyListeners();

    try {
      final resultado = await repository.obtenerIncidencias();

      if (_disposed) return; // widget ya no existe

      if (resultado.isEmpty) {
        incidencias = [];
        estado = IncidenciasEstado.vacio;
      } else {
        incidencias = resultado;
        estado = IncidenciasEstado.exito;
      }
    } catch (e) {
      if (_disposed) return;
      incidencias = [];
      mensajeError = 'No se pudieron cargar las incidencias.';
      estado = IncidenciasEstado.error;
    }

    if (!_disposed) notifyListeners();
  }
}
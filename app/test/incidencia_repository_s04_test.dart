import 'package:app/features/incidencias/data/incidencia_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('S04 - Repositorio de incidencias', () {
    late Dio dio;
    late DioAdapter adapter;
    late IncidenciaRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});

      dio = Dio(BaseOptions(baseUrl: 'http://localhost:4010'));

      adapter = DioAdapter(dio: dio);

      repository = IncidenciaRepositoryImpl(dio: dio);
    });

    test('GET /incidencias devuelve incidencias correctamente', () async {
      adapter.onGet(
        '/incidencias',
        (server) => server.reply(200, {
          'data': [
            {
              'id': 1,
              'titulo': 'Proyector sin señal',
              'descripcion': 'El proyector del laboratorio no responde',
              'estado': 'Pendiente',
            },
            {
              'id': 2,
              'titulo': 'Mouse defectuoso',
              'descripcion': 'El mouse no funciona correctamente',
              'estado': 'En proceso',
            },
          ],
        }),
        queryParameters: {'limit': 20},
      );

      final resultado = await repository.obtenerIncidencias();

      expect(resultado, hasLength(2));
      expect(resultado.first.id, 1);
      expect(resultado.first.titulo, 'Proyector sin señal');
    });

    test('POST /incidencias envía Idempotency-Key', () async {
      String? idempotencyKey;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            idempotencyKey = options.headers['Idempotency-Key']?.toString();

            handler.next(options);
          },
        ),
      );

      adapter.onPost(
        '/incidencias',
        (server) => server.reply(201, {
          'id': 10,
          'titulo': 'Teclado dañado',
          'descripcion': 'Varias teclas no responden',
          'estado': 'Pendiente',
        }),
        data: {
          'titulo': 'Teclado dañado',
          'descripcion': 'Varias teclas no responden',
        },
      );

      final resultado = await repository.crearIncidencia(
        titulo: 'Teclado dañado',
        descripcion: 'Varias teclas no responden',
      );

      expect(resultado.id, 10);
      expect(idempotencyKey, isNotNull);
      expect(idempotencyKey, isNotEmpty);
    });

    test('400 no se considera una respuesta exitosa', () async {
      adapter.onGet(
        '/incidencias',
        (server) => server.reply(400, {'message': 'Solicitud inválida'}),
        queryParameters: {'limit': 20},
      );

      expect(
        () => repository.obtenerIncidencias(),
        throwsA(isA<DioException>()),
      );
    });

    test('422 devuelve error de validación HTTP', () async {
      adapter.onPost(
        '/incidencias',
        (server) =>
            server.reply(422, {'message': 'Los datos enviados no son válidos'}),
        data: {'titulo': '', 'descripcion': ''},
      );

      expect(
        () => repository.crearIncidencia(titulo: '', descripcion: ''),
        throwsA(isA<DioException>()),
      );
    });
  });
}

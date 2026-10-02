import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('S04 - DioClient y reintentos', () {
    test('HTTP 400 no realiza reintentos', () async {
      final cliente = DioClient(
        baseUrl: 'http://localhost:4010',
        tokenProvider: () async => 'token-prueba',
      );

      final adapter = _FakeAdapter(
        responder: (int intento, RequestOptions options) {
          return const _RespuestaFake(
            statusCode: 400,
            body: {'message': 'Solicitud inválida'},
          );
        },
      );

      cliente.dio.httpClientAdapter = adapter;

      await expectLater(
        cliente.dio.get<dynamic>('/prueba-400'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.numeroPeticiones, 1);
    });

    test('HTTP 503 realiza máximo 3 reintentos', () async {
      final cliente = DioClient(
        baseUrl: 'http://localhost:4010',
        tokenProvider: () async => 'token-prueba',
      );

      final adapter = _FakeAdapter(
        responder: (int intento, RequestOptions options) {
          return const _RespuestaFake(
            statusCode: 503,
            body: {'message': 'Servicio no disponible'},
          );
        },
      );

      cliente.dio.httpClientAdapter = adapter;

      await expectLater(
        cliente.dio.get<dynamic>('/prueba-503'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.numeroPeticiones, 4);
    });

    test('HTTP 429 respeta Retry-After antes de reintentar', () async {
      final cliente = DioClient(
        baseUrl: 'http://localhost:4010',
        tokenProvider: () async => 'token-prueba',
      );

      final tiempos = <DateTime>[];

      final adapter = _FakeAdapter(
        responder: (int intento, RequestOptions options) {
          tiempos.add(DateTime.now());

          return const _RespuestaFake(
            statusCode: 429,
            body: {'message': 'Demasiadas solicitudes'},
            headers: {
              'retry-after': ['1'],
            },
          );
        },
      );

      cliente.dio.httpClientAdapter = adapter;

      await expectLater(
        cliente.dio.get<dynamic>('/prueba-429'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.numeroPeticiones, 4);
      expect(tiempos, hasLength(4));

      for (var i = 1; i < tiempos.length; i++) {
        final diferencia = tiempos[i].difference(tiempos[i - 1]);

        expect(diferencia.inMilliseconds, greaterThanOrEqualTo(900));
      }
    });
  });
}

class _RespuestaFake {
  const _RespuestaFake({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final Object body;
  final Map<String, List<String>> headers;
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.responder});

  final _RespuestaFake Function(int intento, RequestOptions options) responder;

  int numeroPeticiones = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    numeroPeticiones++;

    final respuesta = responder(numeroPeticiones, options);

    return ResponseBody.fromString(
      jsonEncode(respuesta.body),
      respuesta.statusCode,
      headers: {
        'content-type': ['application/json'],
        ...respuesta.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

class DioClient {
  DioClient({
    required String baseUrl,
    required Future<String?> Function() tokenProvider,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // 1. Autenticación.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenProvider();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );

    // 2. Registro seguro solo en modo debug.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          assert(() {
            final headers = Map<String, dynamic>.from(options.headers);

            for (final key in headers.keys.toList()) {
              final lower = key.toLowerCase();

              if (lower == 'authorization' ||
                  lower == 'cookie' ||
                  lower == 'set-cookie') {
                headers[key] = '***';
              }
            }

            developer.log(
              '→ ${options.method} ${options.uri} headers=$headers',
              name: 'FixTrack HTTP',
            );

            return true;
          }());

          handler.next(options);
        },
        onResponse: (response, handler) {
          assert(() {
            developer.log(
              '← ${response.statusCode} ${response.requestOptions.uri}',
              name: 'FixTrack HTTP',
            );

            return true;
          }());

          handler.next(response);
        },
        onError: (error, handler) {
          assert(() {
            developer.log(
              '✕ ${error.response?.statusCode ?? 'SIN RESPUESTA'} '
              '${error.requestOptions.uri}',
              name: 'FixTrack HTTP',
            );

            return true;
          }());

          handler.next(error);
        },
      ),
    );

    // 3. Reintentos.
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final request = error.requestOptions;
          final statusCode = error.response?.statusCode;
          final intentos = request.extra['retryCount'] as int? ?? 0;

          final reintentable =
              statusCode == null ||
              statusCode == 429 ||
              (statusCode >= 500 && statusCode <= 599);

          if (!reintentable || intentos >= 3) {
            return handler.next(error);
          }

          Duration espera;

          if (statusCode == 429) {
            final retryAfterHeader =
                error.response?.headers.value('retry-after');

            final segundos = int.tryParse(retryAfterHeader ?? '');

            espera = segundos != null
                ? Duration(seconds: segundos)
                : Duration(milliseconds: 400 * (1 << intentos));
          } else {
            espera = Duration(
              milliseconds: 400 * (1 << intentos),
            );
          }

          request.extra['retryCount'] = intentos + 1;

          await Future<void>.delayed(espera);

          try {
            final response = await dio.fetch<dynamic>(request);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        },
      ),
    );
  }

  late final Dio dio;
}
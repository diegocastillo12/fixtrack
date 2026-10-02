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

    // Interceptor de autenticación.
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

    // Interceptor de registro seguro.
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (object) {
          developer.log('$object', name: 'FixTrack HTTP');
        },
      ),
    );

    // Interceptor de reintentos.
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final request = error.requestOptions;
          final retries = request.extra['retryCount'] as int? ?? 0;

          final retryable =
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              error.response?.statusCode == 503 ||
              error.response?.statusCode == 429;

          if (retryable && retries < 3) {
            request.extra['retryCount'] = retries + 1;

            final retryAfter = error.response?.headers.value('retry-after');
            final retryAfterSeconds = int.tryParse(retryAfter ?? '');
            final delay = retryAfterSeconds != null
              ? Duration(seconds: retryAfterSeconds)
              : Duration(seconds: 1 << retries);

            await Future<void>.delayed(delay);

            try {
              final response = await dio.fetch<dynamic>(request);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  late final Dio dio;
}

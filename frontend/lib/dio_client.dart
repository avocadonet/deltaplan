// lib/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

/// Централизованный HTTP-клиент на основе Dio.
/// Настроен для автоматического добавления токена авторизации.
class DioClient {
  // Приватный конструктор, чтобы предотвратить создание экземпляров извне.
  DioClient._();

  // Создаем единственный "настроенный" экземпляр Dio для запросов, требующих токен.
  static final Dio configuredDio = _createConfiguredDio();

  // Создаем "чистый" экземпляр Dio для публичных запросов (логин, регистрация).
  static final Dio publicDio = Dio(BaseOptions(baseUrl: AppConfig.apiUrl));

  static Dio _createConfiguredDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          const storage = FlutterSecureStorage();
          final accessToken = await storage.read(key: 'access_token');

          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Здесь можно добавить логику обновления токена, если потребуется.
          return handler.next(e);
        },
      ),
    );
    return dio;
  }
}
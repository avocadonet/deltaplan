import 'package:flutter/foundation.dart'; // <-- ИМПОРТИРУЕМ ДЛЯ kReleaseMode
import 'package:universal_io/io.dart';

class AppConfig {
  // URL для локальной разработки на вебе
  static const String _apiUrlWebDev = 'http://127.0.0.1:8000/api/';

  // URL для локальной разработки на эмуляторе Android
  static const String _apiUrlAndroidDev = 'http://10.0.2.2:8000/api/';

  // URL для продакшена (любая платформа)
  // Это относительный путь. Браузер сам подставит домен (https://deltaplanonline.ru)
  static const String _apiUrlProduction = '/api/';

  static String get apiUrl {
    // kReleaseMode - это константа Flutter.
    // true - если сборка релизная (flutter build)
    // false - если сборка отладочная (flutter run)
    if (kReleaseMode) {
      // Если это релизная сборка, всегда используем продакшен URL.
      return _apiUrlProduction;
    } else {
      // Если это отладочная сборка, определяем платформу.
      if (Platform.isAndroid) {
        return _apiUrlAndroidDev;
      }
      // Для всех остальных платформ в режиме отладки (Web, Desktop)
      return _apiUrlWebDev;
    }
  }
}
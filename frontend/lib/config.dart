import 'package:universal_io/io.dart';

class AppConfig {
  static const String _apiUrlWeb = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000/api/',
  );

  static const String _apiUrlAndroid = String.fromEnvironment(
    'API_URL_ANDROID',
    defaultValue: 'http://10.0.2.2:8000/api/',
  );

  static String get apiUrl {
    if (Platform.isAndroid) {
      return _apiUrlAndroid;
    }
    return _apiUrlWeb;
  }
}
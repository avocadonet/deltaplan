class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000/api/',
  );
  
  static const String apiUrlAndroid = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000/api/',
  );
}
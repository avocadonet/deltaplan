import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart'; // <-- Важный импорт для kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'config.dart'; // <-- Используем наш универсальный конфиг

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating
}

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  AuthStatus _status = AuthStatus.uninitialized;
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userData;
  Timer? _authTimer;

  AuthStatus get status => _status;
  String? get token => _accessToken;
  Map<String, dynamic>? get userData => _userData;

  /// КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: Универсальный построитель URL
  /// Этот метод сам определяет, для какой платформы он собирает URL.
  Uri _buildUri(String endpoint) {
    // 1. Убираем слэш в начале эндпоинта, если он есть
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

    // 2. Определяем базовый URL: пустой для веба, полный для мобильных
    final String baseUrl = kIsWeb ? '' : AppConfig.productionApiDomain;

    // 3. Собираем финальный URL и возвращаем его
    // Для Web получится: /api/token/
    // Для Android получится: https://deltaplanonline.ru/api/token/
    return Uri.parse('$baseUrl/api/$cleanEndpoint');
  }


  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final storedAccessToken = await _storage.read(key: 'access_token');
    final storedRefreshToken = await _storage.read(key: 'refresh_token');

    if (storedAccessToken == null || storedRefreshToken == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    if (JwtDecoder.isExpired(storedAccessToken)) {
      _refreshToken = storedRefreshToken;
      if (!await _refreshTokens()) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
    } else {
      _accessToken = storedAccessToken;
      _refreshToken = storedRefreshToken;
    }

    await _fetchUserData();
    if (_status != AuthStatus.unauthenticated) {
      _status = AuthStatus.authenticated;
      _scheduleTokenRefresh();
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    final url = _buildUri('token/'); // <-- ИСПРАВЛЕНО
    try {
      developer.log('Attempting to POST to $url with username: $username', name: 'AuthProvider');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        _accessToken = responseData['access'];
        _refreshToken = responseData['refresh'];

        await _storage.write(key: 'access_token', value: _accessToken);
        await _storage.write(key: 'refresh_token', value: _refreshToken);

        await _fetchUserData();
        _status = AuthStatus.authenticated;
        _scheduleTokenRefresh();
        notifyListeners();
        return true;
      } else {
        developer.log(
          'Login failed with status ${response.statusCode}: ${response.body}',
          name: 'AuthProvider',
        );
      }
    } catch (e, s) {
      developer.log(
        'Login error',
        name: 'AuthProvider',
        error: e,
        stackTrace: s,
      );
    }

    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String password, String password2, String email, String firstName, String lastName) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    final url = _buildUri('register/'); // <-- ИСПРАВЛЕНО
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'username': username,
          'password': password,
          'password2': password2,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );

      if (response.statusCode == 201) {
        return await login(username, password);
      } else {
        developer.log(
          'Registration failed with status ${response.statusCode}: ${response.body}',
          name: 'AuthProvider',
        );
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      developer.log(
        'Registration error',
        name: 'AuthProvider',
        error: e,
        stackTrace: s,
      );
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchUserData() async {
    if (_accessToken == null) return;

    final Map<String, dynamic> decodedToken = JwtDecoder.decode(_accessToken!);
    final userId = decodedToken['user_id'];

    if (userId == null) {
      developer.log('User ID not found in token', name: 'AuthProvider');
      await logout();
      return;
    }

    final url = _buildUri('users/$userId/'); // <-- ИСПРАВЛЕНО
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      });

      if (response.statusCode == 200) {
        _userData = json.decode(utf8.decode(response.bodyBytes));
      } else {
        developer.log(
          'Failed to fetch user data: ${response.statusCode}',
          name: 'AuthProvider',
        );
        await logout();
      }
    } catch (e, s) {
      developer.log(
        'Error fetching user data',
        name: 'AuthProvider',
        error: e,
        stackTrace: s,
      );
      await logout();
    }
  }

  Future<bool> _refreshTokens() async {
    _refreshToken ??= await _storage.read(key: 'refresh_token');
    if (_refreshToken == null) return false;

    final url = _buildUri('token/refresh/'); // <-- ИСПРАВЛЕНО
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _accessToken = responseData['access'];
        await _storage.write(key: 'access_token', value: _accessToken);
        if (responseData.containsKey('refresh')) {
           _refreshToken = responseData['refresh'];
           await _storage.write(key: 'refresh_token', value: _refreshToken);
        }
        return true;
      } else {
        developer.log(
          'Token refresh failed with status ${response.statusCode}',
          name: 'AuthProvider',
        );
        await logout();
      }
    } catch (e, s) {
      developer.log(
        'Token refresh error',
        name: 'AuthProvider',
        error: e,
        stackTrace: s,
      );
      await logout();
    }
    return false;
  }

  void _scheduleTokenRefresh() {
    _authTimer?.cancel();
    if (_accessToken == null) return;

    final expiryDate = JwtDecoder.getExpirationDate(_accessToken!);
    final timeToExpiry = expiryDate.difference(DateTime.now()).inSeconds;
    final duration = Duration(seconds: timeToExpiry > 60 ? timeToExpiry - 60 : 0);

    _authTimer = Timer(duration, () async {
      if (await _refreshTokens()) {
        _scheduleTokenRefresh();
        notifyListeners();
      }
    });
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _userData = null;
    _status = AuthStatus.unauthenticated;
    _authTimer?.cancel();
    await _storage.deleteAll();
    notifyListeners();
  }
}
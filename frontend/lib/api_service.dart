import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_io/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/';
    } else {
      return 'http://127.0.0.1:8000/api/';
    }
  }

  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (includeAuth) {
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<List<dynamic>> _fetchData(String endpoint,
      {bool authenticated = true}) async {
    try {
      final headers = await _getHeaders(includeAuth: authenticated);
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody) as List<dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Ошибка авторизации. Пожалуйста, войдите снова.');
      } else {
        throw Exception(
            'Ошибка загрузки данных с $endpoint. Код: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка подключения к серверу для $endpoint: $e');
    }
  }

  Future<List<dynamic>> fetchEvents() =>
      _fetchData('events/', authenticated: true);
  Future<List<dynamic>> fetchCalendarEvents() =>
      _fetchData('calendar-events/', authenticated: true);
  Future<List<dynamic>> fetchSafetyTrains() =>
      _fetchData('safety-trains/', authenticated: false);
  Future<List<dynamic>> fetchMuseumTasks() =>
      _fetchData('museum-tasks/', authenticated: false);
  Future<List<dynamic>> fetchAlumni() =>
      _fetchData('alumni/', authenticated: true);
  Future<List<dynamic>> fetchParentSchoolEvents() =>
      _fetchData('parent-school-events/', authenticated: true);
  Future<List<dynamic>> fetchParentClubEntries() =>
      _fetchData('parent-club/', authenticated: true);
  Future<List<dynamic>> fetchGenericData(String endpoint) =>
      _fetchData(endpoint, authenticated: true);

  Future<Map<String, dynamic>> fetchMyApplications() async {
    final headers = await _getHeaders(includeAuth: true);
    if (headers['Authorization'] == null) {
      return {'upcoming_approved': [], 'upcoming_pending': [], 'archived': []};
    }
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}my-applications/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      } else {
        throw Exception('Ошибка загрузки заявок: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка подключения для заявок: $e');
    }
  }

  Future<Map<String, dynamic>> applyForEvent(int eventId) async {
    final headers = await _getHeaders(includeAuth: true);
    if (headers['Authorization'] == null) {
      return {'success': false, 'message': 'Пожалуйста, авторизуйтесь.'};
    }
    final url = Uri.parse('${_baseUrl}applications/');
    final body = json.encode({'event_id': eventId});
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Заявка успешно подана!'};
      }
      final errorData = json.decode(utf8.decode(response.bodyBytes));
      return {
        'success': false,
        'message': errorData['detail'] ?? 'Произошла ошибка.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети.'};
    }
  }

  Future<Map<String, dynamic>> registerForParentSchool(int eventId) async {
    final headers = await _getHeaders(includeAuth: true);
    if (headers['Authorization'] == null) {
      return {'success': false, 'message': 'Пожалуйста, авторизуйтесь.'};
    }
    final url = Uri.parse('${_baseUrl}parent-school-registrations/');
    final body = json.encode({'event': eventId});
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Вы успешно зарегистрированы!'};
      }
      final errorData = json.decode(utf8.decode(response.bodyBytes));
      return {
        'success': false,
        'message': errorData['detail'] ?? 'Произошла ошибка.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети.'};
    }
  }

  Future<bool> addParentClubEntry(
      {required String section,
      required String content,
      required bool isAnonymous}) async {
    final headers = await _getHeaders(includeAuth: true);
    if (headers['Authorization'] == null) return false;
    final url = Uri.parse('${_baseUrl}parent-club/');
    final body = json
        .encode({'section': section, 'content': content, 'is_anonymous': isAnonymous});
    try {
      final response = await http.post(url, headers: headers, body: body);
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addAlumni(
      {String? fullName,
      required bool displayName,
      required String graduationYear,
      required String institution,
      required String position,
      String? photoUrl}) async {
    final headers = await _getHeaders(includeAuth: true);
    if (headers['Authorization'] == null) return false;
    final url = Uri.parse('${_baseUrl}alumni/');
    final body = json.encode({
      'full_name': fullName,
      'display_name': displayName,
      'graduation_year': int.tryParse(graduationYear),
      'institution': institution,
      'position': position,
      'photo_url': photoUrl,
    });
    try {
      final response = await http.post(url, headers: headers, body: body);
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> addSuggestion(
      {required String content, required String screenSource}) async {
    final headers = await _getHeaders(includeAuth: true);
    if (headers['Authorization'] == null) {
      return {'success': false, 'message': 'Пожалуйста, авторизуйтесь.'};
    }

    final url = Uri.parse('${_baseUrl}suggestions/');
    final body =
        json.encode({'content': content, 'screen_source': screenSource});
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Ваше предложение успешно отправлено!'};
      }
      return {'success': false, 'message': 'Произошла ошибка при отправке.'};
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети.'};
    }
  }

  Future<Map<String, dynamic>> proposeEventIdea(
      {required String title, required String description}) async {
    final headers = await _getHeaders(includeAuth: true);
    if (headers['Authorization'] == null) {
      return {'success': false, 'message': 'Пожалуйста, авторизуйтесь.'};
    }

    final url = Uri.parse('${_baseUrl}events/');
    final body = json.encode({
      'title': title,
      'description': description,
      'category': 1,
      'status': 'upcoming'
    });
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Ваша идея успешно предложена!'};
      }
      return {
        'success': false,
        'message': 'Произошла ошибка. ${response.body}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети.'};
    }
  }
}
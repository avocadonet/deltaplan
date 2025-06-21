import 'package:flutter/material.dart';
import 'api_service.dart';
import 'detail_screen.dart';

class ParentsSchoolScreen extends StatefulWidget {
  const ParentsSchoolScreen({super.key});

  @override
  State<ParentsSchoolScreen> createState() => _ParentsSchoolScreenState();
}

class _ParentsSchoolScreenState extends State<ParentsSchoolScreen> {
  final _topicController = TextEditingController();
  final _specialistController = TextEditingController();
  final _experienceController = TextEditingController();

  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _apiService.fetchParentSchoolEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Школа для родителей'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Ближайшие мероприятия',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Ошибка загрузки: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Мероприятий пока не запланировано.'),
                  );
                }
                final events = snapshot.data!;
                return Column(
                  children: events.map((event) {
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                title: event['title'] ?? 'Без названия',
                                content: event['description'] ??
                                    'Описание отсутствует.',
                                additionalInfo: {
                                  'Дата': event['event_date'] ?? 'Не указана',
                                  'Организатор':
                                      event['organizer_name'] ?? 'Не указан',
                                },
                                eventId: event['id'],
                                type: DetailType.parentSchool,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading:
                                    const Icon(Icons.event, color: Colors.teal),
                                title: Text(
                                  event['title'] ?? 'Без названия',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Дата: ${event['event_date'] ?? 'не указана'}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  event['description'] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Предложить тему или специалиста',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        labelText: 'Тема',
                        border: OutlineInputBorder(),
                        hintText: 'Например, "Эмоциональный интеллект"',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _specialistController,
                      decoration: const InputDecoration(
                        labelText: 'Специалист',
                        border: OutlineInputBorder(),
                        hintText: 'Имя или профессия (например, психолог Иванова)',
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_topicController.text.isNotEmpty ||
                            _specialistController.text.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ваше предложение отправлено!'),
                            ),
                          );
                          _topicController.clear();
                          _specialistController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Заполните хотя бы одно поле'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Отправить предложение'),
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              'Поделиться своим опытом',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _experienceController,
                      decoration: const InputDecoration(
                        labelText: 'Ваш опыт',
                        border: OutlineInputBorder(),
                        hintText: 'Опишите, о чем хотите рассказать',
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_experienceController.text.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ваше предложение отправлено!'),
                            ),
                          );
                          _experienceController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Пожалуйста, опишите ваш опыт'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Отправить заявку'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _specialistController.dispose();
    _experienceController.dispose();
    super.dispose();
  }
}
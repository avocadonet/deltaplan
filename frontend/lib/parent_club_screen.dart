import 'package:flutter/material.dart';
import 'api_service.dart';

class ParentsClubScreen extends StatefulWidget {
  const ParentsClubScreen({super.key});

  @override
  State<ParentsClubScreen> createState() => _ParentsClubScreenState();
}

class _ParentsClubScreenState extends State<ParentsClubScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _clubEntriesFuture;
  bool _isLoading = false;
  bool _isAnonymous = false;

  final Map<String, dynamic> _sections = {
    'professions_day': {
      'title': 'День родительских профессий',
      'description': 'Расскажите о своей профессии и вдохновите детей!',
      'entries': <dynamic>[],
      'controller': TextEditingController(),
    },
    'heroes': {
      'title': 'Мои герои (Родители на СВО)',
      'description':
          'Поделитесь историей о мужестве и подвигах ваших близких.',
      'entries': <dynamic>[],
      'controller': TextEditingController(),
    },
    'patrol': {
      'title': 'Родительский патруль',
      'description':
          'Предложите идеи по обеспечению безопасности и поддержке школьной среды.',
      'entries': <dynamic>[],
      'controller': TextEditingController(),
    }
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _clubEntriesFuture = _apiService.fetchParentClubEntries();
    });
  }

  Future<void> _addEntry(
      String sectionKey, TextEditingController controller) async {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите текст.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _apiService.addParentClubEntry(
      section: sectionKey,
      content: controller.text.trim(),
      isAnonymous: _isAnonymous,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Ваша запись успешно добавлена!'
              : 'Ошибка добавления записи. Попробуйте снова.'),
        ),
      );
      if (success) {
        controller.clear();
        _fetchData();
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildSectionCard(
      String sectionKey, Map<String, dynamic> sectionData) {
    return Card(
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
            Text(
              sectionData['title'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sectionData['description'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Последние записи:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (sectionData['entries'].isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Пока нет записей.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            else
              ...sectionData['entries'].map<Widget>((entry) {
                return ListTile(
                  leading:
                      const Icon(Icons.article_outlined, color: Colors.teal),
                  title: Text(entry['content'] ?? 'Нет содержимого'),
                  subtitle: Text('Автор: ${entry['author_name'] ?? 'Аноним'}'),
                );
              }).toList(),
            const SizedBox(height: 16),
            TextField(
              controller: sectionData['controller'],
              decoration: const InputDecoration(
                labelText: 'Добавить новую запись',
                border: OutlineInputBorder(),
                hintText: 'Ваш текст...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text("Опубликовать анонимно"),
              value: _isAnonymous,
              onChanged: (newValue) {
                setState(() {
                  _isAnonymous = newValue!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _addEntry(sectionKey, sectionData['controller']),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : const Text('Отправить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Родительский клуб'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _clubEntriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            for (var section in _sections.values) {
              section['entries'].clear();
            }
            for (var entry in snapshot.data!) {
              final sectionKey = entry['section'];
              if (_sections.containsKey(sectionKey)) {
                _sections[sectionKey]!['entries'].add(entry);
              }
            }
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchData(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: _sections.entries.map((entry) {
                return _buildSectionCard(entry.key, entry.value);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    for (var section in _sections.values) {
      section['controller'].dispose();
    }
    super.dispose();
  }
}
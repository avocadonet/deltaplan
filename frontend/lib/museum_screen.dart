import 'package:flutter/material.dart';
import 'api_service.dart';

class MuseumScreen extends StatefulWidget {
  const MuseumScreen({super.key});

  @override
  State<MuseumScreen> createState() => _MuseumScreenState();
}

class _MuseumScreenState extends State<MuseumScreen> {
  final _suggestionController = TextEditingController();
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _tasksFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _apiService.fetchMuseumTasks();
  }

  void _submitSuggestion() async {
    if (_suggestionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите предложение')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final result = await _apiService.addSuggestion(
      content: _suggestionController.text.trim(),
      screenSource: 'museum',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      if (result['success']) {
        _suggestionController.clear();
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Наш музей'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Задачи музея',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: _tasksFuture,
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
                    child: Text('Задачи музея пока не определены.'),
                  );
                }
                final tasks = snapshot.data!;
                return Column(
                  children: tasks.map((task) {
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        leading: const Icon(Icons.museum, color: Colors.teal),
                        title: Text(
                          task['task'] ?? 'Без названия',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Ваши предложения',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
                      controller: _suggestionController,
                      decoration: const InputDecoration(
                        labelText: 'Ваше предложение',
                        border: OutlineInputBorder(),
                        hintText: 'Идеи для развития музея',
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_suggestionController.text.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ваше предложение отправлено!'),
                            ),
                          );
                          _suggestionController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Пожалуйста, введите предложение'),
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
                      child: const Text('Отправить'),
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
    _suggestionController.dispose();
    super.dispose();
  }
}
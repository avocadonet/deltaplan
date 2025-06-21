import 'package:flutter/material.dart';
import 'api_service.dart';
import 'detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, List<dynamic>>> _dataFuture;

  final Map<String, IconData> _iconMap = {
    'Спорт': Icons.sports_basketball,
    'Интеллект': Icons.book,
    'Волонтерство': Icons.favorite,
    'Творчество': Icons.brush,
    'Театр': Icons.theater_comedy,
    'default': Icons.event,
  };

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProposing = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, List<dynamic>>> _fetchData() async {
    try {
      final results = await Future.wait([
        _apiService.fetchGenericData('categories/'),
        _apiService.fetchEvents(),
      ]);
      return {
        'categories': results[0],
        'events': results[1],
      };
    } catch (e) {
      throw Exception('Failed to load initial data: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  void _showProposeIdeaDialog() {
    _titleController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Предложить идею мероприятия'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration:
                          const InputDecoration(labelText: 'Название идеи'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Краткое описание'),
                      maxLines: 3,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Введите описание' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: _isProposing
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setDialogState(() => _isProposing = true);

                          final result = await _apiService.proposeEventIdea(
                            title: _titleController.text,
                            description: _descriptionController.text,
                          );

                          setDialogState(() => _isProposing = false);

                          if (mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message'])),
                            );
                            if (result['success']) {
                              _refreshData();
                            }
                          }
                        }
                      },
                child: _isProposing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Предложить'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мероприятия'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<Map<String, List<dynamic>>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Ошибка загрузки: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData || snapshot.data!['categories']!.isEmpty) {
              return const Center(
                child: Text('Категории мероприятий не найдены.'),
              );
            }

            final categories = snapshot.data!['categories']!;
            final events = snapshot.data!['events']!
                .where((e) => e['is_idea'] == false)
                .toList();

            return DefaultTabController(
              length: categories.length,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabs: categories
                        .map((category) => Tab(text: category['name']))
                        .toList(),
                    labelColor: Colors.teal,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.teal,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: categories.map<Widget>((category) {
                        final categoryEvents = events
                            .where((event) =>
                                event['category_name'] == category['name'])
                            .toList();

                        if (categoryEvents.isEmpty) {
                          return Center(
                            child: Text(
                                'Мероприятий в категории "${category['name']}" пока нет.'),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: categoryEvents.length,
                          itemBuilder: (context, index) {
                            final event = categoryEvents[index];
                            final categoryName =
                                event['category_name'] ?? 'default';
                            final icon =
                                _iconMap[categoryName] ?? _iconMap['default']!;

                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                          'Категория':
                                              event['category_name'] ?? 'Не указана',
                                          'Место':
                                              event['location'] ?? 'Не указано',
                                          'Дата начала':
                                              event['start_date'] ?? 'Не указана',
                                        },
                                        eventId: event['id'],
                                        type: DetailType.event,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(icon, size: 48, color: Colors.teal),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        event['title'] ?? 'Без названия',
                                        style: const TextStyle(fontSize: 16),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'propose_idea',
        onPressed: _showProposeIdeaDialog,
        backgroundColor: Colors.yellow.shade700,
        icon: const Icon(Icons.lightbulb, color: Colors.black),
        label: const Text(
          'Предложи идею',
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
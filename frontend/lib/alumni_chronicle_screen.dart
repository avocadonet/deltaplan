import 'package:flutter/material.dart';
import 'api_service.dart';
import 'detail_screen.dart';

class AlumniChronicleScreen extends StatefulWidget {
  const AlumniChronicleScreen({super.key});

  @override
  State<AlumniChronicleScreen> createState() => _AlumniChronicleScreenState();
}

class _AlumniChronicleScreenState extends State<AlumniChronicleScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _alumniFuture;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _institutionController = TextEditingController();
  final _positionController = TextEditingController();
  final _photoUrlController = TextEditingController();

  bool _displayNameInDialog = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _alumniFuture = _apiService.fetchAlumni();
    });
  }

  Future<void> _submitAlumniForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final success = await _apiService.addAlumni(
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        displayName: _displayNameInDialog,
        graduationYear: _graduationYearController.text,
        institution: _institutionController.text,
        position: _positionController.text,
        photoUrl: _photoUrlController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Выпускник успешно добавлен!' : 'Ошибка добавления.',
            ),
          ),
        );
        if (success) {
          Navigator.of(context).pop();
          _fetchData();
        }
      }

      setState(() => _isLoading = false);
    }
  }

  void _showAddAlumniDialog() {
    _fullNameController.clear();
    _graduationYearController.clear();
    _institutionController.clear();
    _positionController.clear();
    _photoUrlController.clear();
    _displayNameInDialog = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Добавить выпускника'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      decoration:
                          const InputDecoration(labelText: 'ФИО (необязательно)'),
                    ),
                    CheckboxListTile(
                      title: const Text("Отображать ФИО"),
                      value: _displayNameInDialog,
                      onChanged: (newValue) {
                        setDialogState(() {
                          _displayNameInDialog = newValue!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextFormField(
                      controller: _graduationYearController,
                      decoration: const InputDecoration(labelText: 'Год выпуска'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Введите год' : null,
                    ),
                    TextFormField(
                      controller: _institutionController,
                      decoration:
                          const InputDecoration(labelText: 'ВУЗ/Место работы'),
                      validator: (value) =>
                          value!.isEmpty ? 'Заполните поле' : null,
                    ),
                    TextFormField(
                      controller: _positionController,
                      decoration: const InputDecoration(
                          labelText: 'Должность/Достижение'),
                      validator: (value) =>
                          value!.isEmpty ? 'Заполните поле' : null,
                    ),
                    TextFormField(
                      controller: _photoUrlController,
                      decoration: const InputDecoration(
                          labelText: 'URL фотографии (необязательно)'),
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
                onPressed: _isLoading ? null : _submitAlumniForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Добавить'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Летопись выпускников'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchData(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Истории наших выпускников',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _alumniFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Ошибка загрузки: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('Историй выпускников пока нет.'));
                    }
                    final alumni = snapshot.data!;
                    return ListView.builder(
                      itemCount: alumni.length,
                      itemBuilder: (context, index) {
                        final person = alumni[index];
                        final displayName =
                            person['alumni_display_name'] ?? 'Не указано';

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailScreen(
                                    title: displayName,
                                    content:
                                        'Должность/достижение: ${person['position'] ?? 'Не указано'}\n'
                                        'Учебное заведение: ${person['institution'] ?? 'Не указано'}',
                                    additionalInfo: {
                                      'Год выпуска':
                                          person['graduation_year']?.toString() ??
                                              'Не указан',
                                    },
                                  ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              backgroundImage: person['photo_url'] != null &&
                                      person['photo_url'].isNotEmpty
                                  ? NetworkImage(person['photo_url'])
                                  : null,
                              child: person['photo_url'] == null ||
                                      person['photo_url'].isEmpty
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            title: Text(displayName),
                            subtitle:
                                Text('Выпуск ${person['graduation_year'] ?? ''}'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _showAddAlumniDialog,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Добавить историю'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _graduationYearController.dispose();
    _institutionController.dispose();
    _positionController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }
}
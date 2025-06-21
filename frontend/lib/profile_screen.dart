import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'api_service.dart';

class CollapsibleSection extends StatefulWidget {
  final String title;
  final List items;
  final bool initiallyExpanded;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.items,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          if (widget.items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'Нет заявок в этой категории',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final app = widget.items[index];
                final isParentSchool =
                    app['event_type'] == 'Школа для родителей';
                final icon =
                    isParentSchool ? Icons.school : Icons.event_note;
                final statusColor =
                    app['status'] == 'Одобрена' || app['status'] == 'Зарегистрирован'
                        ? Colors.green.shade700
                        : (app['status'] == 'Отклонена'
                            ? Colors.red.shade700
                            : Colors.orange.shade700);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(icon, color: Colors.teal, size: 30),
                    title: Text(app['event_title'] ?? 'Название не указано'),
                    subtitle: Text(app['event_type']),
                    trailing: Text(
                      app['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<dynamic> _myApplicationsFuture;

  @override
  void initState() {
    super.initState();
    _fetchMyApplications();
  }

  void _fetchMyApplications() {
    setState(() {
      _myApplicationsFuture = _apiService.fetchMyApplications();
    });
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Не указано',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchMyApplications();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (userData == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow('Логин', userData['username']),
              _buildInfoRow('Имя', userData['first_name']),
              _buildInfoRow('Фамилия', userData['last_name']),
              _buildInfoRow('Email', userData['email']),
              _buildInfoRow('Роль', userData['role']),
            ],
            const Divider(height: 40, thickness: 1),
            FutureBuilder<dynamic>(
              future: _myApplicationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Ошибка загрузки заявок: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: Text('Нет данных о регистрациях.'),
                  );
                }

                final Map<String, dynamic> applications = snapshot.data;
                final List upcomingApproved =
                    applications['upcoming_approved'] ?? [];
                final List upcomingPending =
                    applications['upcoming_pending'] ?? [];
                final List archived = applications['archived'] ?? [];

                return Column(
                  children: [
                    CollapsibleSection(
                      title: 'Будущие (Участие подтверждено)',
                      items: upcomingApproved,
                      initiallyExpanded: true,
                    ),
                    const Divider(),
                    CollapsibleSection(
                      title: 'Будущие (В ожидании)',
                      items: upcomingPending,
                      initiallyExpanded: true,
                    ),
                    const Divider(),
                    CollapsibleSection(
                      title: 'Архив',
                      items: archived,
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 40, thickness: 1),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Выйти',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                if (Navigator.canPop(context)) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
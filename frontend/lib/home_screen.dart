import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'profile_screen.dart';
import 'events_screen.dart';
import 'calendar_screen.dart';
import 'stay_informed_screen.dart';
import 'museum_screen.dart';
import 'theater_screen.dart';
import 'train_safety_screen.dart';
import 'parent_club_screen.dart';
import 'school_for_parents_screen.dart';
import 'alumni_chronicle_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData ?? {};
    final String fullName =
        "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}".trim();

    final List<Map<String, dynamic>> buttonData = [
      {
        'title': 'Профиль',
        'screen': const ProfileScreen(),
        'icon': Icons.person
      },
      {
        'title': 'Календарный план',
        'screen': const CalendarScreen(),
        'icon': Icons.calendar_today
      },
      {
        'title': 'Мероприятия',
        'screen': const EventsScreen(),
        'icon': Icons.emoji_events
      },
      {
        'title': 'В курсе!\nПроконтролируй!',
        'screen': const StayInformedScreen(),
        'icon': Icons.notifications
      },
      {
        'title': 'Наш музей',
        'screen': const MuseumScreen(),
        'icon': Icons.museum
      },
      {
        'title': 'Школьный театр и\nлитературная гостиная',
        'screen': const TheaterScreen(),
        'icon': Icons.theater_comedy
      },
      {
        'title': 'Поезд безопасности',
        'screen': const TrainSafetyScreen(),
        'icon': Icons.train
      },
      {
        'title': 'Школа для родителей',
        'screen': const ParentsSchoolScreen(),
        'icon': Icons.school
      },
      {
        'title': 'Родительский клуб',
        'screen': const ParentsClubScreen(),
        'icon': Icons.family_restroom
      },
      {
        'title': 'Летопись выпускников',
        'screen': const AlumniChronicleScreen(),
        'icon': Icons.history_edu
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дельтаплан'),
        actions: [
          if (fullName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  'Привет, $fullName!',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1.2,
          ),
          itemCount: buttonData.length,
          itemBuilder: (context, index) {
            final item = buttonData[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () {
                  if (item['screen'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => item['screen'],
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], size: 40, color: Colors.teal),
                    const SizedBox(height: 10),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
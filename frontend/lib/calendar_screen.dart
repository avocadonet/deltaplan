import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'api_service.dart';
import 'detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<dynamic>> _events = {};
  late Future<void> _eventsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _eventsFuture = _fetchCalendarEvents();
  }

  Future<void> _fetchCalendarEvents() async {
    try {
      final eventList = await _apiService.fetchCalendarEvents();
      setState(() {
        _events.clear();
        for (var event in eventList) {
          if (event['start_date'] != null && event['start_date'].isNotEmpty) {
            try {
              final date = DateTime.parse(event['start_date']).toUtc();
              final day = DateTime.utc(date.year, date.month, date.day);
              if (_events[day] == null) _events[day] = [];
              _events[day]!.add(event);
            } catch (e) {
              print(
                  "Could not parse date for event '${event['title']}': ${event['start_date']}");
            }
          }
        }
      });
    } catch (e) {
      throw Exception('Failed to load events from API: $e');
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарный план'),
      ),
      body: FutureBuilder(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.purple.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _selectedDay != null &&
                          _getEventsForDay(_selectedDay!).isNotEmpty
                      ? ListView.builder(
                          itemCount: _getEventsForDay(_selectedDay!).length,
                          itemBuilder: (context, index) {
                            final eventData =
                                _getEventsForDay(_selectedDay!)[index];
                            final bool isParentSchoolEvent =
                                eventData['event_type'] == 'parent_school';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: Icon(
                                  isParentSchoolEvent
                                      ? Icons.school
                                      : Icons.event,
                                  color: Colors.teal,
                                ),
                                title: Text(eventData['title'] ??
                                    'Событие без названия'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailScreen(
                                        title: eventData['title'] ?? 'Без названия',
                                        content: eventData['description'] ??
                                            'Описание отсутствует.',
                                        eventId: eventData['id'],
                                        type: isParentSchoolEvent
                                            ? DetailType.parentSchool
                                            : DetailType.event,
                                        additionalInfo: {
                                          if (!isParentSchoolEvent)
                                            'Категория':
                                                eventData['category_name'] ??
                                                    'Не указана',
                                          'Организатор':
                                              eventData['organizer_name'] ??
                                                  'Не указан',
                                          if (!isParentSchoolEvent)
                                            'Место': eventData['location'] ??
                                                'Не указано',
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'Событий на выбранную дату нет',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'api_service.dart';

enum DetailType { event, parentSchool, other }

class DetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final Map<String, String>? additionalInfo;
  final int? eventId;
  final DetailType type;

  const DetailScreen({
    super.key,
    required this.title,
    required this.content,
    this.additionalInfo,
    this.eventId,
    this.type = DetailType.other,
  });

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (additionalInfo != null) ...[
              ...additionalInfo!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context)
                          .style
                          .copyWith(fontSize: 16),
                      children: [
                        TextSpan(
                          text: '${entry.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: entry.value),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const Divider(height: 24),
            ],
            Text(
              content,
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
          ],
        ),
      ),
      floatingActionButton: eventId != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                Map<String, dynamic> result;
                if (type == DetailType.event) {
                  result = await apiService.applyForEvent(eventId!);
                } else if (type == DetailType.parentSchool) {
                  result = await apiService.registerForParentSchool(eventId!);
                } else {
                  return;
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']!),
                    ),
                  );
                }
              },
              label: const Text('Записаться'),
              icon: const Icon(Icons.check_circle_outline),
            )
          : null,
    );
  }
}
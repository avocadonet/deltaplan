import 'package:flutter/material.dart';

class StayInformedScreen extends StatelessWidget {
  const StayInformedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('В курсе! Проконтролируй!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Учебный прогресс',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Здесь вы можете отслеживать успеваемость и получать уведомления о важных событиях.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
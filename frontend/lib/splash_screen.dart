import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Лицей Дельта',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Образовательно -\nдосуговая платформа\nДЕЛЬТАПЛАН',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }
}
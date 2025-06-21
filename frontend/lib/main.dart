import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'splash_screen.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'auth_provider.dart';

void main() {
  runApp(const DeltaApp());
}

class DeltaApp extends StatelessWidget {
  const DeltaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuthProvider(),
      child: MaterialApp(
        title: 'Delta App',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.grey[200],
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 20,
              ),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthProvider>(
          builder: (ctx, auth, _) {
            switch (auth.status) {
              case AuthStatus.uninitialized:
              case AuthStatus.authenticating:
                return const SplashScreen();
              case AuthStatus.authenticated:
                return const HomeScreen();
              case AuthStatus.unauthenticated:
              default:
                return const AuthScreen();
            }
          },
        ),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/auth': (context) => const AuthScreen(),
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:abonmu_app/screens/splash_screen.dart';

void main() {
  runApp(const AbonmuApp());
}

class AbonmuApp extends StatelessWidget {
  const AbonmuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abonmu',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(), // Mulai dari Splash Screen
      debugShowCheckedModeBanner: false,
    );
  }
}

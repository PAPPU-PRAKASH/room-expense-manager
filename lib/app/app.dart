import 'package:flutter/material.dart';
import 'theme.dart';
import '../features/splash/splash_screen.dart';

class RoomExpenseApp extends StatelessWidget {
  const RoomExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Room Expense Manager",
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
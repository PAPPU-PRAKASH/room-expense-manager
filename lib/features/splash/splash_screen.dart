import 'package:firebase_auth/firebase_auth.dart';

import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/firestore_service.dart';


import '../auth/login_screen.dart';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
void initState() {
  super.initState();
  checkLogin();
}

Future<void> checkLogin() async {
  await Future.delayed(const Duration(seconds: 2));

  final user = FirebaseAuth.instance.currentUser;

  if (!mounted) return;

  if (user == null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(),
      ),
    );
    return;
  }

  final isCompleted =
      await FirestoreService().isProfileCompleted(user.uid);

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) =>
          isCompleted ? const HomeScreen() : const ProfileScreen(),
    ),
  );
} 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 90,
            ),

            SizedBox(height: 20),

            Text(
              "Room Expense Manager",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Manage Smartly",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
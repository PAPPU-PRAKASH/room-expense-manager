import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';
import '../navigation/main_navigation_screen.dart';
import '../profile/profile_screen.dart';
import '../room/room_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // User not logged in
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(),
        ),
      );
      return;
    }

    final firestore = FirestoreService();

    final isProfileCompleted =
        await firestore.isProfileCompleted(user.uid);

    if (!mounted) return;

    // Profile not completed
    if (!isProfileCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
      return;
    }

    final hasRoom = await firestore.hasRoom(user.uid);

    if (!mounted) return;

    // User has no room
    if (!hasRoom) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RoomSetupScreen(),
        ),
      );
      return;
    }

    // Everything completed
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(),
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
          children: const [
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
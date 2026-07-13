import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Room Expense Manager"),
  centerTitle: true,
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();

        if (!context.mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(),
          ),
          (route) => false,
        );
      },
    ),
  ],
),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Welcome 👋",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet,
                    color: Colors.green),
                title: const Text("Total Balance"),
                subtitle: const Text("₹ 0"),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.money_off,
                    color: Colors.red),
                title: const Text("Total Expense"),
                subtitle: const Text("₹ 0"),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.people,
                    color: Colors.blue),
                title: const Text("Room Members"),
                subtitle: const Text("0 Members"),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text("Add Expense"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
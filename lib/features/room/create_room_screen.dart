import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/room_model.dart';
import '../../services/firestore_service.dart';
import '../../services/room_service.dart';
import '../navigation/main_navigation_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController roomNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isLoading = false;

  int maxMembers = 4;

  String generateRoomCode() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final random = Random();

    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> createRoom() async {
    if (roomNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter room name"),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final roomId =
          DateTime.now().millisecondsSinceEpoch.toString();

      final userModel = await FirestoreService().getUserModel(user.uid);
      if (userModel == null) {
        throw Exception('Unable to load user data');
      }

      final room = RoomModel(
        roomId: roomId,
        roomName: roomNameController.text.trim(),
        description: descriptionController.text.trim(),
        roomCode: generateRoomCode(),
        createdBy: user.uid,
        maxMembers: maxMembers,
      );

      await RoomService().createRoom(
        room,
        userModel.name,
        userModel.phone,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Room Created Successfully"),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    roomNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Room"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: roomNameController,
              decoration: const InputDecoration(
                labelText: "Room Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<int>(
              initialValue: maxMembers,
              decoration: const InputDecoration(
                labelText: "Maximum Members",
                border: OutlineInputBorder(),
              ),
              items: [2, 3, 4, 5, 6, 7, 8]
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text("$e Members"),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    maxMembers = value;
                  });
                }
              },
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : createRoom,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text("Create Room"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
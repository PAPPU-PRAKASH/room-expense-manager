import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/room_service.dart';
import '../navigation/main_navigation_screen.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';

class RoomSetupScreen extends StatefulWidget {
  const RoomSetupScreen({super.key});

  @override
  State<RoomSetupScreen> createState() => _RoomSetupScreenState();
}

class _RoomSetupScreenState extends State<RoomSetupScreen> {
  late Future<_RoomSetupData> _setupDataFuture;

  @override
  void initState() {
    super.initState();
    _setupDataFuture = _loadSetupData();
  }

  Future<_RoomSetupData> _loadSetupData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final userModel = await FirestoreService().getUserModel(user.uid);
    if (userModel == null) {
      throw Exception('Unable to load user profile');
    }

    RoomModel? roomModel;
    if (userModel.hasRoom) {
      final roomSnapshot = await RoomService().getRoom(userModel.roomId);
      if (roomSnapshot.exists) {
        final roomData = roomSnapshot.data();
        if (roomData != null) {
          roomModel = RoomModel.fromMap(roomData);
        }
      }
    }

    return _RoomSetupData(
      userModel: userModel,
      roomModel: roomModel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Setup'),
        centerTitle: true,
      ),
      body: FutureBuilder<_RoomSetupData>(
        future: _setupDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _setupDataFuture = _loadSetupData();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            );
          }

          final setupData = snapshot.data!;
          final userModel = setupData.userModel;
          final roomModel = setupData.roomModel;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.groups_rounded,
                  size: 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome ${userModel.name.isNotEmpty ? userModel.name : 'Guest'}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (roomModel != null) ...[
                  const Text(
                    'You are already part of a room.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Room Name',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roomModel.roomName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Room Code',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roomModel.roomCode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigationScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Continue'),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'You are not in any room.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_home_work),
                      label: const Text('Create Room'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateRoomScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.group_add),
                      label: const Text('Join Room'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JoinRoomScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoomSetupData {
  final UserModel userModel;
  final RoomModel? roomModel;

  _RoomSetupData({
    required this.userModel,
    this.roomModel,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/balance_model.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../services/balance_service.dart';
import '../../services/firestore_service.dart';
import '../../services/room_service.dart';
import '../auth/login_screen.dart';
import '../home/add_expense_screen.dart';
import '../room/create_room_screen.dart';
import '../room/join_room_screen.dart';
import '../room/members_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeData {
  final UserModel userModel;
  final RoomModel? roomModel;
  final bool roomLoadFailed;

  _HomeData({
    required this.userModel,
    this.roomModel,
    this.roomLoadFailed = false,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _homeFuture;
  final BalanceService _balanceService = BalanceService();

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHomeData();
  }

  Future<_HomeData> _loadHomeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final userModel = await FirestoreService().getUserModel(user.uid);
    if (userModel == null) {
      throw Exception('Unable to load user profile');
    }

    if (!userModel.hasRoom) {
      return _HomeData(userModel: userModel);
    }

    try {
      final roomSnapshot = await RoomService().getRoom(userModel.roomId);
      if (!roomSnapshot.exists) {
        return _HomeData(userModel: userModel, roomLoadFailed: true);
      }

      final roomData = roomSnapshot.data();
      if (roomData == null) {
        return _HomeData(userModel: userModel, roomLoadFailed: true);
      }

      return _HomeData(
        userModel: userModel,
        roomModel: RoomModel.fromMap(roomData),
      );
    } catch (_) {
      return _HomeData(userModel: userModel, roomLoadFailed: true);
    }
  }

  void _navigateToMembers(String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembersScreen(roomId: roomId),
      ),
    );
  }

  void _retry() {
    setState(() {
      _homeFuture = _loadHomeData();
    });
  }

  Future<void> _copyRoomCode(String roomCode) async {
    await Clipboard.setData(ClipboardData(text: roomCode));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room Code copied.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Expense Manager'),
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
      body: FutureBuilder<_HomeData>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Unable to load home information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            );
          }

          final homeData = snapshot.data!;
          final userModel = homeData.userModel;
          final roomModel = homeData.roomModel;
          final hasRoom = userModel.hasRoom;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome ${userModel.name.isNotEmpty ? userModel.name : 'Guest'}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (hasRoom) ...[
                  if (homeData.roomLoadFailed) ...[
                    Card(
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unable to load room information.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: _retry,
                                child: const Text('Retry'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (roomModel != null) ...[
                    Card(
                      elevation: 5,
                      child: ListTile(
                        leading: const Icon(
                          Icons.home,
                          color: Colors.blue,
                        ),
                        title: const Text('🏠 Room Name'),
                        subtitle: Text(roomModel.roomName),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 5,
                      child: ListTile(
                        leading: const Icon(
                          Icons.vpn_key,
                          color: Colors.orange,
                        ),
                        title: const Text('🔑 Room Code'),
                        subtitle: Text(roomModel.roomCode),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyRoomCode(roomModel.roomCode),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ] else ...[
                  Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You are not in any room.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreateRoomScreen(),
                                  ),
                                );
                              },
                              child: const Text('Create Room'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const JoinRoomScreen(),
                                  ),
                                );
                              },
                              child: const Text('Join Room'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                StreamBuilder<BalanceSummary>(
                  stream: _balanceService.streamBalanceSummary(userModel.roomId),
                  builder: (context, snapshot) {
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;
                    final hasError = snapshot.hasError || !snapshot.hasData;
                    final balanceSummary = snapshot.data;
                    final totalExpense = balanceSummary?.totalExpense ?? 0.0;
                    final currentBalance = balanceSummary?.currentUserBalance ?? 0.0;
                    final balanceText = currentBalance == 0
                        ? 'Settled Up'
                        : currentBalance > 0
                            ? 'You should receive ₹${currentBalance.toStringAsFixed(2)}'
                            : 'You should pay ₹${currentBalance.abs().toStringAsFixed(2)}';

                    return Column(
                      children: [
                        Card(
                          elevation: 5,
                          child: ListTile(
                            leading: const Icon(Icons.account_balance_wallet,
                                color: Colors.green),
                            title: const Text('Total Balance'),
                            subtitle: isLoading
                                ? const Text('Loading...')
                                : hasError
                                    ? const Text('Unable to load balance')
                                    : Text(balanceText),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 5,
                          child: ListTile(
                            leading: const Icon(Icons.money_off,
                                color: Colors.red),
                            title: const Text('Total Expense'),
                            subtitle: isLoading
                                ? const Text('Loading...')
                                : hasError
                                    ? const Text('Unable to load total expense')
                                    : Text('₹ ${totalExpense.toStringAsFixed(2)}'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 5,
                  child: ListTile(
                    leading: const Icon(Icons.people,
                        color: Colors.blue),
                    title: const Text('Room Members'),
                    subtitle: Text(hasRoom
                        ? 'View all members'
                        : 'No room assigned'),
                    trailing: hasRoom
                        ? TextButton(
                            onPressed: () => _navigateToMembers(userModel.roomId),
                            child: const Text('View'),
                          )
                        : null,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: hasRoom
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddExpenseScreen(
                                  roomId: userModel.roomId,
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

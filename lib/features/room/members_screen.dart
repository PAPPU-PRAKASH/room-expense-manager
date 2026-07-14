import 'package:flutter/material.dart';

import '../../models/member_model.dart';
import '../../services/member_service.dart';
import 'add_member_screen.dart';

class MembersScreen extends StatefulWidget {
  final String roomId;

  const MembersScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late Future<List<MemberModel>> _membersFuture;
  final MemberService _memberService = MemberService();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    _membersFuture = _memberService.getRoomMembers(widget.roomId);
  }

  Future<void> _navigateToAddMember() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMemberScreen(roomId: widget.roomId),
      ),
    );

    if (added == true) {
      setState(_loadMembers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Members'),
      ),
      body: FutureBuilder<List<MemberModel>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final members = snapshot.data ?? [];

          if (members.isEmpty) {
            return const Center(
              child: Text('No members found. Add a member to begin.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];

              return ListTile(
                leading: CircleAvatar(
                  child: Text(member.name.isNotEmpty
                      ? member.name[0].toUpperCase()
                      : '?'),
                ),
                title: Text(member.name),
                subtitle: Text(member.phone ?? 'No phone provided'),
                trailing: Chip(
                  label: Text(
                    member.role == 'admin' ? 'Admin' : 'Member',
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddMember,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
    );
  }
}

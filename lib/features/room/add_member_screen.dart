import 'package:flutter/material.dart';

import '../../models/member_model.dart';
import '../../services/member_service.dart';

class AddMemberScreen extends StatefulWidget {
  final String roomId;

  const AddMemberScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;

  Future<void> addMember() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter member name'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final member = MemberModel(
        memberId: '',
        name: name,
        phone: phone.isNotEmpty ? phone : null,
        role: 'member',
      );

      await MemberService().addMemberToRoom(
        roomId: widget.roomId,
        member: member,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Member'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Member Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : addMember,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Member'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

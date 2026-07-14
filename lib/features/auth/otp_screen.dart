import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../services/member_service.dart';
import '../navigation/main_navigation_screen.dart';
import '../profile/profile_screen.dart';
import '../room/room_setup_screen.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;

  const OtpScreen({
    super.key,
    required this.verificationId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;

  Future<void> verifyOTP() async {
    setState(() {
      isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(),
      );

      await _auth.signInWithCredential(credential);

      final user = _auth.currentUser;

      if (user == null) {
        throw Exception("User not found");
      }

      final firestore = FirestoreService();

      await firestore.saveUser(
        uid: user.uid,
        phone: user.phoneNumber ?? "",
      );

      final userModel = await firestore.getUserModel(user.uid);
      final phone = userModel?.phone.trim() ?? '';
      final roomId = userModel?.roomId;
      final isRoomMember = userModel?.hasRoom ?? false;

      if (isRoomMember && roomId != null && roomId.isNotEmpty && phone.isNotEmpty) {
        final memberDoc = await MemberService().findMemberByPhone(
          roomId: roomId,
          phone: phone,
        );

        if (memberDoc != null) {
          await MemberService().claimMember(
            roomId: roomId,
            memberId: memberDoc.id,
            uid: user.uid,
          );

          await firestore.updateRoomId(
            uid: user.uid,
            roomId: roomId,
          );
        }
      }

      final isProfileCompleted =
          await firestore.isProfileCompleted(user.uid);

      if (!mounted) return;

      if (!isProfileCompleted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
          ),
          (route) => false,
        );
        return;
      }

      final hasRoom = await firestore.hasRoom(user.uid);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              hasRoom
                  ? const MainNavigationScreen()
                  : const RoomSetupScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Invalid OTP"),
        ),
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
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OTP Verification"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              "Enter OTP",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "We have sent a verification code to your mobile number.",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: "Enter 6 digit OTP",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyOTP,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
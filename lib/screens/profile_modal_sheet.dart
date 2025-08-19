import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';

class ProfileModalSheet extends StatelessWidget {
  final User user;

  const ProfileModalSheet({super.key, required this.user});

  Future<void> _signOut(BuildContext context) async {
    final auth = FirebaseAuth.instance;

    await auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // ✅ clear login session

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Pic
          CircleAvatar(
            radius: 40,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? const Icon(Icons.person, size: 40, color: Colors.white70)
                : null,
          ),
          const SizedBox(height: 16),

          // Display Name
          Text(
            user.displayName ?? "No Name",
            style: GoogleFonts.mulish(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          // Email
          if (user.email != null)
            Text(
              user.email!,
              style: GoogleFonts.mulish(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),

          const SizedBox(height: 24),

          // Sign out button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _signOut(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Sign Out",
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

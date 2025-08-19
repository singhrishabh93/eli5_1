import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_nav_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final user = await AuthService.signInWithGoogle();

    if (mounted) {
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BottomNavBar(initialIndex: 0),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed. Please try again.')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _skipSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const BottomNavBar(initialIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Image.asset('assets/bg3.png',
              fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 250,
                    child: Center(
                      child: Lottie.asset(
                        'assets/flower.json',
                        errorBuilder: (context, error, stackTrace) {
                          return const Text('AI animation placeholder');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ask Anything,",
                        style: GoogleFonts.mulish(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      Text(
                        "we’ll explain it simply",
                        style: GoogleFonts.mulish(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _handleGoogleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Image.asset(
                              'assets/google.png',
                              height: 24,
                              width: 24,
                            ),
                            label: Text(
                              "Continue with Google",
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.black.withOpacity(0.54),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                  Text(
                    "By signing in, you agree to our Terms of Service and Privacy Policy",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mulish(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF929292),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: _skipSignIn,
              child: Text(
                "Skip",
                style: GoogleFonts.mulish(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF929292),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

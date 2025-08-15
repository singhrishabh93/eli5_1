import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
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

  void _skipSignIn() {
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
      body: Stack(
        children: [
          Image.asset('assets/bg3.png', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // AI loading animation (model.json)
                  SizedBox(
                    height: 250,
                    child: Center(
                      child: Lottie.asset(
                        'assets/flower.json', // Lottie or Rive would be used for actual animation
                        errorBuilder: (context, error, stackTrace) {
                          return const Text('AI animation placeholder');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
      
                  // Ask Anything
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ask Anything,",
                        style: GoogleFonts.mulish(
                          fontSize: 36,
                          fontWeight: FontWeight.w800, // ExtraBold
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      Text(
                    "we’ll explain it simply",
                    style: GoogleFonts.mulish(
                      fontSize: 32,
                      fontWeight: FontWeight.w800, // ExtraBold
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.left,
                  ),
      
                    ],
                  ),
      
                  // We'll explain it simply
                  
                  const SizedBox(height: 32),
      
                  // Google Sign In button
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
                                fontWeight: FontWeight.w500, // Medium
                                color: Colors.black.withOpacity(0.54),
                              ),
                            ),
                          ),
                        ),
      
                  const SizedBox(height: 24),
      
                  // Terms text
                  Text(
                    "By signing in, you agree to our Terms of Service and Privacy Policy",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mulish(
                      fontSize: 11,
                      fontWeight: FontWeight.w300, // Light
                      color: const Color(0xFF929292),
                    ),
                  ),
                ],
              ),
            ),
          ),
      
          // Skip button top right
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: _skipSignIn,
              child: Text(
                "Skip",
                style: GoogleFonts.mulish(
                  fontSize: 18,
                  fontWeight: FontWeight.w300, // Light
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

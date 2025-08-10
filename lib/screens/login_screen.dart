import 'package:flutter/material.dart';
import '../services/auth_service.dart';  // Adjust path as needed
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final user = await AuthService.signInWithGoogle();

    if (user != null) {
      // Navigate to home on success
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed. Please try again.')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Icon or Logo
                const Icon(
                  Icons.lightbulb_outline,
                  size: 100,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 24),

                const Text(
                  "Welcome to ELI5",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  "Ask anything, and we'll explain it simply!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                _isLoading
                    ? const CircularProgressIndicator()
                    : GoogleSignInButton(onPressed: _handleGoogleSignIn),

                const SizedBox(height: 24),

                const Text(
                  "By signing in, you agree to our Terms of Service and Privacy Policy",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

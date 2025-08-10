import 'package:eli5/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "lottie": "assets/kid.json",
      "title1": "Get answers",
      "title2": "like you’re a kid",
      "desc": "Answers made super simple like story time\nyou can understand."
    },
    {
      "lottie": "assets/teenage.json",
      "title1": "Get answers",
      "title2": "like you’re a teenager",
      "desc": "Clear, relatable, and maybe even a little fun to read."
    },
    {
      "lottie": "assets/adult.json",
      "title1": "Get answers",
      "title2": "like you’re an adult",
      "desc": "Direct, detailed, and no unnecessary fluff."
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // same as login screen
      body: SafeArea(
        child: Stack(
          children: [
            // Swipable Pages
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Lottie animation - same height as LoginScreen
                        SizedBox(
                          height: 250,
                          child: Center(
                            child: Lottie.asset(
                              page["lottie"]!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Titles & description - same alignment as LoginScreen
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              page["title1"]!,
                              style: GoogleFonts.mulish(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              page["title2"]!,
                              style: GoogleFonts.mulish(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              page["desc"]!,
                              style: GoogleFonts.mulish(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: const Color(0xFF929292),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Center arrow button (instead of Google sign-in)
                        FloatingActionButton(
                          onPressed: _nextPage,
                          backgroundColor: Colors.black,
                          child: const Icon(Icons.arrow_forward, color: Colors.white),
                        ),

                        const SizedBox(height: 24),

                        // Page indicator dots (instead of terms text)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_pages.length, (dotIndex) {
                            bool selected = dotIndex == _currentPage;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFF3951)
                                    : const Color(0xFFFF7686),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Skip button in same position as LoginScreen
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
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
      ),
    );
  }
}

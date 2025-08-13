import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedGradientText extends StatelessWidget {
  final String text;

  const AnimatedGradientText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFF6A7D),
      const Color(0xFFFF5266),
      const Color(0xFFFF3951),
      const Color(0xFFE62940),
    ];

    return Animate(
      effects: [
        ShimmerEffect(
          colors: colors,
          duration: const Duration(seconds: 3),
          delay: const Duration(milliseconds: 300),
        )
      ],
      onPlay: (controller) => controller.repeat(), // <-- Infinite Loop
      child: Text(
        text,
        style: GoogleFonts.mulish(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

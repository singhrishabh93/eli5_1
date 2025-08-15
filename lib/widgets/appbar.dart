import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget customAppBar() {
  return SafeArea(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: kToolbarHeight, // Same height as AppBar
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Leading Icon
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(
                FluentIcons.person_circle_12_filled,
                size: 32,
                color: Color(0xffFFFFFF),
              ),
            ),
            onPressed: () {},
          ),

          // Title
          Text(
            "eli5",
            style: GoogleFonts.mulish(
              color: const Color(0xffFFFFFF),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          // Action Icon
          IconButton(
            icon: const Icon(
              FluentIcons.share_ios_20_filled,
              size: 28,
              color: Color(0xffFFFFFF),
            ),
            onPressed: () {},
          ),
        ],
      ),
    ),
  );
}

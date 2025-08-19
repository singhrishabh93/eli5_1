import 'package:eli5/screens/profile_modal_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget customAppBar(BuildContext context, {required VoidCallback onNewChat}) {
  return SafeArea(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: kToolbarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile Icon
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(
                FluentIcons.person_circle_12_filled,
                size: 32,
                color: Color(0xffFFFFFF),
              ),
            ),
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => ProfileModalSheet(user: user),
                );
              }
            },
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
              FluentIcons.add_20_filled,
              size: 28,
              color: Color(0xffFFFFFF),
            ),
            onPressed: onNewChat,
          ),
        ],
      ),
    ),
  );
}

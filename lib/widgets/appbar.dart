import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

AppBar customAppBar() {
  return AppBar(
    elevation: 0,
    backgroundColor: Colors.white,
    titleSpacing: 0, // Removes default Material AppBar spacing
    centerTitle: true,
    title: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // match bottom bar
      child: Text(
        "eli5",
        style: GoogleFonts.mulish(
          color: const Color(0xffFF3951),
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    leading: Padding(
      padding: const EdgeInsets.only(left: 16), // match bottom bar left padding
      child: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Icon(
            FluentIcons.person_circle_12_filled,
            size: 32,
            color: Color(0xffFF3951),
          ),
        ),
        onPressed: () {},
      ),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 16), // match bottom bar right padding
        child: IconButton(
          icon: const Icon(
            FluentIcons.share_ios_20_filled,
            size: 28,
            color: Color(0xffFF3951),
          ),
          onPressed: () {},
        ),
      ),
    ],
  );
}

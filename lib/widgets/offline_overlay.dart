// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class OfflineOverlay extends StatelessWidget {
//   final VoidCallback onRetry;

//   const OfflineOverlay({Key? key, required this.onRetry}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.black.withOpacity(0.9),
//       alignment: Alignment.center,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             "The Internet connection appears to be offline.",
//             textAlign: TextAlign.center,
//             style: GoogleFonts.mulish(
//               color: Colors.white,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 12),
//           GestureDetector(
//             onTap: onRetry,
//             child: Text(
//               "Try again",
//               style: GoogleFonts.mulish(
//                 color: Colors.cyanAccent,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

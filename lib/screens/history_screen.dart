import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eli5/services/gemini_service.dart';
import 'package:eli5/widgets/history_chat_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:connectivity_plus/connectivity_plus.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _searchQuery = "";
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }

  Future<bool> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isOffline = true;
      });
      return false;
    }

    try {
      final result = await InternetAddress.lookup('example.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      setState(() {
        _isOffline = !isConnected;
      });
      return isConnected;
    } catch (_) {
      setState(() {
        _isOffline = true;
      });
      return false;
    }
  }

  void _showOfflineDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FluentIcons.wifi_off_20_filled,
                  color: Colors.white70,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  'The Internet connection appears to be offline.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mulish(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _checkInternetConnection();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Try again',
                      style: GoogleFonts.mulish(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    
    // Show offline state if no internet connection
    if (_isOffline) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            "Library",
            style: GoogleFonts.mulish(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xffFFFFFF),
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            /// Background
            Image.asset(
              "assets/bg2.png",
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            /// Offline message
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FluentIcons.wifi_off_20_filled,
                    color: Colors.white70,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Internet Connection",
                    style: GoogleFonts.mulish(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please check your connection and try again",
                    style: GoogleFonts.mulish(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      await _checkInternetConnection();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Try again',
                        style: GoogleFonts.mulish(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show "No History" if user is not authenticated
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "No History",
            style: GoogleFonts.mulish(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "Library",
          style: GoogleFonts.mulish(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xffFFFFFF),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          /// Background
          Image.asset(
            "assets/bg2.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          /// Content
          Padding(
            padding: EdgeInsets.only(
              top: kToolbarHeight + MediaQuery.of(context).padding.top,
            ),
            child: Column(
              children: [
                /// Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                    style: GoogleFonts.mulish(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search history...",
                      hintStyle: GoogleFonts.mulish(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),

                /// Chat history list
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection("users")
                        .doc(user.uid)
                        .collection("chats")
                        .orderBy("createdAt", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final chats = snapshot.data!.docs;

                      if (chats.isEmpty) {
                        return Center(
                          child: Text(
                            "No history yet",
                            style: GoogleFonts.mulish(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      final filteredChats = chats.where((doc) {
                        final chat = doc.data() as Map<String, dynamic>;
                        final messages = List<Map<String, dynamic>>.from(
                          chat["messages"] ?? [],
                        );

                        final preview =
                            messages.firstWhere(
                              (msg) => msg["role"] == "user",
                              orElse: () => {"message": "New Chat"},
                            )["message"] ??
                            "New Chat";

                        final aiPreview =
                            messages.firstWhere(
                              (msg) => msg["role"] == "assistant",
                              orElse: () => {"message_five": ""},
                            )["message_five"] ??
                            "";

                        return preview.toLowerCase().contains(_searchQuery) ||
                            aiPreview.toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (filteredChats.isEmpty) {
                        return Center(
                          child: Text(
                            "No results found",
                            style: GoogleFonts.mulish(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: filteredChats.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withOpacity(0.2),
                          thickness: 0.5,
                          height: 20,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final chatDoc = filteredChats[index];
                          final chat = chatDoc.data() as Map<String, dynamic>;
                          final messages = List<Map<String, dynamic>>.from(
                            chat["messages"] ?? [],
                          );

                          final preview =
                              messages.firstWhere(
                                (msg) => msg["role"] == "user",
                                orElse: () => {"message": "New Chat"},
                              )["message"] ??
                              "New Chat";

                          final aiPreview =
                              messages.firstWhere(
                                (msg) => msg["role"] == "assistant",
                                orElse: () => {"message_five": ""},
                              )["message_five"] ??
                              "";

                          final createdAt = chat["createdAt"] != null
                              ? (chat["createdAt"] as Timestamp).toDate()
                              : DateTime.now();

                          return InkWell(
                            onTap: () async {
                              // Check internet connection before opening modal
                              bool isConnected = await _checkInternetConnection();
                              if (!isConnected) {
                                FocusScope.of(context).unfocus();
                                await Future.delayed(const Duration(milliseconds: 100));
                                _showOfflineDialog();
                                return;
                              }
                              
                              _openChatModal(
                                context,
                                messages,
                                chatDoc.id,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// Title
                                  Text(
                                    preview,
                                    style: GoogleFonts.mulish(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 4),

                                  /// Subtitle
                                  if (aiPreview.isNotEmpty)
                                    Text(
                                      aiPreview,
                                      style: GoogleFonts.mulish(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                  const SizedBox(height: 6),

                                  /// Time row
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeago.format(createdAt),
                                        style: GoogleFonts.mulish(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Modal bottom sheet
  void _openChatModal(
    BuildContext context,
    List<Map<String, dynamic>> messages,
    String chatId,
  ) {
    final geminiService = GeminiService(dotenv.env['GEMINI_API_KEY'] ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => HistoryChatModal(
        messages: messages,
        chatId: chatId,
        geminiService: geminiService,
      ),
    );
  }
}
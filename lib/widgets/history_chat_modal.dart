import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/gemini_service.dart';

class HistoryChatModal extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final String chatId;
  final GeminiService geminiService;

  const HistoryChatModal({
    Key? key,
    required this.messages,
    required this.chatId,
    required this.geminiService,
  }) : super(key: key);

  @override
  State<HistoryChatModal> createState() => _HistoryChatModalState();
}

class _HistoryChatModalState extends State<HistoryChatModal>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final ValueNotifier<String> _selectedSegment = ValueNotifier('five');
  late AnimationController _gradientController;
  late AnimationController _rotationController;
  bool _isUserTyping = false;
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  late List<Map<String, dynamic>> _messages;
  String? _lastQuery;

  @override
  void initState() {
    super.initState();

    _textController.addListener(() {
      setState(() {
        _isUserTyping = _textController.text.trim().isNotEmpty;
      });
    });

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _messages = List.from(widget.messages);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _gradientController.dispose();
    _rotationController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<bool> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;

    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
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
                    if (await _checkInternetConnection()) {
                      _sendMessage();
                    } else {
                      _showOfflineDialog();
                    }
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

  Future<void> _appendMessage(Map<String, dynamic> message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("chats")
        .doc(widget.chatId)
        .update({
          "messages": FieldValue.arrayUnion([message]),
        });
  }

  Future<void> _sendMessage() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      FocusScope.of(context).unfocus(); // Hide keyboard first
      await Future.delayed(const Duration(milliseconds: 100)); // Give time
      _showOfflineDialog();
      return;
    }

    final query = _textController.text.trim();
    if (query.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _lastQuery = query;
      _messages.add({"role": "user", "message": query});
      _textController.clear();
    });
    await _appendMessage({"role": "user", "message": query});
    _scrollToBottom();

    try {
      final results = await widget.geminiService.fetchExplanations(query);

      setState(() {
        _messages.add({
          "role": "assistant",
          "message_five": results[0],
          "message_fifteen": results[1],
          "message_adult": results[2],
        });
      });

      await _appendMessage({
        "role": "assistant",
        "message_five": results[0],
        "message_fifteen": results[1],
        "message_adult": results[2],
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "message_five": "Error: $e",
          "message_fifteen": "",
          "message_adult": "",
        });
      });

      await _appendMessage({
        "role": "assistant",
        "message_five": "Error: $e",
        "message_fifteen": "",
        "message_adult": "",
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              /// Header
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              /// Tab switcher
              Container(
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.yellowAccent.withOpacity(0.15),
                    width: 1.2,
                  ),
                ),
                child: AdvancedSegment(
                  controller: _selectedSegment,
                  segments: const {
                    'five': "Like I'm 5",
                    'fifteen': "Like I'm 15",
                    'adult': "Like I'm an Adult",
                  },
                  backgroundColor: Colors.transparent,
                  sliderColor: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  activeStyle: GoogleFonts.mulish(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  inactiveStyle: GoogleFonts.mulish(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),

                  itemPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              /// Messages list
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: _selectedSegment,
                  builder: (context, selected, _) {
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isLoading && index == _messages.length) {
                          // Loader like HomeScreen
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RotationTransition(
                                  turns: _rotationController,
                                  child: Image.asset(
                                    "assets/icons/star.png",
                                    height: 22,
                                    width: 22,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Just a sec...",
                                  style: GoogleFonts.mulish(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final msg = _messages[index];
                        final isUser = msg["role"] == "user";

                        String text = "";
                        if (isUser) {
                          text = msg["message"] ?? "";
                        } else {
                          if (selected == "five") {
                            text = msg["message_five"] ?? "";
                          } else if (selected == "fifteen") {
                            text = msg["message_fifteen"] ?? "";
                          } else {
                            text = msg["message_adult"] ?? "";
                          }
                        }

                        if (text.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 12,
                                ),
                                padding: const EdgeInsets.all(12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFFFFA775)
                                      : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: MarkdownBody(
                                  data: text,
                                  styleSheet: MarkdownStyleSheet(
                                    p: GoogleFonts.mulish(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    strong: GoogleFonts.mulish(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (!isUser) _buildActionRow(text),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              /// Input field
              AnimatedPadding(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.only(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  top: 4,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: AnimatedBuilder(
                    animation: _gradientController,
                    builder: (context, child) {
                      return Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFA775),
                              const Color(0xFFF0CF7B),
                            ],
                            stops: const [0, 1.0],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            transform: GradientRotation(
                              _gradientController.value * 6.28,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(1.5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () {
                                    // Handle star icon click
                                  },
                                  child: Image.asset(
                                    "assets/icons/star.png",
                                    height: 22,
                                    width: 22,
                                    color: Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    enabled: !_isLoading,
                                    style: GoogleFonts.mulish(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    cursorColor: const Color(0xFFF0CF7B),
                                    decoration: InputDecoration(
                                      hintText: "Type your message...",
                                      hintStyle: GoogleFonts.mulish(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _isUserTyping
                                      ? GestureDetector(
                                          key: const ValueKey('arrowButton'),
                                          onTap: _isLoading
                                              ? null
                                              : _sendMessage,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 12.0,
                                            ),
                                            child: Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _isLoading
                                                    ? Colors.grey
                                                    : Colors.orange,
                                              ),
                                              child: const Icon(
                                                FluentIcons.arrow_up_12_regular,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox(
                                          width: 12,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Action Row (copy, regenerate, share)
  Widget _buildActionRow(String text) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            FluentIcons.copy_16_regular,
            size: 18,
            color: Color(0xFFFFA775),
          ),
          onPressed: () {
            if (text.isNotEmpty) {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Copied to clipboard',
                    style: GoogleFonts.mulish(color: Colors.white),
                  ),
                  backgroundColor: Colors.black87,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
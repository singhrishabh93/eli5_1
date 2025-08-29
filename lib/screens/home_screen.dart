import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eli5/widgets/animated_text.dart';
import 'package:eli5/widgets/appbar.dart';
import 'package:eli5/widgets/chat_modal.dart';
import 'package:eli5/widgets/highlights_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/gemini_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomeScreen extends StatefulWidget {
  final String? initialQuery;
  const HomeScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; //

  final _selectedSegment = ValueNotifier<String>('five');
  final _searchController = TextEditingController();
  final _geminiService = GeminiService(dotenv.env['GEMINI_API_KEY'] ?? "");
  bool _showHighlights = false;
  final ScrollController _scrollController = ScrollController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _currentChatId;
  String? _lastQuery;

  /// ✅ Store all messages persistently
  List<Map<String, String>> _homeMessages = [];
  bool _isLoading = false;

  late AnimationController _gradientController;
  late AnimationController _textAnimController;
  late Animation<Offset> _currentTextOffsetAnimation;
  late Animation<Offset> _nextTextOffsetAnimation;
  late Timer _suggestionTimer;
  late AnimationController _rotationController;

  final List<String> _wearSuggestions = [
    "Ask eli5 why popcorn pops",
    "Ask eli5 what is cloud computing",
    "Ask eli5 why ice floats on water",
    "Ask eli5 what is ChatGPT",
    "Ask eli5 why rainbows happen",
  ];
  int _currentSuggestionIndex = 0;
  int _nextSuggestionIndex = 1;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _getExplanation();
    }

    _searchController.addListener(() {
      setState(() {
        _isUserTyping = _searchController.text.trim().isNotEmpty;
      });
    });

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _textAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _currentTextOffsetAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.5)).animate(
          CurvedAnimation(
            parent: _textAnimController,
            curve: Curves.easeOutCubic,
          ),
        );

    _nextTextOffsetAnimation =
        Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _textAnimController,
            curve: Curves.easeOutCubic,
          ),
        );

    _suggestionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isUserTyping) {
        setState(() {
          _nextSuggestionIndex =
              (_currentSuggestionIndex + 1) % _wearSuggestions.length;
        });
        _textAnimController.reset();
        _textAnimController.forward();
      }
    });

    _textAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isUserTyping) {
        setState(() {
          _currentSuggestionIndex = _nextSuggestionIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _currentChatId = null; // ✅ clear chat session
    _homeMessages.clear(); // ✅ optional: clear messages too
    _gradientController.dispose();
    _textAnimController.dispose();
    _suggestionTimer.cancel();
    _searchController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _startNewChat() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final chatDoc = await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("chats")
        .add({"createdAt": FieldValue.serverTimestamp(), "messages": []});

    _currentChatId = chatDoc.id;
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

  Future<void> _appendMessage(Map<String, dynamic> message) async {
    final user = _auth.currentUser;
    if (user == null || _currentChatId == null) return;

    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("chats")
        .doc(_currentChatId)
        .update({
          "messages": FieldValue.arrayUnion([message]),
        });
  }

  /// ✅ Share functionality - copies text and opens native share
  Future<void> _shareText(String text) async {
    try {
      // First copy to clipboard
      await Clipboard.setData(ClipboardData(text: text));
      
      // Then open native share dialog
      await Share.share(
        text,
        subject: 'ELI5 Explanation', // Optional subject for email shares
      );
      
      // Show feedback that text was copied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Copied to clipboard and shared!',
              style: GoogleFonts.mulish(),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.withOpacity(0.8),
          ),
        );
      }
    } catch (e) {
      // Fallback: just copy to clipboard if share fails
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Copied to clipboard',
              style: GoogleFonts.mulish(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// ✅ Modified to keep old messages and append new response
  Future<void> _getExplanation() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      FocusScope.of(context).unfocus(); // ✅ Hide keyboard first
      await Future.delayed(const Duration(milliseconds: 100)); // ✅ Give time
      _showOfflineDialog();
      return;
    }
    final query = _searchController.text.trim();

    // ✅ Use _lastQuery if input is empty (for regenerate)
    if (query.isEmpty && _lastQuery == null) return;
    _lastQuery = query.isNotEmpty ? query : _lastQuery;

    // 🔹 Ensure we have a chat session
    if (_currentChatId == null) {
      await _startNewChat();
    }

    // 🔹 If user typed new query
    if (query.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _homeMessages.add({"role": "user", "message": query});
        _searchController.clear(); // clear input box
      });
      await _appendMessage({"role": "user", "message": query});

      _scrollToBottom();
    } else {
      // ✅ Regenerate case → just show loader
      setState(() {
        _isLoading = true;
      });
    }

    try {
      /// ✅ Fetch new responses always using _lastQuery
      final results = await _geminiService.fetchExplanations(_lastQuery!);

      setState(() {
        _homeMessages.add({
          "role": "ai",
          "message_five": results[0],
          "message_fifteen": results[1],
          "message_adult": results[2],
        });
      });

      await _appendMessage({
        "role": "ai",
        "message_five": results[0],
        "message_fifteen": results[1],
        "message_adult": results[2],
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _homeMessages.add({
          "role": "ai",
          "message_five": "Error: $e",
          "message_fifteen": "",
          "message_adult": "",
        });
      });

      await _appendMessage({
        "role": "ai",
        "message_five": "Error: $e",
        "message_fifteen": "",
        "message_adult": "",
      });

      _scrollToBottom();
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _handleNewChat() {
    setState(() {
      _currentChatId = null; // reset chat
      _homeMessages.clear(); // clear UI
    });
  }

  void _openChatModal({String? initialMessage}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatModal(
        geminiService: _geminiService,
        initialMessage: initialMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ must call when using keepAlive
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Image.asset(
            "assets/bg1.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: customAppBar(context, onNewChat: _handleNewChat),
          ),
          Column(
            children: [
              SizedBox(
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
              ),

              /// ✅ Show tabs only if there is at least one AI message
              if (_homeMessages.any((msg) => msg["role"] == "ai"))
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
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
                      sliderColor: Colors.yellowAccent.withOpacity(0.2),
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
                ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _showHighlights
                      ? HighlightsWidget(
                          onCardTap: (query) {
                            setState(() {
                              _searchController.text = query;
                              _showHighlights =
                                  false; // hide highlights after selection
                            });
                            _getExplanation();
                          },
                        )
                      : (_homeMessages.isEmpty && !_isLoading)
                      ? const Center(
                          child: AnimatedGradientText(text: "Hey Awesome!"),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount:
                              _homeMessages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            // ✅ Show loader as the last item if still loading
                            if (_isLoading && index == _homeMessages.length) {
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

                            // ✅ Render messages normally
                            final msg = _homeMessages[index];
                            final isUser = msg["role"] == "user";

                            String aiText = "";
                            if (!isUser) {
                              aiText = _selectedSegment.value == 'five'
                                  ? msg["message_five"] ?? ""
                                  : _selectedSegment.value == 'fifteen'
                                  ? msg["message_fifteen"] ?? ""
                                  : msg["message_adult"] ?? "";
                            } else {
                              aiText = msg["message"] ?? "";
                            }

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
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? const Color(0xFFFFA775)
                                          : Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: MarkdownBody(
                                      data: aiText,
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
                                if (!isUser) _buildActionRow(aiText),
                              ],
                            );
                          },
                        ),
                ),
              ),

              /// ✅ Input Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                          stops: [0, 1.0],
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
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 8.0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _showHighlights = !_showHighlights;
                                    });
                                  },
                                  child: Image.asset(
                                    "assets/icons/star.png",
                                    height: 20,
                                    width: 20,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    if (!_isUserTyping)
                                      IgnorePointer(
                                        ignoring: true,
                                        child: AnimatedBuilder(
                                          animation: _textAnimController,
                                          builder: (context, child) {
                                            return SizedBox(
                                              height: 30,
                                              child: ClipRect(
                                                child: Stack(
                                                  children: [
                                                    SlideTransition(
                                                      position:
                                                          _currentTextOffsetAnimation,
                                                      child: Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          " ${_wearSuggestions[_currentSuggestionIndex]}",
                                                          style:
                                                              GoogleFonts.mulish(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    SlideTransition(
                                                      position:
                                                          _nextTextOffsetAnimation,
                                                      child: Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          " ${_wearSuggestions[_nextSuggestionIndex]}",
                                                          style:
                                                              GoogleFonts.mulish(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    TextField(
                                      controller: _searchController,
                                      // enabled:
                                      //     !_isLoading, // ⬅️ disable input while waiting
                                      style: GoogleFonts.mulish(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      cursorColor: const Color(0xffFF0CF7B),
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 0,
                                            ),
                                        border: InputBorder.none,
                                        hintStyle: GoogleFonts.mulish(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      onSubmitted: (_) => !_isLoading
                                          ? _getExplanation()
                                          : null, // ⬅️ block enter
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                child: _isUserTyping
                                    ? GestureDetector(
                                        key: const ValueKey('arrow'),
                                        onTap: _isLoading
                                            ? null
                                            : _getExplanation,
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
                                            child: Icon(
                                              FluentIcons.arrow_up_12_regular,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(
                                        key: ValueKey('empty'),
                                        width: 38,
                                        height: 38,
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
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ Action Row for AI Messages
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
                    style: GoogleFonts.mulish(),
                  ),
                ),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(
            FluentIcons.history_16_filled,
            size: 18,
            color: Color(0xFFFFA775),
          ),
          onPressed: () {
            if (_lastQuery != null && !_isLoading) {
              _getExplanation();
            }
          },
        ),
        IconButton(
          icon: const Icon(
            FluentIcons.share_ios_20_filled,
            size: 18,
            color: Color(0xFFFFA775),
          ),
          onPressed: () {
            // ✅ Updated share functionality
            if (text.isNotEmpty) {
              _shareText(text);
            }
          },
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: GestureDetector(
            onTap: () async {
              bool isConnected = await _checkInternetConnection();
              if (!isConnected) {
                FocusScope.of(context).unfocus();
                await Future.delayed(const Duration(milliseconds: 100));
                _showOfflineDialog();
                return;
              }
              _openChatModal(initialMessage: text);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/icons/star.png",
                    height: 18,
                    width: 18,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Explain",
                    style: GoogleFonts.mulish(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
                      _getExplanation();
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
}
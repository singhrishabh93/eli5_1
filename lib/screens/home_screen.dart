import 'dart:async';
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
import '../services/openai_service.dart';

class HomeScreen extends StatefulWidget {
  final String? initialQuery;
  const HomeScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
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

  /// ✅ Modified to keep old messages and append new response
  Future<void> _getExplanation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // 🔹 Ensure we have a chat session
    if (_currentChatId == null) {
      await _startNewChat();
    }

    // 🔹 Add user message immediately
    setState(() {
      _isLoading = true;
      _homeMessages.add({"role": "user", "message": query});
      _searchController.clear(); // clear input box
    });
    await _appendMessage({"role": "user", "message": query});

    _scrollToBottom();

    try {
      /// ✅ Fetch 3 responses from AI
      final results = await _geminiService.fetchExplanations(query);

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentChatId = null; // ✅ reset chat
            _homeMessages.clear(); // ✅ clear UI
          });
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Image.asset(
            "assets/bg1.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(top: 0, left: 0, right: 0, child: customAppBar()),
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
                        'five': "Like I’m 5",
                        'fifteen': "Like I’m 15",
                        'adult': "Like I’m an Adult",
                      },
                      backgroundColor: Colors.transparent,
                      sliderColor: Colors.yellowAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      activeStyle: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w600,
                      ),
                      inactiveStyle: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Mulish',
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
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontFamily:
                                                                    "SatoshiR",
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
                                      style: const TextStyle(
                                        // This controls the typed text color
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: "SatoshiR",
                                      ),
                                      cursorColor: Color(0xffFF0CF7B),
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 0,
                                        ),
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: "SatoshiR",
                                        ),
                                      ),
                                      onSubmitted: (_) => _getExplanation(),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _getExplanation();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 16.0),
                                  child: Icon(
                                    FluentIcons.send_20_filled,
                                    color: Color(0xFFF0CF7B),
                                    size: 24,
                                  ),
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
                const SnackBar(content: Text('Copied to clipboard')),
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
          onPressed: _getExplanation,
        ),
        IconButton(
          icon: const Icon(
            FluentIcons.share_ios_20_filled,
            size: 18,
            color: Color(0xFFFFA775),
          ),
          onPressed: () {
            // Implement Share functionality
          },
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: GestureDetector(
            onTap: () => _openChatModal(initialMessage: text),
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
}

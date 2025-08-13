import 'dart:async';
import 'package:eli5/widgets/animated_text.dart';
import 'package:eli5/widgets/appbar.dart';
import 'package:eli5/widgets/highlights_widget.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/openai_service.dart';

class HomeScreen extends StatefulWidget {
  final String? initialQuery;
  const HomeScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _selectedSegment = ValueNotifier<String>('five');
  final _searchController = TextEditingController();
  final _geminiService = GeminiService(dotenv.env['GEMINI_API_KEY'] ?? "");
  bool _showHighlights = false; // Toggle to show highlights or explanations

  List<String> _explanations = ["", "", ""];
  bool _isLoading = false;

  late AnimationController _gradientController;
  late AnimationController _textAnimController;
  late Animation<Offset> _currentTextOffsetAnimation;
  late Animation<Offset> _nextTextOffsetAnimation;
  late Timer _suggestionTimer;

  final List<String> _wearSuggestions = [
    "Ask eli5 for party outfits",
    "Ask eli5 for date fit check",
    "Ask eli5 for coffee outfit ideas",
    "Ask eli5 for cute summer outfits",
    "Ask eli5 for workwear suggestions",
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
    _gradientController.dispose();
    _textAnimController.dispose();
    _suggestionTimer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getExplanation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final results = await _geminiService.fetchExplanations(query);
      setState(() {
        _explanations = results;
        _searchController.clear(); // ⬅ Clear search bar after search
      });
    } catch (e) {
      setState(() {
        _explanations = ["Error: $e", "", ""];
        _searchController.clear(); // ⬅ Also clear if there's an error
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Image.asset(
            "assets/bg.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Show tab bar only if there is at least one response
                      if (_explanations.any((e) => e.isNotEmpty))
                        SizedBox(
                          height: 60,
                          child: AdvancedSegment(
                            controller: _selectedSegment,
                            segments: const {
                              'five': "Like I’m 5",
                              'fifteen': "Like I’m 15",
                              'adult': "Like I’m an Adult",
                            },
                            backgroundColor: const Color(0xFFFF6A7D),
                            sliderColor: const Color(0xFFE62940),
                            borderRadius: BorderRadius.circular(30),
                            activeStyle: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Mulish',
                              fontWeight: FontWeight.w600,
                            ),
                            inactiveStyle: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Mulish',
                              fontWeight: FontWeight.w500,
                            ),
                            itemPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                          ),
                        ),

                      if (_explanations.any((e) => e.isNotEmpty))
                        const SizedBox(height: 12),

                      Expanded(
                        child: _showHighlights
                            ? const HighlightsWidget()
                            : (_isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : ValueListenableBuilder<String>(
                                      valueListenable: _selectedSegment,
                                      builder: (context, value, _) {
                                        int index = value == 'five'
                                            ? 0
                                            : value == 'fifteen'
                                            ? 1
                                            : 2;

                                        // If no explanations, show "Hey Awesome!"
                                        if (_explanations.every(
                                          (e) => e.isEmpty,
                                        )) {
                                          return const Center(
                                            child: AnimatedGradientText(
                                              text: "Hey Awesome!",
                                            ),
                                          );
                                        }

                                        return ListView(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          children: [
                                            _buildExplanationText(
                                              _explanations[index],
                                            ),
                                          ],
                                        );
                                      },
                                    )),
                      ),
                    ],
                  ),
                ),
              ),

              // Search bar
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
                            const Color(0xFFE62940),
                            const Color(0xFFFFD700),
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
                            color: Colors.white,
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
                                      _showHighlights =
                                          !_showHighlights; // toggle instead of always true
                                    });
                                  },

                                  child: Image.asset(
                                    "assets/icons/star.png",
                                    height: 20,
                                    width: 20,
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
                                                              const TextStyle(
                                                                color: Colors
                                                                    .black54,
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
                                                                    .black54,
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
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 0,
                                        ),
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color: Colors.black,
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
                                  _searchController.clear(); // Clear instantly
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 16.0),
                                  child: Icon(
                                    Icons.search,
                                    color: Colors.black,
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

  Widget _buildExplanationText(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explanation card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              text.isEmpty ? "No explanation yet." : text,
              style: GoogleFonts.mulish(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ),

        // Action buttons outside the card
        Row(
          children: [
            IconButton(
              icon: const Icon(
                FluentIcons.copy_16_regular,
                size: 18,
                color: Color(0xFFFF5266),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                if (text.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                FluentIcons.history_16_filled,
                size: 18,
                color: Color(0xFFFF5266),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _getExplanation(); // Regenerate with current query
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                FluentIcons.share_ios_20_filled,
                size: 18,
                color: Color(0xFFFF5266),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                // Placeholder for more menu actions
              },
            ),
          ],
        ),
      ],
    );
  }
}

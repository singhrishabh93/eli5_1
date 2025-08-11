import 'dart:async';
import 'package:eli5/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/openai_service.dart';

class HomeScreen extends StatefulWidget {
  final String? initialQuery;
  const HomeScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _geminiService = GeminiService(dotenv.env['GEMINI_API_KEY'] ?? "");

  List<String> _explanations = ["", "", ""];
  bool _isLoading = false;

  // Animation for suggestion text
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

    _tabController = TabController(length: 3, vsync: this);

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _getExplanation();
    }

    // Listen for typing changes
    _searchController.addListener(() {
      setState(() {
        _isUserTyping = _searchController.text.trim().isNotEmpty;
      });
    });

    // Gradient animation
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Text suggestion animation
    _textAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _currentTextOffsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(parent: _textAnimController, curve: Curves.easeOutCubic));

    _nextTextOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textAnimController, curve: Curves.easeOutCubic));

    _suggestionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isUserTyping) {
        setState(() {
          _nextSuggestionIndex = (_currentSuggestionIndex + 1) % _wearSuggestions.length;
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
    _tabController.dispose();
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
      setState(() => _explanations = results);
    } catch (e) {
      setState(() {
        _explanations = ["Error: $e", "", ""];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar(),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.black,
                    tabs: const [
                      Tab(text: "Like I’m 5"),
                      Tab(text: "Like I’m 15"),
                      Tab(text: "Like I’m an Adult"),
                    ],
                  ),
                  const SizedBox(height: 12),
    
                  // Content
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildExplanationText(_explanations[0]),
                              _buildExplanationText(_explanations[1]),
                              _buildExplanationText(_explanations[2]),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
    
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [const Color(0xFFE62940), const Color(0xFFFFD700)],
                      stops: [0, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      transform: GradientRotation(_gradientController.value * 6.28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                            child: Image.asset("assets/icons/star.png", height: 20, width: 20),
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
                                                  position: _currentTextOffsetAnimation,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                      " ${_wearSuggestions[_currentSuggestionIndex]}",
                                                      style: const TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 16,
                                                        fontFamily: "SatoshiR",
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SlideTransition(
                                                  position: _nextTextOffsetAnimation,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                      " ${_wearSuggestions[_nextSuggestionIndex]}",
                                                      style: const TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 16,
                                                        fontFamily: "SatoshiR",
                                                        fontStyle: FontStyle.italic,
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
                                    contentPadding: EdgeInsets.symmetric(horizontal: 0),
                                    border: InputBorder.none,
                                    // hintText: "Ask Nova",
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
                            onTap: _getExplanation,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 16.0),
                              child: Icon(Icons.search, color: Colors.black, size: 24),
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
    );
  }

  Widget _buildExplanationText(String text) {
    return SingleChildScrollView(
      child: Text(
        text.isEmpty ? "No explanation yet." : text,
        style: const TextStyle(fontSize: 16, height: 1.4),
      ),
    );
  }
}

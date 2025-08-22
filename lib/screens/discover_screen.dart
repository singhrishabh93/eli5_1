import 'dart:convert';
import 'dart:async';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import 'package:shimmer/shimmer.dart';
import '../services/gemini_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final String apiKey = dotenv.env['NEWS_API_KEY'] ?? "";

  final List<Map<String, String>> categories = [
    {"label": "For You", "value": "general"},
    {"label": "Top Stories", "value": "top"},
    {"label": "Tech & Science", "value": "technology"},
    {"label": "Finance", "value": "business"},
    {"label": "Arts & Culture", "value": "entertainment"},
    {"label": "Sports", "value": "sports"},
    {"label": "Entertainment", "value": "entertainment"},
  ];

  String selectedCategory = "general";
  List articles = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int page = 1;
  final int pageSize = 20;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    fetchNews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        !isLoading) {
      loadMoreNews();
    }
  }

  Future<void> fetchNews({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() => isLoadingMore = true);
    } else {
      setState(() {
        isLoading = true;
        articles.clear();
        page = 1;
      });
    }

    String url;
    if (selectedCategory == "top") {
      url =
          "https://newsapi.org/v2/top-headlines?country=us&apiKey=$apiKey&pageSize=$pageSize&page=$page";
    } else {
      url =
          "https://newsapi.org/v2/top-headlines?country=us&category=$selectedCategory&apiKey=$apiKey&pageSize=$pageSize&page=$page";
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        if (isLoadMore) {
          articles.addAll(data["articles"] ?? []);
          isLoadingMore = false;
        } else {
          articles = data["articles"] ?? [];
          isLoading = false;
        }
      });
    } else {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void loadMoreNews() {
    page++;
    fetchNews(isLoadMore: true);
  }

  void _openArticleBottomSheet(Map<String, dynamic> article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.8,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _ArticleDetailSheet(article: article);
          },
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.white.withOpacity(0.08),
                  highlightColor: Colors.white.withOpacity(0.25),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Shimmer.fromColors(
                  baseColor: Colors.white.withOpacity(0.08),
                  highlightColor: Colors.white.withOpacity(0.25),
                  child: Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.white.withOpacity(0.08),
                  highlightColor: Colors.white.withOpacity(0.25),
                  child: Container(height: 14, width: 150, color: Colors.white),
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "Discover",
          style: GoogleFonts.mulish(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xffFFFFFF),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              FluentIcons.heart_12_filled,
              color: Color(0xffFFFFFF),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Image.asset(
            "assets/bg3.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Column(
            children: [
              SizedBox(
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category["value"];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category["value"]!;
                        });
                        fetchNews();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xffFFA775)
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            category["label"]!,
                            style: GoogleFonts.mulish(
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? _buildShimmerList()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: articles.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == articles.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final article = articles[index];
                          return GestureDetector(
                            onTap: () => _openArticleBottomSheet(article),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1.2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          clipBehavior: Clip.hardEdge,
                                          child: article["urlToImage"] != null
                                              ? Image.network(
                                                  article["urlToImage"],
                                                  height: 180,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  height: 180,
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.image,
                                                      color: Colors.white70,
                                                      size: 40,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                article["isLiked"] =
                                                    !(article["isLiked"] ??
                                                        false);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.4,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                article["isLiked"] == true
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color:
                                                    article["isLiked"] == true
                                                    ? Colors.red
                                                    : Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      article["title"] ?? "",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.mulish(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.public,
                                          size: 16,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            article["source"]["name"] ?? "",
                                            style: GoogleFonts.mulish(
                                              fontSize: 14,
                                              color: Colors.grey[300],
                                            ),
                                          ),
                                        ),
                                      ],
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
}

// Keep your _ArticleDetailSheet class as is
class _ArticleDetailSheet extends StatefulWidget {
  final Map<String, dynamic> article;
  const _ArticleDetailSheet({required this.article});

  @override
  State<_ArticleDetailSheet> createState() => _ArticleDetailSheetState();
}

class _ArticleDetailSheetState extends State<_ArticleDetailSheet> {
  final _selectedSegment = ValueNotifier<String>('five');
  final _geminiService = GeminiService(dotenv.env['GEMINI_API_KEY'] ?? "");

  final List<String> _explanations = ["", "", ""];
  final List<bool> _isLoading = [false, false, false];
  bool _hasExplanation = false;
  bool _isFetchingExplanations = false;

  Future<void> _loadThreeLevelExplanation() async {
    setState(() {
      _isFetchingExplanations = true;
    });

    try {
      final results = await _geminiService.fetchExplanations(
        widget.article["title"] ?? "",
      );
      setState(() {
        _explanations[0] = results[0];
        _explanations[1] = results[1];
        _explanations[2] = results[2];
        _hasExplanation = true; // Now show tab bar
      });
    } catch (e) {
      setState(() {
        _explanations[0] = "Error: $e";
      });
    } finally {
      setState(() {
        _isFetchingExplanations = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.article["urlToImage"] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.article["urlToImage"],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.article["title"] ?? "",
                            style: GoogleFonts.mulish(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.article["description"] ?? "",
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Explain Button
                    Center(
                      child: GestureDetector(
                        onTap: _loadThreeLevelExplanation,
                        child: Container(
                          height: 50,
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
                              const Text(
                                "Explain like I'm 5",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isFetchingExplanations)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFA775),
                          ),
                        ),
                      ),

                    if (_hasExplanation)
                      Column(
                        children: [
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
                                'five': "Like I’m 5",
                                'fifteen': "Like I’m 15",
                                'adult': "Like I’m an Adult",
                              },
                              backgroundColor: Colors.transparent,
                              sliderColor: Colors.white.withOpacity(0.2),
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
                          ValueListenableBuilder<String>(
                            valueListenable: _selectedSegment,
                            builder: (context, value, _) {
                              int index = value == 'five'
                                  ? 0
                                  : value == 'fifteen'
                                  ? 1
                                  : 2;

                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1.2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    _explanations[index].isEmpty
                                        ? "No explanation yet."
                                        : _explanations[index],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

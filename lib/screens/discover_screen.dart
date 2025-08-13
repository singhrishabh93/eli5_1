// --- DiscoverScreen.dart ---
import 'dart:convert';
import 'dart:async';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import '../services/openai_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        title: Text(
          "Discover",
          style: GoogleFonts.mulish(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xffFF3951),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              FluentIcons.heart_12_filled,
              color: Color(0xffFF3951),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Image.asset("assets/bg.png",
              fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Column(
            children: [
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
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(0xffFF3951)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Color(0xffFF3951),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            category["label"]!,
                            style: GoogleFonts.mulish(
                              color: isSelected
                                  ? Colors.white
                                  : Color(0xffFF3951),
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
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount:
                            articles.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == articles.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          }
                          final article = articles[index];
                          return GestureDetector(
                            onTap: () => _openArticleBottomSheet(article),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3951),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                    child: article["urlToImage"] != null
                                        ? Image.network(
                                            article["urlToImage"],
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: 200,
                                            color: Color(0xffFF5266),
                                            child: const Center(
                                              child: Icon(Icons.image,
                                                  color: Colors.white),
                                            ),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      article["title"] ?? "",
                                      style: GoogleFonts.mulish(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.public,
                                            size: 18,
                                            color: Colors.grey[300]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            article["source"]["name"] ??
                                                "",
                                            style: GoogleFonts.mulish(
                                              fontSize: 14,
                                              color: Colors.grey[300],
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.favorite_border,
                                              color: Colors.white),
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

// --- Article Bottom Sheet ---
class _ArticleDetailSheet extends StatefulWidget {
  final Map<String, dynamic> article;
  const _ArticleDetailSheet({required this.article});

  @override
  State<_ArticleDetailSheet> createState() => _ArticleDetailSheetState();
}

class _ArticleDetailSheetState extends State<_ArticleDetailSheet> {
  final _selectedSegment = ValueNotifier<String>('five');
  final _geminiService = GeminiService(dotenv.env['GEMINI_API_KEY'] ?? "");
  List<String> _explanations = ["", "", ""];
  bool _isLoading = false;

  Future<void> _getExplanation() async {
    final query = widget.article["title"] ?? "";
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await _geminiService.fetchExplanations(query);
      setState(() => _explanations = results);
    } catch (e) {
      setState(() => _explanations = ["Error: $e", "", ""]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          if (widget.article["urlToImage"] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(widget.article["urlToImage"],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Text(widget.article["title"] ?? "",
              style: GoogleFonts.mulish(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(widget.article["description"] ?? "",
              style: GoogleFonts.mulish(
                  fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 16),

          // "Explain Like I'm 5" Button
          ElevatedButton.icon(
            onPressed: _getExplanation,
            icon: Icon(Icons.lightbulb_outline),
            label: Text("Explain Like I’m 5"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3951),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          if (_explanations.any((e) => e.isNotEmpty))
            AdvancedSegment(
              controller: _selectedSegment,
              segments: const {
                'five': "Like I’m 5",
                'fifteen': "Like I’m 15",
                'adult': "Like I’m an Adult",
              },
              backgroundColor: const Color(0xFFFF5266),
              sliderColor: const Color(0xFFFF3951),
              borderRadius: BorderRadius.circular(8),
              activeStyle: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Mulish',
                  fontWeight: FontWeight.w600),
              inactiveStyle: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Mulish',
                  fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ValueListenableBuilder<String>(
                    valueListenable: _selectedSegment,
                    builder: (context, value, _) {
                      int index = value == 'five'
                          ? 0
                          : value == 'fifteen'
                              ? 1
                              : 2;
                      return SingleChildScrollView(
                        child: Text(
                          _explanations[index].isEmpty
                              ? "No explanation yet."
                              : _explanations[index],
                          style: const TextStyle(
                              fontSize: 16, height: 1.4),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

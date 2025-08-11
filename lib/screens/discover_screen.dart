import 'dart:convert';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final String apiKey = "2b45bde099164ea6a148274750ed2a04";

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
      setState(() {
        isLoadingMore = true;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        // backgroundColor: const Color(0xFF121212),
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
            icon: const Icon(FluentIcons.heart_12_filled, color:Color(0xffFF3951),),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Image.asset("assets/bg.png", fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Column(
            children: [
            // Category Pills
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(0xffFF3951)
                            : const Color(0xFFFFFFFF),
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
                            color: isSelected ? Colors.white : Color(0xffFF3951),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
        
            // Articles List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: articles.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == articles.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final article = articles[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3951),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
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
                                        color: Color(0xffFF3951),
                                        child: const Center(
                                          child: Icon(Icons.image,
                                              color: Colors.white),
                                        ),
                                      ),
                              ),
        
                              // Title
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
        
                              // Bottom Row
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.public,
                                        size: 18, color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        article["source"]["name"] ?? "",
                                        style: GoogleFonts.mulish(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.favorite_border,
                                          color: Colors.white),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),]
      ),
    );
  }
}

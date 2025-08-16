import 'dart:convert';
import 'package:eli5/utils/knowledge_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({Key? key}) : super(key: key);

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  List<Map<String, String>> funScienceFacts = [];
  List<Map<String, String>> todayInHistory = [];

  final List<Map<String, String>> inventions = const [
    {
      "image":
          "https://upload.wikimedia.org/wikipedia/commons/3/3a/Light_bulb_invention.jpg",
      "headline": "Light Bulb",
      "text": "Revolutionized human life by enabling nighttime productivity.",
    },
    {
      "image":
          "https://upload.wikimedia.org/wikipedia/commons/4/45/First_phone.jpg",
      "headline": "Telephone",
      "text": "Connected people across the globe instantly.",
    },
  ];

  final List<Map<String, String>> unusualWords = const [
    {"word": "Petrichor", "meaning": "The pleasant smell after rain."},
    {
      "word": "Defenestration",
      "meaning": "The act of throwing someone out a window.",
    },
    {"word": "Limerence", "meaning": "The state of being infatuated."},
  ];

  final List<String> randomQuestions = const [
    "Why is the sky blue?",
    "How does Wi-Fi work?",
    "Why do cats purr?",
    "Why is yawning contagious?",
  ];

  bool isLoadingFacts = true;
  bool isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    fetchUselessFact();
    fetchTodayInHistory();
  }

  Future<void> fetchUselessFact() async {
    try {
      List<Map<String, String>> facts = [];
      for (int i = 0; i < 6; i++) {
        final res = await http.get(
          Uri.parse("https://uselessfacts.jsph.pl/random.json?language=en"),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          facts.add({"fact": data["text"] ?? "No fact available"});
        }
      }
      setState(() {
        funScienceFacts = facts;
      });
    } catch (e) {
      debugPrint("Error fetching facts: $e");
    } finally {
      setState(() => isLoadingFacts = false);
    }
  }

  Future<void> fetchTodayInHistory() async {
    try {
      final res = await http.get(Uri.parse("https://today.zenquotes.io/api"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final events = data["data"]["Events"] as List<dynamic>;
        List<Map<String, String>> eventsList = [];
        for (var event in events.take(5)) {
          String headline = event["text"] ?? "";
          eventsList.add({"headline": headline, "text": headline});
        }
        setState(() {
          todayInHistory = eventsList;
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      setState(() => isLoadingHistory = false);
    }
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
          "Knowledge",
          style: GoogleFonts.mulish(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xffFFFFFF),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Color(0xffFFFFFF)),
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
          Padding(
            padding: EdgeInsets.only(
              top: kToolbarHeight + MediaQuery.of(context).padding.top,
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildSectionTitle("Fun Science Facts"),
                isLoadingFacts
                    ? _buildShimmerCards(6, height: 120, width: 180)
                    : _buildHorizontalCards(funScienceFacts),

                _buildSectionTitle("Today in History"),
                isLoadingHistory
                    ? _buildShimmerCards(5, height: 250, width: 260)
                    : _buildGradientCards(todayInHistory),

                _buildSectionTitle("Inventions & Discoveries"),
                _buildHorizontalImageCards(inventions),

                _buildSectionTitle("Unusual Words & Phrases"),
                _buildWordCards(unusualWords),

                _buildSectionTitle("Random Questions"),
                _buildHorizontalCards(
                  randomQuestions.map((q) => {"fact": q}).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.mulish(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: [
            Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCards(int count, {required double height, required double width}) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.15),
            highlightColor: Colors.white.withOpacity(0.3),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Translucent Gradient Cards ---
  Widget _buildHorizontalCards(List<Map<String, String>> data,
      {bool isLarge = false, bool isNeon = false}) {
    return SizedBox(
      height: isLarge ? 200 : 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: isLarge ? 220 : 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(
                data[index]["fact"] ?? "",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.mulish(
                  fontSize: isLarge ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientCards(List<Map<String, String>> data) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data[index]["headline"] ?? "",
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data[index]["text"] ?? "",
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalImageCards(List<Map<String, String>> data) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = data[index];
          return Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["headline"]!,
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item["text"]!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWordCards(List<Map<String, String>> words) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: words.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = words[index];
          return Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["word"]!,
                  style: GoogleFonts.mulish(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item["meaning"]!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

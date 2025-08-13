import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

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
      "image": "https://upload.wikimedia.org/wikipedia/commons/3/3a/Light_bulb_invention.jpg",
      "headline": "Light Bulb",
      "text": "Revolutionized human life by enabling nighttime productivity."
    },
    {
      "image": "https://upload.wikimedia.org/wikipedia/commons/4/45/First_phone.jpg",
      "headline": "Telephone",
      "text": "Connected people across the globe instantly."
    },
  ];

  final List<Map<String, String>> unusualWords = const [
    {"word": "Petrichor", "meaning": "The pleasant smell after rain."},
    {"word": "Defenestration", "meaning": "The act of throwing someone out a window."},
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
      final res = await http.get(Uri.parse("https://uselessfacts.jsph.pl/random.json?language=en"));
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

      // Fetch images for first 5 events
      List<Map<String, String>> eventsWithImages = [];
      for (var event in events.take(5)) {
        String headline = event["text"] ?? "";
        String wikiImage = await fetchWikipediaImage(headline);

        eventsWithImages.add({
          "image": wikiImage.isNotEmpty
              ? wikiImage
              : "https://upload.wikimedia.org/wikipedia/commons/3/3c/Moon_landing.jpg", // fallback
          "headline": headline,
          "text": headline
        });
      }

      setState(() {
        todayInHistory = eventsWithImages;
      });
    }
  } catch (e) {
    debugPrint("Error fetching history: $e");
  } finally {
    setState(() => isLoadingHistory = false);
  }
}

/// Fetches the first image from Wikipedia for a given search term
Future<String> fetchWikipediaImage(String query) async {
  try {
    final url =
        "https://en.wikipedia.org/w/api.php?action=query&titles=${Uri.encodeComponent(query)}&prop=pageimages&format=json&pithumbsize=500";
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final pages = data["query"]["pages"] as Map<String, dynamic>;
      for (var page in pages.values) {
        if (page["thumbnail"] != null && page["thumbnail"]["source"] != null) {
          return page["thumbnail"]["source"];
        }
      }
    }
  } catch (e) {
    debugPrint("Error fetching Wikipedia image: $e");
  }
  return "";
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        title: Text(
          "Knowledge",
          style: GoogleFonts.mulish(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xffFF3951),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Color(0xffFF3951)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Image.asset("assets/bg.png",
              fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              _buildSectionTitle("Fun Science Facts"),
              isLoadingFacts
                  ? const Center(child: CircularProgressIndicator())
                  : _buildHorizontalCards(funScienceFacts, Colors.orangeAccent),

              _buildSectionTitle("Today in History"),
              isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _buildHorizontalImageCards(todayInHistory),

              _buildSectionTitle("Inventions & Discoveries"),
              _buildHorizontalImageCards(inventions),

              _buildSectionTitle("Unusual Words & Phrases"),
              _buildWordCards(unusualWords),

              _buildSectionTitle("Random Questions"),
              _buildHorizontalCards(
                randomQuestions.map((q) => {"fact": q}).toList(),
                Colors.tealAccent,
              ),
            ],
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
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildHorizontalCards(List<Map<String, String>> data, Color color, {bool isLarge = false}) {
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
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                data[index]["fact"] ?? "",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.mulish(
                  fontSize: isLarge ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    item["image"]!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item["headline"]!,
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    item["text"]!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mulish(fontSize: 14, color: Colors.black87),
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
              color: Colors.purpleAccent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["word"]!,
                  style: GoogleFonts.mulish(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item["meaning"]!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mulish(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

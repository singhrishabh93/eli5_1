import 'dart:convert';
import 'dart:io';
import 'package:eli5/widgets/knowledege_modal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({Key? key}) : super(key: key);

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  List<Map<String, String>> funScienceFacts = [];
  List<Map<String, String>> todayInHistory = [];
  List<Map<String, String>> triviaQuestions = [];
  List<Map<String, String>> boredActivities = [];
  List<Map<String, String>> quotes = [];

  bool isLoading = true;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndFetch();
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

  Future<void> _checkConnectivityAndFetch() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      setState(() {
        isLoading = false;
        isOffline = true;
      });
      // Show dialog after a brief delay to ensure widget is mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOfflineDialog();
      });
      return;
    }
    setState(() {
      isOffline = false;
    });
    _fetchAllData();
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
                      setState(() {
                        isOffline = false;
                        isLoading = true;
                      });
                      _fetchAllData();
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

  Widget _buildOfflineState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.wifi_off_20_filled,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No Internet Connection',
              style: GoogleFonts.mulish(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: GoogleFonts.mulish(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                await _checkConnectivityAndFetch();
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
  }

  Future<void> _fetchAllData() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      setState(() {
        isOffline = true;
        isLoading = false;
      });
      _showOfflineDialog();
      return;
    }

    setState(() {
      isOffline = false;
    });

    await Future.wait([
      fetchUselessFact(),
      fetchTodayInHistory(),
      fetchTrivia(),
      fetchBoredActivities(),
      fetchQuotes(),
    ]);
    setState(() => isLoading = false);
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
      funScienceFacts = facts;
    } catch (e) {}
  }

  Future<void> fetchTodayInHistory() async {
    try {
      final now = DateTime.now();
      final url =
          "https://en.wikipedia.org/api/rest_v1/feed/onthisday/events/${now.month}/${now.day}";
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final events = data["events"] as List<dynamic>;
        List<Map<String, String>> eventsList = [];
        for (var event in events.take(5)) {
          String headline = event["text"] ?? "";
          String description =
              event["pages"] != null && event["pages"].isNotEmpty
                  ? event["pages"][0]["description"] ?? ""
                  : "";
          String image = (event["pages"] != null &&
                  event["pages"].isNotEmpty &&
                  event["pages"][0]["thumbnail"] != null)
              ? event["pages"][0]["thumbnail"]["source"]
              : "";
          eventsList.add({
            "headline": headline,
            "text": description,
            "image": image,
          });
        }
        todayInHistory = eventsList;
      }
    } catch (e) {}
  }

  Future<void> fetchTrivia() async {
    try {
      final res =
          await http.get(Uri.parse("https://the-trivia-api.com/api/questions"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        List<Map<String, String>> triviaList = [];
        for (var item in data.take(5)) {
          triviaList.add({
            "question": item["question"] ?? "",
            "answer": item["correctAnswer"] ?? "",
          });
        }
        triviaQuestions = triviaList;
      }
    } catch (e) {}
  }

  Future<void> fetchBoredActivities() async {
    try {
      List<Map<String, String>> activities = [];
      for (int i = 0; i < 6; i++) {
        final res =
            await http.get(Uri.parse("https://bored-api.appbrewery.com/random"));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          activities.add({"activity": data["activity"] ?? ""});
        }
      }
      boredActivities = activities;
    } catch (e) {}
  }

  Future<void> fetchQuotes() async {
    try {
      List<Map<String, String>> quoteList = [];
      for (int i = 0; i < 6; i++) {
        final res = await http.get(Uri.parse("https://zenquotes.io/api/random"));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as List<dynamic>;
          if (data.isNotEmpty) {
            quoteList.add({"fact": data[0]["q"] ?? ""});
          }
        }
      }
      quotes = quoteList;
    } catch (e) {}
  }

  void _openKnowledgeModal(String type, Map<String, String> data) async {
    // Check internet connection before opening modal
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      _showOfflineDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.85,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return KnowledgeModalSheet(
              type: type,
              data: data,
            );
          },
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
          "Knowledge",
          style: GoogleFonts.mulish(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.favorite, color: Colors.white),
          //   onPressed: () {},
          // ),
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
            child: isOffline
                ? _buildOfflineState()
                : isLoading
                ? _buildFullPageShimmer()
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      _buildSectionTitle("Fun Science Facts"),
                      _buildHorizontalCards(funScienceFacts, "fact"),

                      _buildSectionTitle("Today in History"),
                      _buildImageCards(todayInHistory),

                      _buildSectionTitle("Trivia Questions"),
                      _buildHorizontalCards(triviaQuestions, "trivia"),

                      _buildSectionTitle("Bored Activities"),
                      _buildHorizontalCards(boredActivities, "activity"),

                      _buildSectionTitle("Motivational Quotes"),
                      _buildHorizontalCards(quotes, "quote"),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullPageShimmer() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _buildSectionTitle("Fun Science Facts"),
        _buildShimmerCards(6, height: 120, width: 180),
        _buildSectionTitle("Today in History"),
        _buildShimmerCards(5, height: 250, width: 260),
        _buildSectionTitle("Trivia Questions"),
        _buildShimmerCards(5, height: 120, width: 220),
        _buildSectionTitle("Bored Activities"),
        _buildShimmerCards(6, height: 120, width: 180),
        _buildSectionTitle("Motivational Quotes"),
        _buildShimmerCards(6, height: 120, width: 180),
      ],
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

  Widget _buildShimmerCards(int count,
      {required double height, required double width}) {
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

  Widget _buildHorizontalCards(List<Map<String, String>> data, String type) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openKnowledgeModal(type, data[index]),
            child: Container(
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
              child: Center(
                child: Text(
                  data[index]["fact"] ??
                      data[index]["question"] ??
                      data[index]["activity"] ??
                      data[index]["headline"] ??
                      "",
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageCards(List<Map<String, String>> data) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openKnowledgeModal("history", data[index]),
            child: Container(
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
                  if (data[index]["image"]!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data[index]["image"]!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    data[index]["headline"]!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data[index]["text"]!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mulish(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
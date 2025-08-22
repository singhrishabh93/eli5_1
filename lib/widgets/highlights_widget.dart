import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:shimmer/shimmer.dart';

class HighlightsCache {
  static List<dynamic>? songs;
  static List<dynamic>? newsArticles;
  static List<String>? advices;
  static List<Map<String, dynamic>>? topics;

  static DateTime? lastFetch;

  static bool get isValid {
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch!).inMinutes < 10; // cache 10 min
  }
}

class HighlightsWidget extends StatefulWidget {
  final Function(String) onCardTap;

  const HighlightsWidget({Key? key, required this.onCardTap}) : super(key: key);

  @override
  State<HighlightsWidget> createState() => _HighlightsWidgetState();
}

class _HighlightsWidgetState extends State<HighlightsWidget> {
  List<dynamic> songs = [];
  int currentIndex = 0;
  bool isLoading = true;

  List<dynamic> newsArticles = [];
  bool isNewsLoading = true;

  List<String> advices = [];
  bool isAdviceLoading = true;

  List<Map<String, dynamic>> topics = [];
  bool isTopicsLoading = true;

  bool get allLoaded =>
      !isLoading && !isNewsLoading && !isAdviceLoading && !isTopicsLoading;

  @override
  void initState() {
    super.initState();
    _loadData();
    fetchSongs();
    fetchNews();
    fetchAdvices();
    fetchTopics();
  }

  Future<void> _loadData() async {
    if (HighlightsCache.isValid) {
      setState(() {
        songs = HighlightsCache.songs ?? [];
        newsArticles = HighlightsCache.newsArticles ?? [];
        advices = HighlightsCache.advices ?? [];
        topics = HighlightsCache.topics ?? [];
        isLoading = false;
      });
      return;
    }

    await Future.wait([
      fetchSongs(),
      fetchNews(),
      fetchAdvices(),
      fetchTopics(),
    ]);

    HighlightsCache.songs = songs;
    HighlightsCache.newsArticles = newsArticles;
    HighlightsCache.advices = advices;
    HighlightsCache.topics = topics;
    HighlightsCache.lastFetch = DateTime.now();

    setState(() => isLoading = false);
  }

  Future<void> fetchSongs() async {
    try {
      final url =
          "https://itunes.apple.com/lookup?upc=720642462928&entity=song";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data["results"] ?? [];
        songs = results.where((r) => r["wrapperType"] == "track").toList();
      }
    } catch (_) {}
  }

  Future<void> fetchNews() async {
    try {
      final apiKey = dotenv.env['NEWS_API_KEY'] ?? "";
      final url =
          "https://newsapi.org/v2/top-headlines?country=us&pageSize=3&apiKey=$apiKey";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        newsArticles = data["articles"] ?? [];
      }
    } catch (_) {}
  }

  Future<void> fetchAdvices() async {
    try {
      List<String> results = [];
      for (int i = 0; i < 3; i++) {
        final res = await http.get(
          Uri.parse("https://api.adviceslip.com/advice"),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          results.add(data["slip"]["advice"]);
        }
      }
      advices = results;
    } catch (_) {
      advices = List.filled(3, "Stay positive!");
    }
  }

  Future<void> fetchTopics() async {
    try {
      var rng = Random();
      List<Map<String, dynamic>> results = [];
      for (int i = 0; i < 3; i++) {
        final id = 1000 + rng.nextInt(9000);
        final url =
            "https://hacker-news.firebaseio.com/v0/item/$id.json?print=pretty";
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data != null && data["text"] != null) {
            results.add({"title": "Discussion #$id", "text": data["text"]});
          }
        }
      }
      topics = results;
    } catch (_) {
      topics = List.generate(
        3,
        (i) => {"title": "Discussion", "text": "Something went wrong."},
      );
    }
  }

  void _showSongPlayer(BuildContext context, dynamic song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return PodcastPlayerModal(
          audioUrl: song["previewUrl"],
          title: song["trackName"] ?? "Unknown",
          subtitle: song["artistName"] ?? "",
          imageUrl: song["artworkUrl100"] ?? "https://picsum.photos/200",
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
    return _shimmerLoaderList();
  }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          "It's great to see you",
          style: GoogleFonts.mulish(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),

        // 🎵 Songs
        if (songs.isNotEmpty)
          GestureDetector(
            onTap: () {
              final song = songs[currentIndex];
              _showSongPlayer(context, song);
              setState(() {
                currentIndex = (currentIndex + 1) % songs.length;
              });
            },
            child: _songCard(songs[currentIndex]),
          )
        else
          _glassPlaceholder(),

        const SizedBox(height: 24),

        // 🔹 Stories
        _sectionWithMagazineGrid(
          "Stories to explore",
          ensureThree<Widget>(
            newsArticles.map((article) {
              return _imageCard(
                imageUrl: article["urlToImage"] ?? "https://picsum.photos/400",
                title: article["title"] ?? "No title",
                subtitle: article["description"] ?? "",
                onTap: widget.onCardTap,
              );
            }).toList(),
            (i) => _glassPlaceholder(),
          ),
        ),

        const SizedBox(height: 24),

        // 💡 Advices
        _sectionWithMagazineGrid(
          "Ideas to explore",
          ensureThree<Widget>(
            advices.asMap().entries.map((entry) {
              final i = entry.key;
              final advice = entry.value;
              return _imageCard(
                imageUrl: "https://picsum.photos/400/400?advice$i",
                title: "Advice",
                subtitle: advice,
                onTap: widget.onCardTap,
              );
            }).toList(),
            (i) => _glassPlaceholder(),
          ),
        ),

        const SizedBox(height: 24),

        // 🌐 Topics
        _sectionWithMagazineGrid(
          "Topics I thought you'd enjoy",
          ensureThree<Widget>(
            topics.asMap().entries.map((entry) {
              final i = entry.key;
              final topic = entry.value;
              return _imageCard(
                imageUrl: "https://picsum.photos/400/400?topic$i",
                title: topic["title"],
                subtitle: topic["text"],
                onTap: widget.onCardTap,
              );
            }).toList(),
            (i) => _glassPlaceholder(),
          ),
        ),
      ],
    );
  }

  // --- Shimmer Loaders ---
  Widget _shimmerLoaderList() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _shimmerBox(height: 24, borderRadius: 8, width: 200),
        const SizedBox(height: 16),
        _shimmerBox(height: 180, borderRadius: 24),
        const SizedBox(height: 24),
        _shimmerSection(),
        const SizedBox(height: 24),
        _shimmerSection(),
        const SizedBox(height: 24),
        _shimmerSection(),
      ],
    );
  }

  Widget _shimmerBox({
    double height = 100,
    double borderRadius = 20,
    double? width,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.08),
      highlightColor: Colors.white.withOpacity(0.25),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
        ),
      ),
    );
  }

  Widget _shimmerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerBox(height: 20, borderRadius: 8, width: 150),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _shimmerBox(height: 240, borderRadius: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _shimmerBox(height: 115, borderRadius: 20),
                  const SizedBox(height: 10),
                  _shimmerBox(height: 115, borderRadius: 20),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Helpers ---
  static List<T> ensureThree<T>(List<T> items, T Function(int) filler) {
    if (items.length >= 3) return items.sublist(0, 3);
    return List.generate(3, (i) => i < items.length ? items[i] : filler(i));
  }

  static Widget _glassPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.08),
      highlightColor: Colors.white.withOpacity(0.25),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
        ),
      ),
    );
  }

  static Widget _songCard(dynamic song) => Container(
    height: 180,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      image: DecorationImage(
        image: NetworkImage(song["artworkUrl100"]),
        fit: BoxFit.cover,
      ),
    ),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song["trackName"] ?? "Song",
          style: GoogleFonts.mulish(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          song["artistName"] ?? "",
          style: GoogleFonts.mulish(
            color: Colors.white70,
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text("Play now", style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );

  Widget _sectionWithMagazineGrid(String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.mulish(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: SizedBox(height: 240, child: cards[0])),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  SizedBox(height: 115, child: cards[1]),
                  const SizedBox(height: 10),
                  SizedBox(height: 115, child: cards[2]),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _imageCard({
    required String imageUrl,
    required String title,
    required String subtitle,
    required Function(String) onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap(title),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mulish(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mulish(
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PodcastPlayerModal extends StatefulWidget {
  final String audioUrl;
  final String title;
  final String subtitle;
  final String imageUrl;

  const PodcastPlayerModal({
    Key? key,
    required this.audioUrl,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<PodcastPlayerModal> createState() => _PodcastPlayerModalState();
}

class _PodcastPlayerModalState extends State<PodcastPlayerModal> {
  final _player = AudioPlayer();
  bool _isLoading = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _player.setUrl(widget.audioUrl);
      setState(() => _isLoading = false);
      _player.play();
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: NetworkImage(widget.imageUrl),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: GoogleFonts.mulish(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.mulish(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          _isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                )
              : IconButton(
                  iconSize: 64,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlayPause,
                ),
        ],
      ),
    );
  }
}

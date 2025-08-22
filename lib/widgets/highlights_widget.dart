// ✨ Added new APIs (Advice & HackerNews)
// Replaced static "Ideas to explore" + "Topics I thought you'd enjoy"
// with dynamic API content (3 cards each)

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:shimmer/shimmer.dart';

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

  @override
  void initState() {
    super.initState();
    fetchSongs();
    fetchNews();
    fetchAdvices();
    fetchTopics();
  }

  Future<void> fetchSongs() async {
    final url = "https://itunes.apple.com/lookup?upc=720642462928&entity=song";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data["results"] ?? [];

      setState(() {
        songs = results.where((r) => r["wrapperType"] == "track").toList();
        isLoading = false;
      });
    }
  }

  // 📰 Fetch top 3 news
  Future<void> fetchNews() async {
    final apiKey = dotenv.env['NEWS_API_KEY'] ?? "";
    final url =
        "https://newsapi.org/v2/top-headlines?country=us&pageSize=3&apiKey=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          newsArticles = data["articles"] ?? [];
          isNewsLoading = false;
        });
      } else {
        setState(() => isNewsLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching news: $e");
      setState(() => isNewsLoading = false);
    }
  }

  // 💡 Fetch 3 advices
  Future<void> fetchAdvices() async {
    List<String> results = [];
    try {
      for (int i = 0; i < 3; i++) {
        final res = await http.get(
          Uri.parse("https://api.adviceslip.com/advice"),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          results.add(data["slip"]["advice"]);
        } else {
          results.add("Stay positive and keep going!"); // fallback
        }
      }
      setState(() {
        advices = results;
        isAdviceLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching advices: $e");
      setState(() {
        advices = List.filled(3, "Take it easy!"); // safe fallback
        isAdviceLoading = false;
      });
    }
  }

  // 🌐 Fetch 3 HackerNews topics
  Future<void> fetchTopics() async {
    List<Map<String, dynamic>> results = [];
    var rng = Random();
    try {
      for (int i = 0; i < 3; i++) {
        bool gotOne = false;
        int attempts = 0;
        while (!gotOne && attempts < 5) {
          // retry up to 5 times
          final id = 1000 + rng.nextInt(9000);
          final url =
              "https://hacker-news.firebaseio.com/v0/item/$id.json?print=pretty";
          final res = await http.get(Uri.parse(url));
          attempts++;
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data != null && data["text"] != null) {
              results.add({"title": "Discussion #$id", "text": data["text"]});
              gotOne = true;
            }
          }
        }
        if (!gotOne) {
          results.add({
            "title": "Discussion",
            "text": "No interesting topic found right now.",
          });
        }
      }
      setState(() {
        topics = results;
        isTopicsLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching topics: $e");
      setState(() {
        topics = List.generate(
          3,
          (i) => {
            "title": "Discussion",
            "text": "Something went wrong. Try again later.",
          },
        );
        isTopicsLoading = false;
      });
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
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          "It's great to see you",
          style: GoogleFonts.mulish(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),

        // 🎵 Songs
        isLoading || songs.isEmpty
            ? _songShimmer()
            : GestureDetector(
                onTap: () {
                  final song = songs[currentIndex];
                  _showSongPlayer(context, song);
                  setState(() {
                    currentIndex = (currentIndex + 1) % songs.length;
                  });
                },
                child: _songCard(songs[currentIndex]),
              ),

        const SizedBox(height: 24),

        // 🔹 Stories
        _sectionWithMagazineGrid(
          "Stories to explore",
          isNewsLoading
              ? List.generate(3, (_) => _shimmerNewsCard())
              : List.generate(3, (i) {
                  if (i < newsArticles.length) {
                    final article = newsArticles[i];
                    return _imageCard(
                      imageUrl:
                          article["urlToImage"] ??
                          "https://picsum.photos/400?fallback=$i",
                      title: article["title"] ?? "No title",
                      subtitle: article["description"] ?? "",
                      onTap: widget.onCardTap,
                    );
                  }
                  // pad with shimmer if missing
                  return _shimmerNewsCard();
                }),
        ),
        const SizedBox(height: 24),

        // 💡 Advices
        _sectionWithMagazineGrid(
          "Ideas to explore",
          isAdviceLoading
              ? List.generate(3, (_) => _shimmerNewsCard())
              : List.generate(3, (i) {
                  if (i < advices.length) {
                    return _imageCard(
                      imageUrl: "https://picsum.photos/400/400?advice$i",
                      title: "Advice",
                      subtitle: advices[i],
                      onTap: widget.onCardTap,
                    );
                  }
                  // pad with shimmer if missing
                  return _shimmerNewsCard();
                }),
        ),
        const SizedBox(height: 24),

        // 🌐 Topics
        _sectionWithMagazineGrid(
          "Topics I thought you'd enjoy",
          isTopicsLoading
              ? List.generate(3, (_) => _shimmerNewsCard())
              : List.generate(3, (i) {
                  if (i < topics.length) {
                    return _imageCard(
                      imageUrl: "https://picsum.photos/400/400?topic$i",
                      title: topics[i]["title"],
                      subtitle: topics[i]["text"],
                      onTap: widget.onCardTap,
                    );
                  }
                  // pad with shimmer if missing
                  return _shimmerNewsCard();
                }),
        ),
      ],
    );
  }

  // --- Helpers ---

  static Widget _songShimmer() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  );

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

  static Widget _shimmerNewsCard() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
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
              ? const CircularProgressIndicator()
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

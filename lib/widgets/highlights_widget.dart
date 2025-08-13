import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

class HighlightsWidget extends StatelessWidget {
  final Function(String) onCardTap; // Callback to start search

  const HighlightsWidget({Key? key, required this.onCardTap}) : super(key: key);

  void _showPodcastPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const PodcastPlayerModal(
          audioUrl: "https://www.listennotes.com/e/p/a5ae21acf75a43538b635cf6b089f0b3/",
          title: "Podcast Daily",
          subtitle:
              "Aug 13 • 3 min  Unions push AI safeguards, US-China tariff truce, Food influencers clash, and more",
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _greeting(),
        const SizedBox(height: 16),
        _podcastSection(context),
        const SizedBox(height: 24),

        _sectionWithMagazineGrid(
          "Stories to explore",
          [
            _imageCard(
              imageUrl: "https://picsum.photos/400/400?1",
              title: "\$5M grandparent scam targeting seniors dismantled",
              subtitle:
                  "How the scam operated, lavish lifestyles, AI’s role, and more",
              onTap: onCardTap,
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?2",
              title: "Alaska braces for record-breaking glacial flood threat",
              subtitle: "Communities preparing for glacial surge",
              onTap: onCardTap,
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?3",
              title: "Adidas faces backlash over Oaxaca-inspired sandal",
              subtitle: "Cultural debate over new shoe design",
              onTap: onCardTap,
            ),
          ],
        ),
        const SizedBox(height: 24),

        _sectionWithMagazineGrid(
          "Ideas to explore",
          [
            _imageCard(
              imageUrl: "https://picsum.photos/400/400?4",
              title: "Build connections and thrive in a new city",
              subtitle: "Tips to settle and connect faster",
              onTap: onCardTap,
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?5",
              title: "Embrace chaos gardening for surprise blooms",
              subtitle: "Let nature surprise you",
              onTap: onCardTap,
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?6",
              title: "Discover morning routines for better productivity",
              subtitle: "Start your day right",
              onTap: onCardTap,
            ),
          ],
        ),
        const SizedBox(height: 24),

        _sectionWithMagazineGrid(
          "Topics I thought you'd enjoy",
          [
            _imageCard(
              imageUrl: "https://picsum.photos/400/400?7",
              title: "Find your zen with simple breathwork tips",
              subtitle: "Easy mindfulness breathing",
              onTap: onCardTap,
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?8",
              title: "Navigate airport madness with ease",
              subtitle: "Travel like a pro",
              onTap: onCardTap,
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?9",
              title: "Learn to cook one new dish a week",
              subtitle: "Expand your culinary skills",
              onTap: onCardTap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _greeting() {
    return Text(
      "It's great to see you",
      style: GoogleFonts.mulish(
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _podcastSection(BuildContext context) {
    return Column(
      children: [
        _podcastCard(context),
      ],
    );
  }

  Widget _podcastCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Podcast Daily",
              style: GoogleFonts.mulish(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(
              "Aug 13 • 3 min  Unions push AI safeguards, US-China tariff truce, Food influencers clash, and more",
              style: GoogleFonts.mulish(
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  fontSize: 14)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showPodcastPlayer(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text("Play now"),
          ),
        ],
      ),
    );
  }

  Widget _sectionWithMagazineGrid(String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 240,
                child: cards[0],
              ),
            ),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.mulish(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.mulish(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.more_vert,
                          color: Colors.white, size: 18),
                    ],
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

  const PodcastPlayerModal({
    Key? key,
    required this.audioUrl,
    required this.title,
    required this.subtitle,
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
            backgroundImage: NetworkImage(
              "https://picsum.photos/200",
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.title,
              style: GoogleFonts.mulish(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(widget.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.mulish(
                  fontSize: 14, color: Colors.grey[600])),
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

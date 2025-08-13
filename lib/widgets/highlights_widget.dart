import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HighlightsWidget extends StatelessWidget {
  const HighlightsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _greeting(),
        const SizedBox(height: 16),
        _podcastSection(),
        const SizedBox(height: 24),

        // Stories to explore
        _sectionWithMagazineGrid(
          "Stories to explore",
          [
            _imageCard(
              imageUrl: "https://picsum.photos/400/400?1",
              title: "\$5M grandparent scam targeting seniors dismantled",
              subtitle:
                  "How the scam operated, lavish lifestyles, AI’s role, and more",
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?2",
              title: "Alaska braces for record-breaking glacial flood threat",
              subtitle: "Communities preparing for glacial surge",
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?3",
              title: "Adidas faces backlash over Oaxaca-inspired sandal",
              subtitle: "Cultural debate over new shoe design",
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Ideas to explore
        _sectionWithMagazineGrid(
          "Ideas to explore",
          [
            _imageCard(
              imageUrl: "https://picsum.photos/400/400?4",
              title: "Build connections and thrive in a new city",
              subtitle: "Tips to settle and connect faster",
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?5",
              title: "Embrace chaos gardening for surprise blooms",
              subtitle: "Let nature surprise you",
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?6",
              title: "Discover morning routines for better productivity",
              subtitle: "Start your day right",
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Topics you might enjoy
        _sectionWithMagazineGrid(
          "Topics I thought you'd enjoy",
          [
            _imageCard(
              imageUrl: "https://picsum.photos/400/400?7",
              title: "Find your zen with simple breathwork tips",
              subtitle: "Easy mindfulness breathing",
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?8",
              title: "Navigate airport madness with ease",
              subtitle: "Travel like a pro",
            ),
            _imageCard(
              imageUrl: "https://picsum.photos/400/200?9",
              title: "Learn to cook one new dish a week",
              subtitle: "Expand your culinary skills",
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

  Widget _podcastSection() {
    return Column(
      children: [
        _podcastCard(),
      ],
    );
  }

  Widget _podcastCard() {
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
            onPressed: () {},
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
  }) {
    return ClipRRect(
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
    );
  }
}

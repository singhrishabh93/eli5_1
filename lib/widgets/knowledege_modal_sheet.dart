import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import '../services/gemini_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class KnowledgeModalSheet extends StatefulWidget {
  final String type; // fact, trivia, activity, quote, history
  final Map<String, String> data;

  const KnowledgeModalSheet({
    required this.type,
    required this.data,
    super.key,
  });

  @override
  State<KnowledgeModalSheet> createState() => _KnowledgeModalSheetState();
}

class _KnowledgeModalSheetState extends State<KnowledgeModalSheet> {
  final _selectedSegment = ValueNotifier<String>('five');
  final _geminiService = GeminiService(dotenv.env['GEMINI_API_KEY'] ?? "");

  final List<String> _explanations = ["", "", ""];
  bool _isFetchingExplanations = false;
  bool _hasExplanation = false;

  Future<void> _loadExplanations(String content) async {
    setState(() => _isFetchingExplanations = true);
    try {
      final results = await _geminiService.fetchExplanations(content);
      setState(() {
        _explanations[0] = results[0];
        _explanations[1] = results[1];
        _explanations[2] = results[2];
        _hasExplanation = true;
      });
    } catch (e) {
      setState(() {
        _explanations[0] = "Error: $e";
      });
    } finally {
      setState(() => _isFetchingExplanations = false);
    }
  }

  String _getDisplayText() {
    switch (widget.type) {
      case "fact":
        return widget.data["fact"] ?? "";
      case "trivia":
        return "${widget.data["question"]}\n\nAnswer: ${widget.data["answer"]}";
      case "activity":
        return widget.data["activity"] ?? "";
      case "quote":
        return widget.data["fact"] ?? "";
      case "history":
        return "${widget.data["headline"]}\n\n${widget.data["text"]}";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    String content = _getDisplayText();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle + Close button
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: GoogleFonts.mulish(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Explain Button
                    Center(
                      child: GestureDetector(
                        onTap: () => _loadExplanations(content),
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
                              Text(
                                "Explain like I'm 5",
                                style: GoogleFonts.mulish(
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
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFA775),
                        ),
                      ),

                    if (_hasExplanation)
                      Column(
                        children: [
                          Container(
                            height: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
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
                              activeStyle: GoogleFonts.mulish(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              inactiveStyle: GoogleFonts.mulish(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              itemPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<String>(
                            valueListenable: _selectedSegment,
                            builder: (context, value, _) {
                              int index = value == 'five'
                                  ? 0
                                  : value == 'fifteen'
                                  ? 1
                                  : 2;
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  _explanations[index],
                                  style: GoogleFonts.mulish(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.5,
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

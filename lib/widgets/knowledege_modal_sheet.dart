import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
  bool isOffline = false;

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
                      });
                      _loadExplanations(_getDisplayText());
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

  Future<void> _loadExplanations(String content) async {
    // Check internet connection before proceeding
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      setState(() {
        isOffline = true;
      });
      _showOfflineDialog();
      return;
    }

    setState(() {
      _isFetchingExplanations = true;
      isOffline = false;
    });

    try {
      final results = await _geminiService.fetchExplanations(content);
      setState(() {
        _explanations[0] = results[0];
        _explanations[1] = results[1];
        _explanations[2] = results[2];
        _hasExplanation = true;
      });
    } catch (e) {
      // Check if the error is due to network issues
      bool isStillConnected = await _checkInternetConnection();
      if (!isStillConnected) {
        setState(() {
          isOffline = true;
        });
        _showOfflineDialog();
      } else {
        setState(() {
          _explanations[0] = "Error: $e";
          _explanations[1] = "Error: $e";
          _explanations[2] = "Error: $e";
          _hasExplanation = true;
        });
      }
    } finally {
      setState(() {
        _isFetchingExplanations = false;
      });
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
                        onTap: () async {
                          bool isConnected = await _checkInternetConnection();
                          if (!isConnected) {
                            _showOfflineDialog();
                            return;
                          }
                          _loadExplanations(content);
                        },
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
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Lottie.asset(
                            "assets/searching.json",
                            width: 150,
                            height: 150,
                          ),
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
                                'five': "Like I'm 5",
                                'fifteen': "Like I'm 15",
                                'adult': "Like I'm an Adult",
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
                          ValueListenableBuilder<String>(
                            valueListenable: _selectedSegment,
                            builder: (context, value, _) {
                              int index = value == 'five'
                                  ? 0
                                  : value == 'fifteen'
                                  ? 1
                                  : 2;

                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1.2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    _explanations[index].isEmpty
                                        ? "No explanation yet."
                                        : _explanations[index],
                                    style: GoogleFonts.mulish(
                                      fontSize: 16,
                                      height: 1.4,
                                      color: Colors.white,
                                    ),
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
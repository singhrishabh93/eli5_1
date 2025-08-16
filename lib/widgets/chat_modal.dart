import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import '../services/openai_service.dart';

class ChatModal extends StatefulWidget {
  final GeminiService geminiService;
  final String? initialMessage;

  const ChatModal({
    Key? key,
    required this.geminiService,
    this.initialMessage,
  }) : super(key: key);

  @override
  State<ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends State<ChatModal> {
  final TextEditingController _chatController = TextEditingController();

  final List<String> _explanations = ["", "", ""];
  final List<bool> _isLoading = [false, false, false];

  final _selectedSegment = ValueNotifier<String>('five');

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _loadThreeLevelExplanation(widget.initialMessage!);
    }
  }

  Future<void> _loadThreeLevelExplanation(String query) async {
    for (int i = 0; i < 3; i++) {
      setState(() => _isLoading[i] = true);
    }

    try {
      final results = await widget.geminiService.fetchExplanations(query);

      setState(() {
        _explanations[0] = results[0];
        _explanations[1] = results[1];
        _explanations[2] = results[2];
      });
    } catch (e) {
      setState(() {
        _explanations[0] = "Error: $e";
      });
    } finally {
      setState(() {
        for (int i = 0; i < 3; i++) {
          _isLoading[i] = false;
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;
    _chatController.clear();
    await _loadThreeLevelExplanation(query);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // ✅ SAME AdvancedSegment as HomeScreen
              Container(
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  activeStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.w600,
                  ),
                  inactiveStyle: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.w500,
                  ),
                  itemPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Content
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: _selectedSegment,
                  builder: (context, value, _) {
                    int index = value == 'five'
                        ? 0
                        : value == 'fifteen'
                            ? 1
                            : 2;

                    if (_isLoading[index] && _explanations[index].isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFA775),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildExplanationText(_explanations[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Copied from HomeScreen
  Widget _buildExplanationText(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: text.isEmpty ? "No explanation yet." : text,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.4,
                ),
                strong: GoogleFonts.mulish(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(
                FluentIcons.copy_16_regular,
                size: 18,
                color: Color(0xFFFFA775),
              ),
              onPressed: () {
                if (text.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                FluentIcons.history_16_filled,
                size: 18,
                color: Color(0xFFFFA775),
              ),
              onPressed: () {
                _loadThreeLevelExplanation(text);
              },
            ),
            IconButton(
              icon: const Icon(
                FluentIcons.share_ios_20_filled,
                size: 18,
                color: Color(0xFFFFA775),
              ),
              onPressed: () {
                // share action
              },
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_service.dart';

class HistoryChatModal extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final String chatId;
  final GeminiService geminiService;

  const HistoryChatModal({
    Key? key,
    required this.messages,
    required this.chatId,
    required this.geminiService,
  }) : super(key: key);

  @override
  State<HistoryChatModal> createState() => _HistoryChatModalState();
}

class _HistoryChatModalState extends State<HistoryChatModal> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final ValueNotifier<String> _selectedSegment = ValueNotifier('five');

  bool _isLoading = false;
  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.messages);
  }

  Future<void> _appendMessage(Map<String, dynamic> message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("chats")
        .doc(widget.chatId)
        .update({
      "messages": FieldValue.arrayUnion([message]),
    });
  }

  Future<void> _sendMessage() async {
    final query = _textController.text.trim();
    if (query.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _messages.add({"role": "user", "message": query});
      _textController.clear();
    });
    await _appendMessage({"role": "user", "message": query});
    _scrollToBottom();

    try {
      final results = await widget.geminiService.fetchExplanations(query);

      setState(() {
        _messages.add({
          "role": "assistant",
          "message_five": results[0],
          "message_fifteen": results[1],
          "message_adult": results[2],
        });
      });

      await _appendMessage({
        "role": "assistant",
        "message_five": results[0],
        "message_fifteen": results[1],
        "message_adult": results[2],
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "message_five": "Error: $e",
          "message_fifteen": "",
          "message_adult": "",
        });
      });

      await _appendMessage({
        "role": "assistant",
        "message_five": "Error: $e",
        "message_fifteen": "",
        "message_adult": "",
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Column(
          children: [
            const SizedBox(height: 12),

            /// 🔹 Tab switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSegmentButton("five", "Like I’m 5"),
                    _buildSegmentButton("fifteen", "Like I’m 15"),
                    _buildSegmentButton("adult", "Like I’m an Adult"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            /// 🔹 Messages list
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _selectedSegment,
                builder: (context, selected, _) {
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg["role"] == "user";

                      String text = "";
                      if (isUser) {
                        text = msg["message"] ?? "";
                      } else {
                        if (selected == "five") {
                          text = msg["message_five"] ?? "";
                        } else if (selected == "fifteen") {
                          text = msg["message_fifteen"] ?? "";
                        } else {
                          text = msg["message_adult"] ?? "";
                        }
                      }

                      if (text.isEmpty) return const SizedBox.shrink();

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFFFFA775)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: MarkdownBody(
                            data: text,
                            styleSheet: MarkdownStyleSheet(
                              p: GoogleFonts.mulish(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              strong: GoogleFonts.mulish(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            /// 🔹 Input field
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        enabled: !_isLoading,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: const Color(0xFFF0CF7B),
                        decoration: InputDecoration(
                          hintText: "Type your message...",
                          hintStyle:
                              GoogleFonts.mulish(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        FluentIcons.send_20_filled,
                        color: _isLoading
                            ? Colors.grey
                            : const Color(0xFFF0CF7B),
                      ),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSegmentButton(String key, String label) {
    return ValueListenableBuilder<String>(
      valueListenable: _selectedSegment,
      builder: (_, selected, __) {
        final isActive = selected == key;
        return GestureDetector(
          onTap: () => _selectedSegment.value = key,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.yellowAccent.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: GoogleFonts.mulish(
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

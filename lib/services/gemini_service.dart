import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  final List<Content> _chatHistory = []; // Stores full chat context

  GeminiService(this.apiKey);

  /// Normal Chat with Context
  Future<String> sendMessage(String userMessage) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash', // or 'gemini-1.5-pro' for better quality
      apiKey: apiKey,
    );

    // Add user message to chat history
    _chatHistory.add(Content.text(userMessage));

    final response = await model.generateContent(_chatHistory);

    final reply = response.text ?? "I couldn't generate a response.";
    
    // Add AI reply to chat history
    _chatHistory.add(Content.text(reply));

    return reply;
  }

  /// Clear chat history when starting a new chat
  void resetChat() {
    _chatHistory.clear();
  }
  void addAIMessage(String message) {
  _chatHistory.add(Content.text(message));
}

  /// Your old explanation method stays the same
  Future<List<String>> fetchExplanations(String query) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    final prompt = """
Explain "$query" in three levels:
1. Like I’m 5
2. Like I’m 15
3. Like I’m an adult
Format your response as:
[5] explanation here
[15] explanation here
[adult] explanation here
""";

    final response = await model.generateContent([Content.text(prompt)]);

    final text = response.text ?? "";
    final like5 = RegExp(r"\[5\](.*?)(?=\[15\]|\$)", dotAll: true)
        .firstMatch(text)?.group(1)?.trim() ?? "";
    final like15 = RegExp(r"\[15\](.*?)(?=\[adult\]|\$)", dotAll: true)
        .firstMatch(text)?.group(1)?.trim() ?? "";
    final likeAdult = RegExp(r"\[adult\](.*)", dotAll: true)
        .firstMatch(text)?.group(1)?.trim() ?? "";

    return [like5, like15, likeAdult];
  }
}

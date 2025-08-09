import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;

  GeminiService(this.apiKey);

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
    // Parse into list based on markers
    final like5 = RegExp(r"\[5\](.*?)(?=\[15\]|\$)", dotAll: true)
        .firstMatch(text)?.group(1)?.trim() ?? "";
    final like15 = RegExp(r"\[15\](.*?)(?=\[adult\]|\$)", dotAll: true)
        .firstMatch(text)?.group(1)?.trim() ?? "";
    final likeAdult = RegExp(r"\[adult\](.*)", dotAll: true)
        .firstMatch(text)?.group(1)?.trim() ?? "";

    return [like5, like15, likeAdult];
  }
}

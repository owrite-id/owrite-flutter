import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  // Valid Google Gemini API model REST endpoints
  static const List<String> _models = [
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent",
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent",
  ];

  static const String _fallbackKey = 'AIzaSyDa3Fo_obfSV_DTUo8OmaSUiR7U7KllYEs';
  
  // API Key Config with mobile release fallback
  static String get _apiKey {
    const compileTimeKey = String.fromEnvironment('GEMINI_API_KEY');
    if (compileTimeKey.isNotEmpty) {
      return compileTimeKey;
    }
    final dotenvKey = dotenv.env['GEMINI_API_KEY'];
    if (dotenvKey != null && dotenvKey.isNotEmpty) {
      return dotenvKey;
    }
    return _fallbackKey;
  }

  static Future<String> summarizeText(String text) async {
    final key = _apiKey;
    if (key.isEmpty) {
      return _generateLocalFallback(text);
    }

    final prompt = '''Ringkas teks berita berikut dalam bahasa Indonesia dengan format yang jelas dan terstruktur. 

PENTING:
- Fokus pada poin-poin penting dan fakta utama
- Gunakan bullet points (•) untuk setiap poin penting
- Jika ada informasi tentang siapa, apa, kapan, di mana, mengapa, dan bagaimana, sertakan dalam ringkasan
- Pertahankan header atau subjudul jika ada dalam teks asli
- Ringkas menjadi 3-5 poin utama yang paling relevan
- Gunakan bahasa yang jelas dan mudah dipahami
- Jangan tambahkan informasi yang tidak ada di teks asli
- Jangan sertakan frasa seperti "berikut berita", "berikut isi", "deskripsi", "ringkasan ini", "dan lain yang seperti itu" di dalam ringkasan

Format output:
• Poin penting pertama
• Poin penting kedua
• Poin penting ketiga
(dan seterusnya)

Teks yang akan diringkas:
$text''';

    // Try Gemini models sequentially until one succeeds
    for (final modelUrl in _models) {
      try {
        final uri = Uri.parse("$modelUrl?key=$key");
        final response = await http.post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt}
                ]
              }
            ],
            "generationConfig": {
              "temperature": 0.3,
              "topK": 40,
              "topP": 0.95,
              "maxOutputTokens": 1500,
            },
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["candidates"] != null &&
              data["candidates"].isNotEmpty &&
              data["candidates"][0]["content"] != null &&
              data["candidates"][0]["content"]["parts"] != null &&
              data["candidates"][0]["content"]["parts"].isNotEmpty) {
            final summary = data["candidates"][0]["content"]["parts"][0]["text"];
            if (summary != null && summary.toString().trim().isNotEmpty) {
              return summary.toString().trim();
            }
          }
        } else if (response.statusCode == 429) {
          debugPrint("Gemini model $modelUrl hit 429 Rate Limit. Delaying & trying next model...");
          await Future.delayed(const Duration(milliseconds: 1000));
          continue;
        } else {
          debugPrint("Gemini model $modelUrl failed (${response.statusCode}): ${response.body}");
        }
      } catch (e) {
        debugPrint("Gemini model $modelUrl exception: $e");
      }
    }

    // Fallback if all Gemini API endpoints fail or rate-limit
    return _generateLocalFallback(text);
  }

  static String _generateLocalFallback(String text) {
    final clean = text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (clean.isEmpty) return 'Ringkasan tidak tersedia.';

    final sentences = clean.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.trim().length > 15).toList();
    if (sentences.isEmpty) {
      return '• $clean';
    }

    final takeCount = sentences.length > 5 ? 4 : sentences.length;
    return sentences.take(takeCount).map((s) => '• ${s.trim()}').join('\n');
  }
}

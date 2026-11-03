import 'dart:convert';
import '../config/app_config.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service untuk menangani komunikasi dengan Backend Engine Open Voice Neural TTS (Orpheus-TTS)
class OpenVoiceService {
  /// Primary Backend API URLs to try
  static List<String> get apiEndpoints => AppConfig.openVoiceApiUrls;

  /// Mapping Akronim & Singkatan Bahasa Indonesia (Orpheus-TTS Normalizer)
  static const Map<String, String> acronymMap = {
    'DPR': 'D P R',
    'MPR': 'M P R',
    'DPD': 'D P D',
    'DPRD': 'D P R D',
    'TNI': 'T N I',
    'Polri': 'Polri',
    'POLRI': 'Polri',
    'PNS': 'P N S',
    'ASN': 'A S N',
    'IKN': 'I K N',
    'KPU': 'K P K',
    'KPK': 'K P K',
    'BMKG': 'B M K G',
    'BBM': 'B B M',
    'WIB': 'W I B',
    'WITA': 'W I T A',
    'WIT': 'W I T',
    'LRT': 'L R T',
    'MRT': 'M R T',
    'BUMN': 'B U M N',
    'BUMD': 'B U M D',
    'HAM': 'H A M',
    'PBB': 'P B B',
    'WHO': 'W H O',
    'UNESCO': 'Unesco',
    'USA': 'U S A',
    'US': 'U S',
    'UK': 'U K',
    'EU': 'E U',
    'IDR': 'I D R',
    'USD': 'U S D',
    'dlsb.': 'dan lain sebagainya',
    'dlsb': 'dan lain sebagainya',
    'dll.': 'dan lain-lain',
    'dll': 'dan lain-lain',
    'dkk.': 'dan kawan-kawan',
    'dkk': 'dan kawan-kawan',
    's.d.': 'sampai dengan',
    's/d': 'sampai dengan',
    'No.': 'Nomor ',
    'no.': 'nomor ',
    'Jl.': 'Jalan ',
    'jl.': 'jalan ',
    'Hal.': 'Halaman ',
    'PT.': 'P T ',
    'CV.': 'C V ',
  };

  /// Normalisasi Teks untuk Orpheus Neural TTS (Mengubah akronim, mata uang, & tanda baca)
  static String prepareText(String title, String text) {
    if (text.isEmpty) return title;

    // 1. Clean HTML tags
    String cleanText = text
        .replaceAll(RegExp(r'<[^>]*>?'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 2. Format Currency & Percentages
    cleanText = cleanText
        .replaceAllMapped(RegExp(r'Rp\.?\s*([\d\.\,]+)\s*(juta|miliar|triliun)?', caseSensitive: false), (match) {
          final amount = match.group(1) ?? '';
          final scale = match.group(2) ?? '';
          final suffix = scale.isNotEmpty ? ' $scale' : '';
          return '$amount$suffix rupiah';
        })
        .replaceAllMapped(RegExp(r'(\d+)\s*%'), (match) => '${match.group(1)} persen')
        .replaceAllMapped(RegExp(r'\+(\d+)'), (match) => 'plus ${match.group(1)}');

    // 3. Normalize Acronyms
    acronymMap.forEach((shortKey, expandedVal) {
      final pattern = '\\b${RegExp.escape(shortKey)}\\b';
      cleanText = cleanText.replaceAll(RegExp(pattern), expandedVal);
    });

    // 4. Format Quotes and Pauses for natural intonation
    cleanText = cleanText
        .replaceAllMapped(RegExp(r'["“]([^"”]+)["”]'), (m) => ', ${m.group(1)?.trim()}, ')
        .replaceAll(RegExp(r'\s*--+\s*'), ', ')
        .replaceAll(RegExp(r'\s*\.\.\.+\s*'), '... ');

    final cleanTitle = title.replaceAll(RegExp(r'<[^>]*>?'), ' ').trim();
    return "Judul: $cleanTitle. Isi artikel: $cleanText";
  }

  /// Fetch audio MP3 as Uint8List (Byte Array) directly from Open Voice Backend Engine.
  /// Works across all platforms including Web (Chrome) and Native (Android/iOS).
  static Future<Uint8List?> fetchAudioBytes({
    required String title,
    required String content,
    String? author,
    String? category,
    String voice = 'male',
  }) async {
    final processedText = prepareText(title, content);

    for (final endpoint in apiEndpoints) {
      try {
        debugPrint('🎙️ Requesting OpenVoice Neural TTS from $endpoint...');
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'audio/mpeg',
          },
          body: jsonEncode({
            'title': title,
            'author': author ?? 'Redaksi Owrite',
            'text': processedText,
            'category': category ?? '',
            'voice': voice,
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          debugPrint('✅ OpenVoice Neural TTS success: ${response.bodyBytes.length} bytes from $endpoint');
          return response.bodyBytes;
        } else {
          debugPrint('⚠️ HTTP ${response.statusCode} from $endpoint');
        }
      } catch (e) {
        debugPrint('⚠️ OpenVoice fetch failed for $endpoint: $e');
      }
    }
    return null;
  }

  /// Fetch audio file for native disk storage
  static Future<File?> fetchAudio({
    required String title,
    required String content,
    String? author,
    String? category,
    String voice = 'male',
  }) async {
    if (kIsWeb) return null; // Web browser uses byte streams

    try {
      final bytes = await fetchAudioBytes(
        title: title,
        content: content,
        author: author,
        category: category,
        voice: voice,
      );
      if (bytes != null && bytes.isNotEmpty) {
        final dir = await getTemporaryDirectory();
        final fileName = 'openvoice_${title.hashCode}.mp3';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        return file;
      }
    } catch (e) {
      debugPrint('❌ OpenVoice fetchAudio file error: $e');
    }
    return null;
  }
}

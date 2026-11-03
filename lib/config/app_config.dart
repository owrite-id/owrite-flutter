import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place for environment-specific configuration.
///
/// Each value is read from a `--dart-define` compile-time value first, then
/// from `.env` (loaded in `main()`), then falls back to a default (if any).
/// See `.env.example` for the full list of keys.
class AppConfig {
  AppConfig._();

  static String _env(String compileValue, String key, [String fallback = '']) {
    if (compileValue.isNotEmpty) return compileValue;
    final value = dotenv.isInitialized ? dotenv.env[key] : null;
    return (value != null && value.isNotEmpty) ? value : fallback;
  }

  static String _trimSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  // ── URLs ────────────────────────────────────────────────────────────────

  /// Public website, e.g. https://www.owrite.id (no trailing slash).
  static String get siteUrl => _trimSlash(_env(
      const String.fromEnvironment('SITE_URL'),
      'SITE_URL',
      'https://www.owrite.id'));

  /// WordPress REST API base, e.g. https://cms.owrite.id/wp-json/wp/v2.
  static String get apiBaseUrl => _trimSlash(_env(
      const String.fromEnvironment('API_BASE_URL'),
      'API_BASE_URL',
      'https://cms.owrite.id/wp-json/wp/v2'));

  /// WordPress REST API on the public site (used for login / current user).
  static String get siteApiUrl => '$siteUrl/wp-json/wp/v2';

  /// JWT auth token endpoint.
  static String get jwtTokenUrl => '$siteUrl/wp-json/jwt-auth/v1/token';

  /// Login page (WebView login).
  static String get loginPageUrl => '$siteUrl/writehere/';

  /// Open Voice TTS backends, tried in order. Comma-separated in the env.
  static List<String> get openVoiceApiUrls => _env(
          const String.fromEnvironment('OPEN_VOICE_API_URLS'),
          'OPEN_VOICE_API_URLS',
          'https://sinpo.id/api/tts,https://www.sinpo.id/api/tts')
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  // ── API keys ────────────────────────────────────────────────────────────

  static String get googleTtsApiKey => _env(
      const String.fromEnvironment('GOOGLE_TTS_API_KEY'), 'GOOGLE_TTS_API_KEY');

  static String get geminiApiKey => _env(
      const String.fromEnvironment('GEMINI_API_KEY'), 'GEMINI_API_KEY');

  static String get youtubeApiKey => _env(
      const String.fromEnvironment('YOUTUBE_API_KEY'), 'YOUTUBE_API_KEY');

  // ── EmailJS / feedback ──────────────────────────────────────────────────

  static String get emailJsUrl => _env(
      const String.fromEnvironment('EMAILJS_URL'),
      'EMAILJS_URL',
      'https://api.emailjs.com/api/v1.0/email/send');

  static String get emailJsServiceId => _env(
      const String.fromEnvironment('EMAILJS_SERVICE_ID'), 'EMAILJS_SERVICE_ID');

  static String get emailJsTemplateId => _env(
      const String.fromEnvironment('EMAILJS_TEMPLATE_ID'),
      'EMAILJS_TEMPLATE_ID');

  static String get emailJsPublicKey => _env(
      const String.fromEnvironment('EMAILJS_PUBLIC_KEY'), 'EMAILJS_PUBLIC_KEY');

  static String get feedbackTargetEmail => _env(
      const String.fromEnvironment('FEEDBACK_TARGET_EMAIL'),
      'FEEDBACK_TARGET_EMAIL');
}

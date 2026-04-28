import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  // --- Single source for default values (used when .env is missing or empty) ---
  // Real / staging values belong in .env only (not committed; see .env.example).
  static const String _defaultApiBaseUrl = 'https://inkbattle.in/api';
  static const String _defaultSocketUrl = 'https://inkbattle.in';
  static const String _defaultAgoraAppId = '85ed3bccf4dc4f62b3e30b834a0b5670';
  static const String _defaultGoogleWebClientId =
      '810403540241-ip9gtcb25f8m6f3du23riuqj5h5dbr9l.apps.googleusercontent.com';

  /// Defaults merged when loading .env so the app never hits NotInitializedError.
  /// Used by main.dart in dotenv.load(mergeWith: ...).
  static Map<String, String> get envDefaults => {
        'API_BASE_URL': _defaultApiBaseUrl,
        'SOCKET_URL': _defaultSocketUrl,
        'AGORA_APP_ID': _defaultAgoraAppId,
        'GOOGLE_WEB_CLIENT_ID': _defaultGoogleWebClientId,
      };

  // API and Socket URLs: read from .env with production fallbacks.
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? _defaultApiBaseUrl;
  static String get socketUrl => dotenv.env['SOCKET_URL'] ?? _defaultSocketUrl;

  static const String appSecret = "InkBattle_Secure_2024"; // match Nginx exactly
  static const int dailyCoinsAwarded = 1000;

  static String get agoraAppId =>
      dotenv.env['AGORA_APP_ID'] ?? _defaultAgoraAppId;

  // Web client ID (OAuth 2.0) from Firebase/Google Cloud. Required for Google Sign-In idToken on Android.
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim().isNotEmpty == true
          ? dotenv.env['GOOGLE_WEB_CLIENT_ID']!.trim()
          : _defaultGoogleWebClientId;
}

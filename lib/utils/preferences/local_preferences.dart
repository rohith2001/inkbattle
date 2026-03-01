import 'package:inkbattle_frontend/services/native_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageUtils {
  static late final SharedPreferences instance;

  static Future<SharedPreferences> init() async =>
      instance = await SharedPreferences.getInstance();

//  static JwtTokeResponseModel get tokenResponseModel => userData();

  static Future<void> saveUserDetails(String token) async {
    await instance.setString("token", token);
    NativeLogService.log("Token saved!", tag: 'LocalStorageUtils', level: 'debug');
  }

  static Future<void> saveGeoLocation(double lat, double lon) async {
    await instance.setDouble("latitude", lat);
    await instance.setDouble("longitude", lon);
    NativeLogService.log("Geo Location Saved", tag: 'LocalStorageUtils', level: 'debug');
  }

  static double? getLatitude() {
    final latitude = instance.getDouble('latitude');
    return latitude;
  }

  static Future<void> setDistance(double distance) async {
    await instance.setDouble("distance", distance);
    NativeLogService.log("Distace Saved $distance", tag: 'LocalStorageUtils', level: 'debug');
  }

  static double? getDistance() {
    final distance = instance.getDouble('distance');
    final meter = (distance ?? 40) * 1000;
    return meter;
  }

  static double? getLongitude() {
    final latitude = instance.getDouble('longitude');
    return latitude;
  }

  static Future<String?> fetchToken() async {
    try {
      final token = instance.getString('token');

      if (token == null || token.isEmpty) {
        return null;
      }
      NativeLogService.log(token, tag: 'LocalStorageUtils', level: 'debug');
      return token;
    } catch (e) {
      NativeLogService.log('Error fetching token: $e', tag: 'LocalStorageUtils', level: 'error');
      return null;
    }
  }

  // Pending guest (lazy creation: no DB row until first server action)
  static const String _keyLocalGuestId = 'local_guest_id';
  static const String _keyGuestName = 'guest_name';
  static const String _keyGuestAvatar = 'guest_avatar';
  static const String _keyGuestLanguage = 'guest_language';
  static const String _keyGuestCountry = 'guest_country';

  static Future<void> savePendingGuest({
    required String localGuestId,
    required String name,
    String? avatar,
    String? language,
    String? country,
  }) async {
    await instance.setString(_keyLocalGuestId, localGuestId);
    await instance.setString(_keyGuestName, name);
    if (avatar != null) await instance.setString(_keyGuestAvatar, avatar);
    if (language != null) await instance.setString(_keyGuestLanguage, language);
    if (country != null) await instance.setString(_keyGuestCountry, country);
  }

  static Map<String, String?>? getPendingGuest() {
    final id = instance.getString(_keyLocalGuestId);
    if (id == null || id.isEmpty) return null;
    return {
      'localGuestId': id,
      'name': instance.getString(_keyGuestName) ?? 'Guest',
      'avatar': instance.getString(_keyGuestAvatar),
      'language': instance.getString(_keyGuestLanguage),
      'country': instance.getString(_keyGuestCountry),
    };
  }

  static bool hasPendingGuest() {
    final id = instance.getString(_keyLocalGuestId);
    return id != null && id.isNotEmpty;
  }

  static Future<void> clearPendingGuest() async {
    await instance.remove(_keyLocalGuestId);
    await instance.remove(_keyGuestName);
    await instance.remove(_keyGuestAvatar);
    await instance.remove(_keyGuestLanguage);
    await instance.remove(_keyGuestCountry);
  }

  static Future<void> clear() async {
    instance.remove('token');
    await clearPendingGuest();
    await instance.clear();
  }

  static Future<bool> showTutorial() async {
    return instance.getBool('tutorialShown') ?? false;
  }

  static Future<void> setTutorialShown(bool shown) async {
    NativeLogService.log('Tutorial shown status updated to $shown', tag: 'LocalStorageUtils', level: 'debug');
    await instance.setBool('tutorialShown', shown);
  }

  static Future<double> setVolume(double vol) async {
    NativeLogService.log('Volume saved: $vol', tag: 'LocalStorageUtils', level: 'debug');
    await instance.setDouble('volume', vol);
    return vol;
  }

  static Future<double> getVolume() async {
    final vol = instance.getDouble('volume') ?? 1;
    NativeLogService.log('Volume fetched: $vol', tag: 'LocalStorageUtils', level: 'debug');
    return vol;
  }

  // Language storage
  static Future<void> saveLanguage(String languageCode) async {
    await instance.setString('app_language', languageCode);
    NativeLogService.log('Language saved: $languageCode', tag: 'LocalStorageUtils', level: 'debug');
  }

  static String getLanguage() {
    final language = instance.getString('app_language') ?? 'en';
    NativeLogService.log('Language fetched: $language', tag: 'LocalStorageUtils', level: 'debug');
    return language;
  }

  // static JwtTokeResponseModel userData() {
  //   final token = instance.getString('token') ?? '';
  //   var userData = JwtDecoder.decode(token);
  //   var userDecoded = JwtTokeResponseModel.fromJson(userData);
  //   return userDecoded;
  // }
}

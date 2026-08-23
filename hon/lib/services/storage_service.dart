import 'package:shared_preferences/shared_preferences.dart';

/// لایه‌ی نازک روی SharedPreferences برای نگه‌داشتن نشست کاربر
/// (توکن و نام کاربری) بین اجراهای مختلف اپ.
class StorageService {
  static const _kToken = 'auth_token';
  static const _kUsername = 'username';

  Future<String?> get token async =>
      (await SharedPreferences.getInstance()).getString(_kToken);

  Future<String?> get username async =>
      (await SharedPreferences.getInstance()).getString(_kUsername);

  Future<void> saveSession({required String username, required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsername, username);
    await prefs.setString(_kToken, token);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUsername);
    await prefs.remove(_kToken);
  }
}

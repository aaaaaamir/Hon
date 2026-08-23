/// تنظیمات مرکزی اپ.
/// آدرس سرور مطابق درخواست روی chat.idothis.ir تنظیم شده.
/// اگر بعداً سرور عوض شد، فقط همین دو مقدار را عوض کنید.
class AppConfig {
  AppConfig._();

  static const String host = 'chat.idothis.ir';

  static const String baseUrl = 'https://$host';
  static const String wsUrl = 'wss://$host/ws';

  /// حداقل طول رمز عبور، مطابق قوانین سرور.
  static const int minPasswordLength = 5;

  /// الگوی مجاز برای نام کاربری: فقط حروف انگلیسی، عدد و _ (۳ تا ۲۰ کاراکتر)
  static final RegExp usernamePattern = RegExp(r'^[A-Za-z0-9_]{3,20}$');
}

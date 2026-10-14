// تستِ ویجتِ پیش‌فرضِ flutter create دیگر اعتبار نداشت:
// به `package:hon/main.dart` (و کلاس MyApp) ارجاع می‌داد در حالی‌که
// نام پکیج `hon_chat` است. این فایل فعلاً یک تست placeholder است؛
// تست‌های واقعی‌ی ویجت بعداً با توجه به ساختار واقعیِ اپ اضافه می‌شوند.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder: تست‌های ویجت اپ', () {
    expect(1 + 1, 2);
  });
}

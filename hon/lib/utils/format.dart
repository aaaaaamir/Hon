const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// اعداد لاتین را به فارسی تبدیل می‌کند (برای نمایش زمان و شمارنده‌ها).
String toFa(Object value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    final d = int.tryParse(ch);
    buf.write(d != null ? _faDigits[d] : ch);
  }
  return buf.toString();
}

String formatTime(int timestampMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final now = DateTime.now();
  final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  if (sameDay) return toFa('$hh:$mm');
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday =
      dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
  if (isYesterday) return 'دیروز';
  return toFa('${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}');
}

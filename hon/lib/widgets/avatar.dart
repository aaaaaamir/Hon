import 'package:flutter/material.dart';
import '../config.dart';
import '../theme.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool online;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 46,
    this.online = false,
  });

  /// اگر آدرس تصویر نسبی باشد، دامنه‌ی سرور جلویش اضافه می‌شود.
  String? _resolvedUrl() {
    final raw = imageUrl?.trim() ?? '';
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '${AppConfig.baseUrl}${raw.startsWith('/') ? '' : '/'}$raw';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolvedUrl();
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: resolvedUrl == null ? AppColors.accentGradient : null,
              image: resolvedUrl != null
                  ? DecorationImage(image: NetworkImage(resolvedUrl), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: resolvedUrl == null
                ? Text(
                    initial,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: size * 0.4,
                    ),
                  )
                : null,
          ),
          if (online)
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'avatar.dart';

/// کارت پروفایل کاربر — مشترک بین صفحه‌ها (چت، اعضای گروه).
/// مطابق بخش «پروفایل» در وب: آواتار، نام، بیو، «مهمان — ثبت‌نام‌نشده»،
/// و دکمه‌های «ارسال پیام» و «گزارش این کاربر».
Future<void> showUserProfileSheet(
  BuildContext context,
  String username, {
  required void Function(BuildContext sheetContext) onMessage,
  bool showBlock = true,
}) async {
  final state = Provider.of<AppState>(context, listen: false);
  Map<String, dynamic>? profile;
  try {
    profile = await state.api.fetchProfile(username);
  } catch (_) {
    // آفلاین؛ با همان اطلاعات محلی نمایش داده می‌شود
  }
  if (!context.mounted) return;

  final displayName = ((profile?['displayName']?.toString() ?? '').trim().isNotEmpty
      ? profile!['displayName'].toString()
      : username);
  final bio = (profile?['bio']?.toString() ?? '').trim();
  final avatarUrl = profile?['avatarUrl']?.toString();
  final isGuest = profile?['isGuest'] == true;
  final blocked = state.isBlocked(username);

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: UserAvatar(name: displayName, imageUrl: avatarUrl, size: 84)),
            const SizedBox(height: 12),
            Center(
              child: Text(displayName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text('@$username',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
            ),
            if (isGuest) ...[
              const SizedBox(height: 6),
              const Text('👤 مهمان — ثبت‌نام‌نشده',
                  style: TextStyle(fontSize: 12, color: AppColors.orange)),
            ],
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(bio,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onMessage(ctx);
                      },
                      child: const Text('ارسال پیام'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.campaign_outlined, size: 18),
                    label: const Text('گزارش این کاربر'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      showReportUserSheet(context, username);
                    },
                  ),
                ),
              ],
            ),
            if (showBlock) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  state.toggleBlock(username);
                  Navigator.pop(ctx);
                },
                child: Text(blocked ? 'آنبلاک' : 'بلاک کردن',
                    style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// دیالوگ گزارش کاربر — مشترک
void showReportUserSheet(BuildContext context, String target) {
  final reasonCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('گزارش کاربر'),
      content: TextField(
        controller: reasonCtrl,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(hintText: 'دلیل گزارش را بنویسید'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
        TextButton(
          onPressed: () async {
            final s = Provider.of<AppState>(context, listen: false);
            await s.api.report(
              username: s.currentUsername!,
              target: target,
              reason: reasonCtrl.text.trim(),
            );
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('گزارش ارسال شد')));
            }
          },
          child: const Text('ارسال'),
        ),
      ],
    ),
  );
}

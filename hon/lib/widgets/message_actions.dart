import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';
import '../theme.dart';

/// منوی عملیات پیام (تپ / نگه‌داشتن) — مشترک بین چت مستقیم و گروه.
/// مطابق نسخه‌ی وب: روی پیام می‌زنی، گزینه‌ها پایین صفحه باز می‌شوند.
Future<void> showMessageActionsSheet(
  BuildContext context,
  ChatMessage m, {
  required bool isMine,
  required void Function() onReply,
  required Future<void> Function(String messageId) onDelete,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          if (m.text.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: AppColors.accent),
              title: const Text('کپی متن'),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: m.text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('کپی شد'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ListTile(
            leading: const Icon(Icons.reply_rounded, color: AppColors.accent),
            title: const Text('پاسخ'),
            onTap: () {
              Navigator.pop(ctx);
              onReply();
            },
          ),
          if (isMine)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
              title: const Text('حذف پیام'),
              onTap: () async {
                Navigator.pop(ctx);
                await onDelete(m.id);
              },
            ),
        ],
      ),
    ),
  );
}

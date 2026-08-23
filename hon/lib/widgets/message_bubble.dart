import 'dart:io';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme.dart';
import '../utils/format.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String? senderLabel; // برای گروه: نام فرستنده روی پیام‌های دیگران
  final String Function()? imageUrlBuilder; // آدرس شبکه‌ای عکس، وقتی آپلود کامل شده
  final VoidCallback? onReply;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.senderLabel,
    this.imageUrlBuilder,
    this.onReply,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (message.deleted) {
      return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.card2,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text('این پیام حذف شد',
              style: TextStyle(color: AppColors.muted, fontStyle: FontStyle.italic, fontSize: 13)),
        ),
      );
    }

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: isMine ? AppColors.bubbleMe : null,
        color: isMine ? null : AppColors.bubbleThem,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMine ? 16 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (senderLabel != null && !isMine)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(senderLabel!,
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          if (message.replyPreview != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: const Border(right: BorderSide(color: Colors.white54, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message.replyPreview!.from,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white70)),
                  Text(message.replyPreview!.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
          if (message.image != null) _imageContent(context),
          if (message.text.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: message.image != null ? 6 : 0),
              child: Text(message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4)),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(formatTime(message.timestamp),
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
              if (isMine) ...[
                const SizedBox(width: 4),
                Icon(
                  message.pending ? Icons.access_time_rounded : Icons.done_all_rounded,
                  size: 13,
                  color: Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        child: GestureDetector(
          onLongPress: onLongPress,
          onDoubleTap: onReply,
          child: bubble,
        ),
      ),
    );
  }

  Widget _imageContent(BuildContext context) {
    final img = message.image!;
    Widget content;

    if (img.id != null && imageUrlBuilder != null) {
      // عکس با موفقیت آپلود شده؛ از سرور نمایش داده می‌شود
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrlBuilder!(),
          width: 220,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              width: 220,
              height: 160,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
            );
          },
          errorBuilder: (ctx, err, stack) => const SizedBox(
            width: 220,
            height: 120,
            child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.white54)),
          ),
        ),
      );
    } else if (img.localPath != null) {
      // هنوز در حال آپلود یا آپلود ناموفق؛ پیش‌نمایش محلی
      content = Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: message.uploadFailed ? 0.4 : 0.75,
              child: Image.file(File(img.localPath!), width: 220, fit: BoxFit.cover),
            ),
          ),
          if (message.uploadFailed)
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 28)
          else if (message.pending)
            const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ],
      );
    } else {
      content = const SizedBox(
        width: 220,
        height: 120,
        child: Center(child: Icon(Icons.image_not_supported_rounded, color: Colors.white54)),
      );
    }

    return GestureDetector(
      onTap: img.id != null && imageUrlBuilder != null
          ? () => _openFullImage(context, imageUrlBuilder!())
          : null,
      child: content,
    );
  }

  void _openFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: InteractiveViewer(
          child: Center(child: Image.network(url)),
        ),
      ),
    );
  }
}


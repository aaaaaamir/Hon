import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'avatar.dart';

class ConversationTile extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final bool isGroup;
  final bool online;
  final int unreadCount;
  final String subtitle;
  final int? timestamp;
  final bool isPendingLast;
  final bool blocked;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationTile({
    super.key,
    required this.title,
    this.avatarUrl,
    this.isGroup = false,
    this.online = false,
    this.unreadCount = 0,
    required this.subtitle,
    this.timestamp,
    this.isPendingLast = false,
    this.blocked = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            isGroup
                ? Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.accentGradient,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                  )
                : UserAvatar(name: title, imageUrl: avatarUrl, online: online),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                        ),
                      ),
                      if (blocked) ...[
                        const SizedBox(width: 6),
                        const Text('بلاک', style: TextStyle(color: AppColors.red, fontSize: 11)),
                      ],
                      if (timestamp != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          formatTime(timestamp!),
                          style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (isPendingLast) ...[
                        const Icon(Icons.access_time_rounded, size: 13, color: AppColors.muted),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            toFa(unreadCount),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

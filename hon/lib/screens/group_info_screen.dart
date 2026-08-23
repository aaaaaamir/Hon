import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../state/app_state.dart';
import '../theme.dart';

class GroupInfoScreen extends StatelessWidget {
  final String groupId;
  const GroupInfoScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final groupList = state.groups.where((g) => g.id == groupId).toList();
    final group = groupList.isNotEmpty ? groupList.first : null;
    final inviteLink = '${AppConfig.baseUrl}/?group=$groupId';

    return Scaffold(
      appBar: AppBar(title: const Text('اطلاعات گروه')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.accentGradient),
              alignment: Alignment.center,
              child: const Icon(Icons.groups_rounded, color: Colors.white, size: 38),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(group?.name ?? 'گروه',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          if (group != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${group.memberCount} عضو، ${group.onlineCount} آنلاین',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ),
            ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.link_rounded, color: AppColors.accent),
              title: const Text('لینک دعوت'),
              subtitle: Text(inviteLink, style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteLink));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('لینک کپی شد')));
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.red),
              title: const Text('خروج از گروه', style: TextStyle(color: AppColors.red)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: const Text('خروج از گروه'),
                    content: const Text('مطمئنی می‌خوای از این گروه خارج بشی؟'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await state.api.leaveGroup(state.currentUsername!, groupId);
                  await state.refreshConversations();
                  if (context.mounted) {
                    Navigator.popUntil(context, (r) => r.isFirst);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

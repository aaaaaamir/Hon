import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../models/group.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import 'chat_screen.dart';

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
              leading: const Icon(Icons.groups_rounded, color: AppColors.accent),
              title: const Text('اعضا'),
              subtitle: group != null
                  ? Text('${group.memberCount} عضو',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted))
                  : null,
              trailing: const Icon(Icons.chevron_left_rounded, size: 20),
              onTap: () => _showMembersDialog(context, state, group),
            ),
          ),
          const SizedBox(height: 12),
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

  /// Window «Members» — shown as a dialog; tapping a member
  /// goes to a direct chat (private) with that member.
  Future<void> _showMembersDialog(
      BuildContext context, AppState state, GroupConversation? group) async {
    await state.refreshGroupMembers(groupId);
    final members = state.membersForGroup(groupId);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.card,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 480),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          '${group?.name ?? 'Group'} — Members',
                          style:
                              const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: members.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Member list is not available',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 13)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (ctx, i) {
                          final mem = members[i];
                          final name =
                              (mem.displayName ?? '').trim().isEmpty
                                  ? mem.username
                                  : mem.displayName!;
                          final roleLabel = mem.role == 'owner'
                              ? ' · Owner'
                              : (mem.role == 'admin' ? ' · Admin' : '');
                          return ListTile(
                            leading: UserAvatar(
                                name: name, size: 38, online: mem.isOnline),
                            title: Text(name),
                            subtitle: Text('@${mem.username}$roleLabel',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ChatScreen(username: mem.username)));
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

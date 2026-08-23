import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation.dart';
import '../models/group.dart';
import '../services/ws_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'new_chat_screen.dart';
import 'group_create_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final searchCtrl = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final directs = state.conversations
        .where((c) => c.nameForDisplay.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final groups = state.groups
        .where((g) => g.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    final items = <_ListItem>[
      ...directs.map((d) => _ListItem.direct(d)),
      ...groups.map((g) => _ListItem.group(g)),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (r) => AppColors.accentGradient.createShader(r),
              child: const Text('چت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 8),
            _connectionDot(state.connectionState),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: searchCtrl,
              onChanged: (v) => setState(() => query = v),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'جستجو در گفتگوها',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
                    onRefresh: state.refreshConversations,
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) => items[i].build(context),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openComposeMenu(context),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _connectionDot(WsConnectionState s) {
    Color c;
    switch (s) {
      case WsConnectionState.connected:
        c = AppColors.green;
        break;
      case WsConnectionState.connecting:
        c = AppColors.orange;
        break;
      case WsConnectionState.disconnected:
        c = AppColors.red;
        break;
    }
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  }

  void _openComposeMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.accent),
              title: const Text('گفتگوی خصوصی جدید'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_rounded, color: AppColors.accent),
              title: const Text('ساخت یا پیوستن به گروه'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreateScreen()));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.muted),
          const SizedBox(height: 12),
          Text('هنوز گفتگویی نداری', style: TextStyle(color: AppColors.muted.withOpacity(0.9))),
          const SizedBox(height: 4),
          const Text('با دکمه‌ی + یک گفتگوی جدید شروع کن', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ListItem {
  final DirectConversation? direct;
  final GroupConversation? group;

  _ListItem.direct(this.direct) : group = null;
  _ListItem.group(this.group) : direct = null;

  int get timestamp =>
      direct?.lastMessage?.timestamp ?? group?.lastMessage?.timestamp ?? 0;

  Widget build(BuildContext context) {
    if (direct != null) {
      final d = direct!;
      final subtitle = d.lastMessage != null
          ? (d.lastMessage!.hasImage ? '📷 عکس' : d.lastMessage!.text)
          : (d.isBlocked ? 'بلاک شده' : (d.isOnline ? 'آنلاین' : 'آفلاین'));
      return ConversationTile(
        title: d.nameForDisplay,
        avatarUrl: d.avatarUrl,
        online: d.isOnline,
        unreadCount: d.unreadCount,
        subtitle: subtitle,
        timestamp: d.lastMessage?.timestamp,
        isPendingLast: d.lastMessage?.pending ?? false,
        blocked: d.isBlocked,
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => ChatScreen(username: d.username))),
      );
    }
    final g = group!;
    final subtitle = g.lastMessage != null
        ? '${g.lastMessage!.from != null ? '${g.lastMessage!.from}: ' : ''}${g.lastMessage!.hasImage ? '📷 عکس' : g.lastMessage!.text}'
        : '${g.memberCount} عضو، ${g.onlineCount} آنلاین';
    return ConversationTile(
      title: g.name,
      isGroup: true,
      unreadCount: g.unreadCount,
      subtitle: subtitle,
      timestamp: g.lastMessage?.timestamp,
      isPendingLast: g.lastMessage?.pending ?? false,
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: g.id))),
    );
  }
}

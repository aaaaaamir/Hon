import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/avatar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = context.read<AppState>();
      await state.refreshNotifications();
      await state.markNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('اعلان‌ها')),
      body: RefreshIndicator(
        onRefresh: state.refreshNotifications,
        child: ListView(
          children: [
            if (state.contactRequests.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('درخواست‌های مخاطب',
                    style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              ...state.contactRequests.map((r) => ListTile(
                    leading: UserAvatar(name: r.from, size: 42),
                    title: Text('${r.from} درخواست مخاطب فرستاد'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_rounded, color: AppColors.green),
                          onPressed: () => state.respondContactRequest(r.id, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, color: AppColors.red),
                          onPressed: () => state.respondContactRequest(r.id, false),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 20),
            ],
            if (state.notifications.isEmpty && state.contactRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Text('اعلانی وجود ندارد', style: TextStyle(color: AppColors.muted)),
                ),
              )
            else
              ...state.notifications.map((n) => ListTile(
                    leading: UserAvatar(name: n.from ?? '؟', size: 42),
                    title: Text(n.label),
                    subtitle: Text(formatTime(n.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    tileColor: n.read ? null : AppColors.card2,
                  )),
          ],
        ),
      ),
    );
  }
}

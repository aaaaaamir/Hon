import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/avatar.dart';

/// اعلان‌ها — مطابق نسخه‌ی وب (index.html) با چهار دسته‌بندی:
/// همه / درخواست‌ها / پذیرفته‌شده / ردشده.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _tab = 0;

  static const _tabs = ['همه', 'درخواست‌ها', 'پذیرفته‌شده', 'ردشده'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = context.read<AppState>();
      await state.refreshNotifications();
      await state.markNotificationsRead();
    });
  }

  List<AppNotification> _filtered(List<AppNotification> all) {
    switch (_tab) {
      case 1:
        return const []; // درخواست‌ها جدا نمایش داده می‌شوند
      case 2:
        return all.where((n) => n.type == 'contact_accept').toList();
      case 3:
        return all.where((n) => n.isReject).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final showRequests = _tab == 0 || _tab == 1;
    final items = _filtered(state.notifications);
    final empty = switch (_tab) {
      0 => state.contactRequests.isEmpty && state.notifications.isEmpty,
      1 => state.contactRequests.isEmpty,
      _ => items.isEmpty,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('اعلان‌ها')),
      body: Column(
        children: [
          // دسته‌بندی‌ها (مثل تب‌های وب)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = _tab == i;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _tab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _tabs[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                          color: selected ? Colors.white : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: state.refreshNotifications,
              child: ListView(
                children: [
                  if (showRequests && state.contactRequests.isNotEmpty) ...[
                    if (_tab == 0) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text('درخواست‌های مخاطب',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
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
                    if (showRequests && state.contactRequests.isNotEmpty && items.isNotEmpty)
                      const Divider(height: 20),
                  ],
                  if (empty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text('اعلانی وجود ندارد', style: TextStyle(color: AppColors.muted)),
                      ),
                    )
                  else
                    ...items.map((n) => ListTile(
                          leading: UserAvatar(name: n.from ?? '؟', size: 42),
                          title: Text(n.label),
                          subtitle: Text(formatTime(n.createdAt),
                              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          tileColor: n.read ? null : AppColors.card2,
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

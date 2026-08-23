import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ws_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final username = state.currentUsername ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: UserAvatar(name: username, size: 92)),
          const SizedBox(height: 14),
          Center(
            child: Text(username, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 28),
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.accent),
              title: const Text('ویرایش پروفایل'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    state.connectionState == WsConnectionState.connected
                        ? Icons.wifi_rounded
                        : Icons.wifi_off_rounded,
                    color: state.connectionState == WsConnectionState.connected
                        ? AppColors.green
                        : AppColors.muted,
                  ),
                  title: const Text('وضعیت اتصال'),
                  trailing: Text(
                    switch (state.connectionState) {
                      WsConnectionState.connected => 'متصل',
                      WsConnectionState.connecting => 'در حال اتصال',
                      WsConnectionState.disconnected => 'قطع',
                    },
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.red),
              title: const Text('خروج از حساب', style: TextStyle(color: AppColors.red)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: const Text('خروج از حساب'),
                    content: const Text('مطمئنی می‌خوای خارج بشی؟'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await state.logout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

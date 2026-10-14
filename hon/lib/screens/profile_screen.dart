import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ws_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import 'edit_profile_screen.dart';

/// پروفایل — مطابق وب: آواتار (با عکس واقعی)، نام نمایشی، بیو،
/// نشان «مهمان — ثبت‌نام‌نشده» و وضعیت اتصال همراه با تاخیر (میلی‌ثانیه).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshMyProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final username = state.currentUsername ?? '';
    final displayName =
        (state.myDisplayName != null && state.myDisplayName!.trim().isNotEmpty)
            ? state.myDisplayName!
            : username;
    final bio = state.myBio;
    final avatarUrl = state.myAvatarUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: UserAvatar(name: displayName, imageUrl: avatarUrl, size: 92)),
          const SizedBox(height: 14),
          Center(
            child: Text(displayName,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text('@$username',
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ),
          if (state.isGuestAccount) ...[
            const SizedBox(height: 6),
            const Center(
              child: Text('👤 مهمان — ثبت‌نام‌نشده',
                  style: TextStyle(fontSize: 12, color: AppColors.orange)),
            ),
          ],
          if (bio != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(bio,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ),
          ],
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
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.speed_rounded, color: AppColors.accent),
                  title: const Text('تاخیر اتصال'),
                  trailing: Text(
                    state.connectionLabel,
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final searchCtrl = TextEditingController();
  List<String> results = [];
  bool loading = false;
  Timer? debounce;

  @override
  void dispose() {
    searchCtrl.dispose();
    debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() => results = []);
      return;
    }
    debounce = Timer(const Duration(milliseconds: 400), () => _search(v.trim()));
  }

  Future<void> _search(String q) async {
    setState(() => loading = true);
    try {
      final state = context.read<AppState>();
      final raw = await state.api.searchUsers(q);
      results = raw
          .map((e) => e is String ? e : (e['username']?.toString() ?? ''))
          .where((e) => e.isNotEmpty && e != state.currentUsername)
          .cast<String>()
          .toList();
    } catch (_) {
      results = [];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('گفتگوی جدید')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchCtrl,
              autofocus: true,
              textAlign: TextAlign.right,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'شناسه کاربری را جستجو کن',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted),
              ),
            ),
          ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text('نتیجه‌ای برای نمایش نیست', style: TextStyle(color: AppColors.muted)))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final u = results[i];
                      return ListTile(
                        leading: UserAvatar(name: u, size: 40),
                        title: Text(u),
                        onTap: () {
                          Navigator.pushReplacement(
                              context, MaterialPageRoute(builder: (_) => ChatScreen(username: u)));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

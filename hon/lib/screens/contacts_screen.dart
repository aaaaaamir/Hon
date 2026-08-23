import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final searchCtrl = TextEditingController();
  List<String> searchResults = [];
  Timer? debounce;
  bool searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshContacts();
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => searching = true);
      try {
        final state = context.read<AppState>();
        final raw = await state.api.searchUsers(v.trim());
        searchResults = raw
            .map((e) => e is String ? e : (e['username']?.toString() ?? ''))
            .where((e) => e.isNotEmpty && e != state.currentUsername)
            .cast<String>()
            .toList();
      } catch (_) {
        searchResults = [];
      } finally {
        if (mounted) setState(() => searching = false);
      }
    });
  }

  Future<void> _addContact(String username) async {
    final state = context.read<AppState>();
    try {
      final res = await state.api.addContact(state.currentUsername!, username);
      final requested = res['status'] == 'requested';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(requested ? 'درخواست به «$username» فرستاده شد' : 'به مخاطبین اضافه شد')),
        );
      }
      state.refreshContacts();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انجام نشد')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('مخاطبین')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: searchCtrl,
              onChanged: _onSearchChanged,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'افزودن مخاطب با شناسه کاربری',
                prefixIcon: Icon(Icons.person_add_alt_1_rounded, color: AppColors.muted),
              ),
            ),
          ),
          if (searching) const LinearProgressIndicator(minHeight: 2),
          if (searchResults.isNotEmpty)
            ...searchResults.map((u) => ListTile(
                  leading: UserAvatar(name: u, size: 40),
                  title: Text(u),
                  trailing: TextButton(
                    onPressed: () => _addContact(u),
                    child: const Text('افزودن'),
                  ),
                )),
          if (searchResults.isNotEmpty) const Divider(height: 1),
          Expanded(
            child: state.myContacts.isEmpty
                ? const Center(child: Text('هنوز مخاطبی نداری', style: TextStyle(color: AppColors.muted)))
                : ListView.builder(
                    itemCount: state.myContacts.length,
                    itemBuilder: (context, i) {
                      final u = state.myContacts[i];
                      return ListTile(
                        leading: UserAvatar(name: u, size: 44),
                        title: Text(u, style: const TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => ChatScreen(username: u))),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

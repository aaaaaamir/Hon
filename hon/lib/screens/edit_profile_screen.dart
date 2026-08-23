import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final displayNameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    try {
      final data = await state.api.fetchProfile(state.currentUsername!);
      displayNameCtrl.text = data['displayName']?.toString() ?? '';
      bioCtrl.text = data['bio']?.toString() ?? '';
    } catch (_) {
      // اگر پروفایل خالی بود، فرم همچنان قابل تکمیل است
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    displayNameCtrl.dispose();
    bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await state.api.updateProfile(
        username: state.currentUsername!,
        displayName: displayNameCtrl.text.trim(),
        bio: bioCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => error = 'ذخیره‌سازی ناموفق بود');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ویرایش پروفایل')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: displayNameCtrl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(hintText: 'نام نمایشی'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioCtrl,
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'درباره من'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : _save,
                      child: saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('ذخیره'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

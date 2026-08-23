import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'group_chat_screen.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  bool creatingMode = true;
  final nameCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  String? error;
  bool busy = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    setState(() {
      error = null;
      busy = true;
    });
    try {
      final group = creatingMode
          ? await state.createGroup(nameCtrl.text.trim())
          : await state.joinGroup(codeCtrl.text.trim());
      if (group != null && mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: group.id)));
      }
    } on ApiException catch (e) {
      setState(() => error = e.message);
    } catch (_) {
      setState(() => error = 'خطا در اتصال به سرور');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('گروه')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: AppColors.card2, borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(child: _tab('ساخت گروه', true)),
                  Expanded(child: _tab('پیوستن با کد', false)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (creatingMode)
              TextField(
                controller: nameCtrl,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(hintText: 'نام گروه'),
              )
            else
              TextField(
                controller: codeCtrl,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(hintText: 'کد یا لینک دعوت گروه'),
              ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : _submit,
                child: busy
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(creatingMode ? 'ساخت گروه' : 'پیوستن به گروه'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool value) {
    final selected = creatingMode == value;
    return GestureDetector(
      onTap: () => setState(() {
        creatingMode = value;
        error = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ),
    );
  }
}

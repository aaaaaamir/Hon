import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';

/// ویرایش پروفایل — مطابق وب (index.html):
///  - «تغییر عکس پروفایل» (دوربین/گالری) + «ذخیره در گوشی»
///  - «نام نمایشی» و «بیو» + «ذخیره تغییرات»
///  - «تغییر شناسه‌ی کاربری» با «رمز عبور فعلی (برای تأیید)»
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

/// ذخیره در گالری از طریق کد بومی اندروید (بدون پلاگین)؛
/// پیاده‌سازی در MainActivity.kt با MediaStore.
const MethodChannel _galleryChannel = MethodChannel('com.example.hon/gallery');

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _picker = ImagePicker();
  final displayNameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final newUsernameCtrl = TextEditingController();
  final currentPassCtrl = TextEditingController();

  bool loading = true;
  bool saving = false;
  bool savingAvatar = false;
  bool changingUsername = false;
  bool savingToPhone = false;
  String? error;
  String? usernameError;

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
    newUsernameCtrl.dispose();
    currentPassCtrl.dispose();
    super.dispose();
  }

  void _snack(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  // ---------------- عکس پروفایل ----------------

  Future<void> _pickAvatar() async {
    if (savingAvatar) return;
    final source = await showModalBottomSheet<ImageSource>(
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
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
              title: const Text('انتخاب از گالری'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accent),
              title: const Text('گرفتن عکس با دوربین'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    if (!mounted) return;

    final state = context.read<AppState>();
    setState(() {
      savingAvatar = true;
      error = null;
    });
    final err = await state.changeAvatar(file);
    if (!mounted) return;
    setState(() {
      savingAvatar = false;
      if (err != null) error = err;
    });
  }

  /// «ذخیره در گوشی»: دانلود عکس پروفایل فعلی و ذخیره در گالری.
  Future<void> _saveAvatarToPhone() async {
    final state = context.read<AppState>();
    final url = state.myAvatarUrl;
    if (url == null || savingToPhone) return;

    setState(() => savingToPhone = true);
    final bytes = await state.downloadMyAvatarBytes();
    if (!mounted) return;
    if (bytes == null) {
      setState(() => savingToPhone = false);
      _snack('دانلود عکس ناموفق بود');
      return;
    }
    final saved = await _saveToGallery(bytes);
    if (!mounted) return;
    setState(() => savingToPhone = false);
    _snack(saved ? 'در گوشی ذخیره شد' : 'ذخیره در گوشی انجام نشد');
  }

  /// ذخیره از طریق کانال بومی (MediaStore در MainActivity).
  Future<bool> _saveToGallery(List<int> bytes) async {
    try {
      final result = await _galleryChannel.invokeMethod<bool>('saveImageToGallery', {
        'data': base64Encode(bytes),
        'name': 'hon_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      });
      return result == true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  // ---------------- ذخیره تغییرات ----------------

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
      await state.refreshMyProfile();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => error = 'ذخیره‌سازی ناموفق بود');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ---------------- تغییر شناسه ----------------

  Future<void> _changeUsername() async {
    final newUsername = newUsernameCtrl.text.trim();
    final password = currentPassCtrl.text.trim();
    setState(() => usernameError = null);

    if (!AppConfig.usernamePattern.hasMatch(newUsername)) {
      setState(() => usernameError =
          'شناسه فقط می‌تواند شامل حروف انگلیسی، عدد و _ باشد (۳ تا ۲۰ کاراکتر)');
      return;
    }
    if (password.isEmpty) {
      setState(() => usernameError = 'رمز عبور فعلی را برای تأیید وارد کنید');
      return;
    }

    final state = context.read<AppState>();
    setState(() => changingUsername = true);
    final err = await state.changeUsername(newUsername, password);
    if (!mounted) return;
    setState(() => changingUsername = false);
    if (err != null) {
      setState(() => usernameError = err);
      return;
    }
    _snack('شناسه کاربری تغییر کرد');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('ویرایش پروفایل')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // --- تغییر عکس پروفایل ---
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      UserAvatar(
                        name: displayNameCtrl.text.trim().isNotEmpty
                            ? displayNameCtrl.text.trim()
                            : (state.currentUsername ?? '?'),
                        imageUrl: state.myAvatarUrl,
                        size: 88,
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: savingAvatar ? null : _pickAvatar,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: savingAvatar
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.photo_camera_outlined,
                                    color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton.icon(
                    onPressed: state.myAvatarUrl == null || savingToPhone
                        ? null
                        : _saveAvatarToPhone,
                    icon: savingToPhone
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_alt_outlined, size: 16),
                    label: const Text('ذخیره در گوشی', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(height: 18),

                // --- نام نمایشی و بیو ---
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
                  decoration: const InputDecoration(hintText: 'بیو'),
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
                        : const Text('ذخیره تغییرات'),
                  ),
                ),
                const SizedBox(height: 16),

                // --- تغییر شناسه‌ی کاربری ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('تغییر شناسه‌ی کاربری',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: newUsernameCtrl,
                          textAlign: TextAlign.right,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'شناسه جدید'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: currentPassCtrl,
                          obscureText: true,
                          textAlign: TextAlign.right,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _changeUsername(),
                          decoration:
                              const InputDecoration(hintText: 'رمز عبور فعلی (برای تأیید)'),
                        ),
                        if (usernameError != null) ...[
                          const SizedBox(height: 10),
                          Text(usernameError!,
                              style: const TextStyle(color: AppColors.red, fontSize: 13)),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: changingUsername ? null : _changeUsername,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: changingUsername
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('تغییر شناسه'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}

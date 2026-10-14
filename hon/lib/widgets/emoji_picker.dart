import 'package:flutter/material.dart';
import '../theme.dart';

/// مجموعه‌ی ثابت اموجی‌ها — دقیقاً همان ۴۶ ایموجی که نسخه‌ی وب
/// (index.html) در نوار اموجیِ پایین چت نمایش می‌دهد.
const List<String> kEmojiSet = [
  '😀', '😁', '😂', '🤣', '😊', '😍', '😘', '😉', '😎', '🤔',
  '😅', '😢', '😭', '😡', '😱', '🥳', '👍', '👎', '🙏', '👏',
  '🔥', '❤️', '💔', '🎉', '✅', '❌', '⭐', '💯', '😴', '🤝',
  '👋', '🙌', '😇', '🤗', '😜', '🤩', '😐', '🙄', '😬', '🤐',
  '🥺', '😤', '😷', '🤒', '💪', '👀', '🤷', '🤦', '🎂', '☕',
];

/// دکمه‌ی اموجی کنار ورودی چت. با لمس، یک شیت با شبکه‌ی ایموجی‌ها
/// باز می‌شود و با هر لمس، ایموجی در مکان نشانگر متن درج می‌شود
/// (شیت تا بستن دست نمی‌شود تا امکان انتخاب چند ایموجی باشد).
class EmojiButton extends StatelessWidget {
  final TextEditingController controller;

  const EmojiButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.muted),
      onPressed: () => _open(context, controller),
    );
  }

  static void _open(BuildContext context, TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
            ),
            itemCount: kEmojiSet.length,
            itemBuilder: (c, i) {
              final emoji = kEmojiSet[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    final text = controller.text;
                    final sel = controller.selection;
                    final start =
                        (sel.isValid ? sel.start : text.length).clamp(0, text.length);
                    final end =
                        (sel.isValid ? sel.end : text.length).clamp(0, text.length);
                    controller.text =
                        text.replaceRange(start, end, emoji);
                    controller.selection =
                        TextSelection.collapsed(offset: start + emoji.length);
                  },
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

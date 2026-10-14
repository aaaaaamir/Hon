import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/message_actions.dart';
import '../widgets/message_bubble.dart';
import '../widgets/profile_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  const ChatScreen({super.key, required this.username});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final textCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  final focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  ChatMessage? replyTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().openChat(widget.username);
    });
  }

  @override
  void dispose() {
    context.read<AppState>().stopComposing(to: widget.username);
    context.read<AppState>().closeChat();
    textCtrl.dispose();
    scrollCtrl.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String v) {
    context.read<AppState>().onComposingChanged(to: widget.username);
  }

  void _send() {
    final text = textCtrl.text.trim();
    if (text.isEmpty) return;
    final state = context.read<AppState>();
    state.stopComposing(to: widget.username);
    state.sendDirectMessage(widget.username, text, replyTo: replyTo);
    textCtrl.clear();
    setState(() => replyTo = null);
    Future.delayed(const Duration(milliseconds: 60), _scrollToBottom);
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (file == null) return;
    if (!mounted) return;
    await context.read<AppState>().sendImageMessage(to: widget.username, file: file);
    Future.delayed(const Duration(milliseconds: 60), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (!scrollCtrl.hasClients) return;
    scrollCtrl.animateTo(
      scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.messagesForUser(widget.username);
    final conv = state.conversations.where((c) => c.username == widget.username).toList();
    final displayName = conv.isNotEmpty ? conv.first.nameForDisplay : widget.username;
    final isOnline = conv.isNotEmpty && conv.first.isOnline;
    final blocked = state.isBlocked(widget.username);
    final isTyping = state.isPeerTyping(widget.username);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        // مثل وب: لمس روی عنوان، کارت پروفایل کاربر را باز می‌کند.
        title: InkWell(
          onTap: () => _showProfileSheet(context),
          child: Row(
            children: [
              UserAvatar(name: displayName, size: 36, online: isOnline),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: isTyping
                          ? const Text('در حال نوشتن...',
                              key: ValueKey('typing'),
                              style: TextStyle(fontSize: 11.5, color: AppColors.accent))
                          : Text(
                              blocked ? 'بلاک شده' : (isOnline ? 'آنلاین' : 'آفلاین'),
                              key: const ValueKey('status'),
                              style: TextStyle(
                                  fontSize: 11.5, color: blocked ? AppColors.red : AppColors.muted),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              final s = context.read<AppState>();
              if (v == 'block') await s.toggleBlock(widget.username);
              if (v == 'report') _showReportSheet(context);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'block', child: Text(blocked ? 'رفع بلاک' : 'بلاک کردن')),
              const PopupMenuItem(value: 'report', child: Text('گزارش کاربر')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text('این اولین پیام از این کاربره.', style: TextStyle(color: AppColors.muted)),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      return MessageBubble(
                        message: m,
                        isMine: m.isMine(state.currentUsername ?? ''),
                        imageUrlBuilder: m.image?.id != null
                            ? () => state.imageUrl(m.image!.id!)
                            : null,
                        onTap: () => _showMessageActions(context, m),
                        onLongPress: () => _showMessageActions(context, m),
                      );
                    },
                  ),
          ),
          if (replyTo != null) _replyBar(),
          if (blocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.red.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('شما این کاربر را بلاک کرده‌اید.',
                          style: TextStyle(color: AppColors.red, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () => state.toggleBlock(widget.username),
                      child: const Text('آنبلاک',
                          style: TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            )
          else
            _inputBar(),
        ],
      ),
    );
  }

  Widget _replyBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.card2, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('پاسخ به ${replyTo!.from}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                Text(replyTo!.text, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
            onPressed: () => setState(() => replyTo = null),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(
          children: [
            EmojiButton(controller: textCtrl),
            IconButton(
              icon: const Icon(Icons.image_outlined, color: AppColors.muted),
              onPressed: _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: textCtrl,
                focusNode: focusNode,
                textAlign: TextAlign.right,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onChanged: _onTextChanged,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(hintText: 'پیام بنویس...'),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: const BoxDecoration(gradient: AppColors.accentGradient, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// تپ/نگه‌داشتن روی پیام → منوی عملیات (کپی، پاسخ، حذف) — مثل وب
  void _showMessageActions(BuildContext context, ChatMessage m) {
    showMessageActionsSheet(
      context,
      m,
      isMine: m.isMine(context.read<AppState>().currentUsername ?? ''),
      onReply: () => setState(() => replyTo = m),
      onDelete: (id) => context.read<AppState>().api.deleteMessage(id),
    );
  }

  /// کارت پروفایل کاربر — مثل بخش «پروفایل» در وب (ویجت مشترک)
  Future<void> _showProfileSheet(BuildContext context) async {
    await showUserProfileSheet(
      context,
      widget.username,
      onMessage: (ctx) => focusNode.requestFocus(),
    );
  }

  /// دیالوگ گزارش کاربر (مشترک)
  void _showReportSheet(BuildContext context) =>
      showReportUserSheet(context, widget.username);
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/message_bubble.dart';
import 'group_info_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final textCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();
  ChatMessage? replyTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().openGroup(widget.groupId);
    });
  }

  @override
  void dispose() {
    context.read<AppState>().stopComposing(groupId: widget.groupId);
    context.read<AppState>().closeGroup();
    textCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String v) {
    context.read<AppState>().onComposingChanged(groupId: widget.groupId);
  }

  void _send() {
    final text = textCtrl.text.trim();
    if (text.isEmpty) return;
    final state = context.read<AppState>();
    state.stopComposing(groupId: widget.groupId);
    state.sendGroupMessage(widget.groupId, text, replyTo: replyTo);
    textCtrl.clear();
    setState(() => replyTo = null);
    Future.delayed(const Duration(milliseconds: 60), _scrollToBottom);
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (file == null) return;
    if (!mounted) return;
    await context.read<AppState>().sendImageMessage(groupId: widget.groupId, file: file);
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
    final messages = state.messagesForGroup(widget.groupId);
    final groupList = state.groups.where((g) => g.id == widget.groupId).toList();
    final group = groupList.isNotEmpty ? groupList.first : null;
    final typingUsers = state.typingUsersInGroup(widget.groupId);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => GroupInfoScreen(groupId: widget.groupId))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(group?.name ?? 'گروه', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: typingUsers.isNotEmpty
                    ? Text(
                        '${typingUsers.join('، ')} در حال نوشتن...',
                        key: const ValueKey('typing'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.accent),
                      )
                    : Text(
                        group != null ? '${group.memberCount} عضو، ${group.onlineCount} آنلاین' : '',
                        key: const ValueKey('info'),
                        style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                      ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => GroupInfoScreen(groupId: widget.groupId))),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text('هنوز پیامی در گروه نیست', style: TextStyle(color: AppColors.muted)))
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      final mine = m.isMine(state.currentUsername ?? '');
                      return MessageBubble(
                        message: m,
                        isMine: mine,
                        senderLabel: mine ? null : m.from,
                        imageUrlBuilder: m.image?.id != null
                            ? () => state.imageUrl(m.image!.id!)
                            : null,
                        onReply: () => setState(() => replyTo = m),
                      );
                    },
                  ),
          ),
          if (replyTo != null) _replyBar(),
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
            IconButton(
              icon: const Icon(Icons.image_outlined, color: AppColors.muted),
              onPressed: _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: textCtrl,
                textAlign: TextAlign.right,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onChanged: _onTextChanged,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(hintText: 'پیام به گروه...'),
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
}

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../models/conversation.dart';
import '../models/group.dart';
import '../models/message.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/ws_service.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

class AppState extends ChangeNotifier {
  final ApiService api = ApiService();
  final WsService ws = WsService();
  final StorageService storage = StorageService();

  AuthStatus authStatus = AuthStatus.unknown;
  String? currentUsername;
  String? _authToken;
  String? _deviceId;
  String? authError;
  String? sessionErrorMessage;
  bool authBusy = false;

  final List<DirectConversation> conversations = [];
  final List<GroupConversation> groups = [];
  int notifBadge = 0;

  // پیام‌های هر چت خصوصی/گروهی، با کلید username یا groupId
  final Map<String, List<ChatMessage>> _messagesByPeer = {};
  final Map<String, List<ChatMessage>> _messagesByGroup = {};

  String? activeChatUser;
  String? activeGroupId;

  // نام کاربرانی که در حال حاضر دارن تایپ می‌کنن
  final Set<String> _typingPeers = {}; // برای چت خصوصی: username
  final Map<String, Set<String>> _typingInGroup = {}; // groupId -> usernames
  final Map<String, Timer> _typingTimers = {}; // کلید: "peer:x" یا "group:id:x"

  List<ContactRequest> contactRequests = [];
  List<String> myContacts = [];
  List<AppNotification> notifications = [];
  Set<String> blockedUsers = {};

  WsConnectionState connectionState = WsConnectionState.disconnected;

  AppState() {
    ws.connectionState.listen((s) {
      connectionState = s;
      notifyListeners();
    });
    ws.messages.listen(_handleWsMessage);
    _restoreSession();
  }

  String get _deviceIdOrGenerate {
    _deviceId ??= _randomId();
    return _deviceId!;
  }

  String _randomId() {
    final r = Random();
    return List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  // ---------------- Session ----------------

  Future<void> _restoreSession() async {
    final username = await storage.username;
    final token = await storage.token;
    if (username != null && token != null) {
      currentUsername = username;
      _authToken = token;
      api.setToken(token);
      authStatus = AuthStatus.loggedIn;
      notifyListeners();
      _startRealtime();
      await refreshConversations();
      await refreshContacts();
      await refreshNotifications();
    } else {
      authStatus = AuthStatus.loggedOut;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) =>
      _authAction(username, password, isLogin: true);

  Future<bool> signup(String username, String password) =>
      _authAction(username, password, isLogin: false);

  Future<bool> _authAction(String username, String password,
      {required bool isLogin}) async {
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      final data = isLogin
          ? await api.login(
              username: username, password: password, deviceId: _deviceIdOrGenerate)
          : await api.signup(
              username: username, password: password, deviceId: _deviceIdOrGenerate);
      final token = data['token']?.toString();
      if (token == null) {
        authError = 'پاسخ سرور نامعتبر بود';
        return false;
      }
      currentUsername = username;
      _authToken = token;
      api.setToken(token);
      await storage.saveSession(username: username, token: token);
      authStatus = AuthStatus.loggedIn;
      _applyConversationsSnapshot(data['conversations'] as Map<String, dynamic>?);
      _startRealtime();
      refreshContacts();
      refreshNotifications();
      return true;
    } on ApiException catch (e) {
      if (isLogin && e.reason == 'not_found') {
        authError = 'حساب یافت نشد؛ می‌توانید با همین شناسه ثبت‌نام کنید';
      } else {
        authError = e.message;
      }
      return false;
    } catch (e) {
      authError = 'خطا در اتصال به سرور';
      return false;
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  void _startRealtime() {
    ws.connect(
      username: currentUsername!,
      token: _authToken!,
      deviceId: _deviceIdOrGenerate,
    );
  }

  Future<void> logout() async {
    await api.logout();
    ws.disconnect();
    await storage.clearSession();
    currentUsername = null;
    _authToken = null;
    conversations.clear();
    groups.clear();
    _messagesByPeer.clear();
    _messagesByGroup.clear();
    contactRequests.clear();
    myContacts.clear();
    notifications.clear();
    blockedUsers.clear();
    _typingPeers.clear();
    _typingInGroup.clear();
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    _typingTimers.clear();
    activeChatUser = null;
    activeGroupId = null;
    authStatus = AuthStatus.loggedOut;
    notifyListeners();
  }

  // ---------------- Conversations ----------------

  Future<void> refreshConversations() async {
    if (currentUsername == null) return;
    try {
      final data = await api.fetchConversations(currentUsername!);
      _applyConversationsSnapshot(data);
    } catch (_) {
      // در آفلاین بودن، لیست محلی همچنان نمایش داده می‌شود
    }
  }

  void _applyConversationsSnapshot(Map<String, dynamic>? snapshot) {
    if (snapshot == null) return;
    conversations.clear();
    groups.clear();
    final direct = (snapshot['direct'] as List?) ?? [];
    for (final d in direct) {
      final c = DirectConversation.fromJson(Map<String, dynamic>.from(d));
      conversations.add(c);
      if (c.isBlocked) blockedUsers.add(c.username);
    }
    final g = (snapshot['groups'] as List?) ?? [];
    for (final item in g) {
      groups.add(GroupConversation.fromJson(Map<String, dynamic>.from(item)));
    }
    if (snapshot['notifBadge'] is int) notifBadge = snapshot['notifBadge'] as int;
    _sortConversations();
    notifyListeners();
  }

  void _sortConversations() {
    int valueOf(int? ts) => ts ?? 0;
    conversations.sort((a, b) =>
        valueOf(b.lastMessage?.timestamp).compareTo(valueOf(a.lastMessage?.timestamp)));
    groups.sort((a, b) =>
        valueOf(b.lastMessage?.timestamp).compareTo(valueOf(a.lastMessage?.timestamp)));
  }

  // ---------------- Messaging ----------------

  List<ChatMessage> messagesForUser(String username) =>
      _messagesByPeer[username] ?? const [];

  List<ChatMessage> messagesForGroup(String groupId) =>
      _messagesByGroup[groupId] ?? const [];

  Future<void> openChat(String username) async {
    activeChatUser = username;
    activeGroupId = null;
    ws.sendMarkRead(to: username);
    final idx = conversations.indexWhere((c) => c.username == username);
    if (idx >= 0) conversations[idx].unreadCount = 0;
    notifyListeners();
    try {
      final data = await api.fetchMessages(username);
      final list = (data['messages'] as List?) ?? [];
      _messagesByPeer[username] = list
          .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      notifyListeners();
    } catch (_) {
      // در صورت خطا، تاریخچه‌ی کش‌شده (اگر باشد) نمایش داده می‌ماند
    }
  }

  void closeChat() {
    activeChatUser = null;
    notifyListeners();
  }

  Future<void> openGroup(String groupId) async {
    activeGroupId = groupId;
    activeChatUser = null;
    ws.sendMarkRead(groupId: groupId);
    final idx = groups.indexWhere((g) => g.id == groupId);
    if (idx >= 0) groups[idx].unreadCount = 0;
    notifyListeners();
    try {
      final data = await api.groupInfo(currentUsername!, groupId);
      final gi = groups.indexWhere((g) => g.id == groupId);
      if (gi >= 0 && data['memberCount'] is int) {
        groups[gi].memberCount = data['memberCount'] as int;
        groups[gi].onlineCount = (data['onlineCount'] as int?) ?? groups[gi].onlineCount;
      }
      notifyListeners();
    } catch (_) {}
  }

  void closeGroup() {
    activeGroupId = null;
    notifyListeners();
  }

  void sendDirectMessage(String to, String text, {ChatMessage? replyTo}) {
    final local = ChatMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      from: currentUsername!,
      to: to,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      pending: true,
      replyTo: replyTo?.id,
      replyPreview: replyTo == null
          ? null
          : ReplyPreview(
              from: replyTo.from,
              text: replyTo.text.length > 80 ? replyTo.text.substring(0, 80) : replyTo.text),
    );
    _messagesByPeer.putIfAbsent(to, () => []).add(local);
    notifyListeners();
    ws.sendChatMessage(to: to, text: text, replyTo: replyTo?.id);
  }

  void sendGroupMessage(String groupId, String text, {ChatMessage? replyTo}) {
    final local = ChatMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      from: currentUsername!,
      groupId: groupId,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      pending: true,
      replyTo: replyTo?.id,
      replyPreview: replyTo == null
          ? null
          : ReplyPreview(
              from: replyTo.from,
              text: replyTo.text.length > 80 ? replyTo.text.substring(0, 80) : replyTo.text),
    );
    _messagesByGroup.putIfAbsent(groupId, () => []).add(local);
    notifyListeners();
    ws.sendChatMessage(groupId: groupId, text: text, replyTo: replyTo?.id);
  }

  // ---------------- Typing indicators ----------------

  Timer? _typingStopTimer;

  /// باید هر بار که متن ورودی چت تغییر می‌کند صدا زده شود؛ خودش تصمیم
  /// می‌گیرد که رویداد start را بفرستد و بعد از ۲.۵ ثانیه بی‌حرکتی، stop.
  void onComposingChanged({String? to, String? groupId}) {
    ws.send({
      'type': 'typing',
      'state': 'start',
      if (to != null) 'to': to,
      if (groupId != null) 'groupId': groupId,
    });
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(milliseconds: 2500), () {
      ws.send({
        'type': 'typing',
        'state': 'stop',
        if (to != null) 'to': to,
        if (groupId != null) 'groupId': groupId,
      });
    });
  }

  void stopComposing({String? to, String? groupId}) {
    _typingStopTimer?.cancel();
    ws.send({
      'type': 'typing',
      'state': 'stop',
      if (to != null) 'to': to,
      if (groupId != null) 'groupId': groupId,
    });
  }

  bool isPeerTyping(String username) => _typingPeers.contains(username);

  Set<String> typingUsersInGroup(String groupId) =>
      _typingInGroup[groupId] ?? const {};

  void _handleTypingEvent(Map<String, dynamic> data) {
    final from = data['from']?.toString();
    if (from == null) return;
    final groupId = data['groupId']?.toString();
    final state = data['state']?.toString();

    if (groupId != null) {
      final timerKey = 'group:$groupId:$from';
      _typingTimers[timerKey]?.cancel();
      final set = _typingInGroup.putIfAbsent(groupId, () => {});
      if (state == 'start') {
        set.add(from);
        _typingTimers[timerKey] = Timer(const Duration(seconds: 4), () {
          set.remove(from);
          notifyListeners();
        });
      } else {
        set.remove(from);
      }
    } else {
      final timerKey = 'peer:$from';
      _typingTimers[timerKey]?.cancel();
      if (state == 'start') {
        _typingPeers.add(from);
        _typingTimers[timerKey] = Timer(const Duration(seconds: 4), () {
          _typingPeers.remove(from);
          notifyListeners();
        });
      } else {
        _typingPeers.remove(from);
      }
    }
    notifyListeners();
  }

  // ---------------- Image messages ----------------

  Future<void> sendImageMessage({
    String? to,
    String? groupId,
    required XFile file,
    String text = '',
  }) async {
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final bytes = await file.readAsBytes();
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    final local = ChatMessage(
      id: localId,
      from: currentUsername!,
      to: to,
      groupId: groupId,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      pending: true,
      image: ImageAttachment(localPath: file.path),
    );

    final key = groupId ?? to!;
    final list = groupId != null
        ? _messagesByGroup.putIfAbsent(key, () => [])
        : _messagesByPeer.putIfAbsent(key, () => []);
    list.add(local);
    notifyListeners();

    try {
      final data = await api.uploadChatImage(
        username: currentUsername!,
        imageBase64: dataUrl,
        to: to,
        groupId: groupId,
      );
      final imageId = data['imageId']?.toString();
      final idx = list.indexWhere((m) => m.id == localId);
      if (idx >= 0) {
        list[idx].image = ImageAttachment(
          id: imageId,
          localPath: file.path,
          width: data['width'] as int?,
          height: data['height'] as int?,
        );
        list[idx].pending = false;
      }
      ws.sendChatMessage(to: to, groupId: groupId, text: text);
      notifyListeners();
    } catch (e) {
      final idx = list.indexWhere((m) => m.id == localId);
      if (idx >= 0) list[idx].uploadFailed = true;
      notifyListeners();
    }
  }

  String imageUrl(String imageId, {bool download = false}) =>
      api.imageDisplayUrl(imageId, currentUsername ?? '', download: download);

  // ---------------- WS incoming ----------------

  void _handleWsMessage(Map<String, dynamic> data) {
    final type = data['type'];
    switch (type) {
      case 'history':
        final list = (data['messages'] as List?) ?? [];
        for (final m in list) {
          _ingestMessage(ChatMessage.fromJson(Map<String, dynamic>.from(m)));
        }
        notifyListeners();
        break;
      case 'chat_message':
        _ingestMessage(ChatMessage.fromJson(data));
        notifyListeners();
        break;
      case 'notif_badge':
        notifBadge = (data['count'] as int?) ?? notifBadge;
        notifyListeners();
        break;
      case 'notification':
        notifBadge += 1;
        refreshNotifications();
        break;
      case 'contacts_changed':
        refreshContacts();
        break;
      case 'user_status_change':
        final idx = conversations.indexWhere((c) => c.username == data['username']);
        if (idx >= 0) {
          conversations[idx].isOnline = data['is_online'] == true;
          notifyListeners();
        }
        break;
      case 'conversation_update':
        refreshConversations();
        break;
      case 'block_update':
        final target = data['target']?.toString();
        if (target != null) {
          if (data['blocked'] == true) {
            blockedUsers.add(target);
          } else {
            blockedUsers.remove(target);
          }
          notifyListeners();
        }
        break;
      case 'message_deleted':
        final id = data['messageId']?.toString();
        if (id != null) {
          for (final list in _messagesByPeer.values) {
            for (final m in list) {
              if (m.id == id) m.deleted = true;
            }
          }
          for (final list in _messagesByGroup.values) {
            for (final m in list) {
              if (m.id == id) m.deleted = true;
            }
          }
          notifyListeners();
        }
        break;
      case 'group_update':
        refreshConversations();
        break;
      case 'typing':
        _handleTypingEvent(data);
        break;
      case 'auth_error':
      case 'banned':
        sessionErrorMessage = data['error']?.toString() ?? 'نشست شما پایان یافته است';
        logout();
        break;
      default:
        break;
    }
  }

  void _ingestMessage(ChatMessage msg) {
    if (msg.groupId != null) {
      final list = _messagesByGroup.putIfAbsent(msg.groupId!, () => []);
      list.removeWhere((m) => m.id.startsWith('local_') && m.text == msg.text && m.from == msg.from);
      list.add(msg);
    } else {
      final peer = msg.from == currentUsername ? msg.to : msg.from;
      if (peer == null) return;
      final list = _messagesByPeer.putIfAbsent(peer, () => []);
      list.removeWhere((m) => m.id.startsWith('local_') && m.text == msg.text && m.from == msg.from);
      list.add(msg);
    }
  }

  // ---------------- Contacts ----------------

  Future<void> refreshContacts() async {
    if (currentUsername == null) return;
    try {
      final data = await api.fetchContacts(currentUsername!);
      myContacts = ((data['contacts'] as List?) ?? [])
          .map((e) => e is String ? e : (e['username']?.toString() ?? ''))
          .where((e) => e.isNotEmpty)
          .cast<String>()
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> respondContactRequest(String requestId, bool accept) async {
    await api.respondContact(
        username: currentUsername!, requestId: requestId, accept: accept);
    contactRequests.removeWhere((r) => r.id == requestId);
    if (accept) refreshContacts();
    refreshNotifications();
    notifyListeners();
  }

  // ---------------- Notifications ----------------

  Future<void> refreshNotifications() async {
    if (currentUsername == null) return;
    try {
      final data = await api.fetchNotifications(currentUsername!);
      contactRequests = ((data['requests'] as List?) ?? [])
          .map((e) => ContactRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      notifications = ((data['notifications'] as List?) ?? [])
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markNotificationsRead() async {
    if (currentUsername == null) return;
    notifBadge = 0;
    notifyListeners();
    try {
      await api.markNotificationsRead(currentUsername!);
    } catch (_) {}
  }

  // ---------------- Groups ----------------

  Future<GroupConversation?> createGroup(String name) async {
    try {
      final data = await api.createGroup(currentUsername!, name);
      await refreshConversations();
      final id = data['id']?.toString();
      return groups.firstWhere((g) => g.id == id, orElse: () => GroupConversation(id: id ?? '', name: name));
    } on ApiException {
      rethrow;
    }
  }

  Future<GroupConversation?> joinGroup(String codeOrLink) async {
    var code = codeOrLink.trim();
    final match = RegExp(r'[?&]group=([a-zA-Z0-9]+)').firstMatch(code);
    if (match != null) code = match.group(1)!;
    final data = await api.joinGroup(currentUsername!, code);
    await refreshConversations();
    final id = data['id']?.toString();
    return groups.firstWhere((g) => g.id == id,
        orElse: () => GroupConversation(id: id ?? '', name: data['name']?.toString() ?? 'گروه'));
  }

  // ---------------- Block ----------------

  Future<void> toggleBlock(String username) async {
    if (blockedUsers.contains(username)) {
      await api.unblockUser(currentUsername!, username);
      blockedUsers.remove(username);
    } else {
      await api.blockUser(currentUsername!, username);
      blockedUsers.add(username);
    }
    notifyListeners();
  }

  bool isBlocked(String username) => blockedUsers.contains(username);
}

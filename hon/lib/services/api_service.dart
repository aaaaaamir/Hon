import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// خطای عمومی سطح API که پیام قابل‌نمایش به کاربر را همراه دارد.
class ApiException implements Exception {
  final String message;
  final String? reason;
  final int statusCode;
  ApiException(this.message, {this.reason, this.statusCode = 0});
  @override
  String toString() => message;
}

/// تمام تماس‌های REST با سرور (به‌جز بخش مدیریت/ادمین که عمداً حذف شده).
class ApiService {
  String? _authToken;

  void setToken(String? token) => _authToken = token;

  Uri _u(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Map<String, String> _headers([Map<String, String>? extra]) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_authToken != null) h['X-Auth-Token'] = _authToken!;
    if (extra != null) h.addAll(extra);
    return h;
  }

  Future<Map<String, dynamic>> _decode(http.Response res) async {
    if (res.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(_u(path), headers: _headers());
    return _handle(res);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(_u(path), headers: _headers(), body: jsonEncode(body));
    return _handle(res);
  }

  Future<Map<String, dynamic>> _handle(http.Response res) async {
    final data = await _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw ApiException(
      data['error']?.toString() ?? 'خطا در ارتباط با سرور',
      reason: data['reason']?.toString(),
      statusCode: res.statusCode,
    );
  }

  // ---------------- Auth ----------------

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String deviceId,
  }) {
    return _post('/api/login', {
      'username': username,
      'password': password,
      'deviceId': deviceId,
    });
  }

  Future<Map<String, dynamic>> signup({
    required String username,
    required String password,
    required String deviceId,
  }) {
    return _post('/api/signup', {
      'username': username,
      'password': password,
      'deviceId': deviceId,
    });
  }

  Future<void> logout() async {
    if (_authToken == null) return;
    try {
      await http.post(_u('/api/logout'), headers: _headers());
    } catch (_) {
      // خروج محلی مهم‌تر از موفقیت این درخواست است
    }
  }

  // ---------------- Conversations ----------------

  Future<Map<String, dynamic>> fetchConversations(String username) {
    return _get('/api/conversations?username=${Uri.encodeQueryComponent(username)}');
  }

  // ---------------- Users / search ----------------

  Future<List<dynamic>> searchUsers(String query) async {
    final data = await _get('/api/users/search?username=${Uri.encodeQueryComponent(query)}');
    return (data['users'] as List?) ?? (data['data'] as List?) ?? [];
  }

  Future<bool> userExists(String username) async {
    final data = await _get('/api/users/exists?username=${Uri.encodeQueryComponent(username)}');
    return data['exists'] == true;
  }

  // ---------------- Profile ----------------

  Future<Map<String, dynamic>> fetchProfile(String username) {
    return _get('/api/profile?username=${Uri.encodeQueryComponent(username)}');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String username,
    String? displayName,
    String? bio,
  }) {
    return _post('/api/profile/update', {
      'username': username,
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
    });
  }

  // ---------------- Messages ----------------

  Future<Map<String, dynamic>> fetchMessages(String username) {
    return _get('/api/messages?username=${Uri.encodeQueryComponent(username)}');
  }

  Future<void> deleteMessage(String messageId) {
    return _post('/api/messages/delete', {'messageId': messageId});
  }

  // ---------------- Contacts ----------------

  Future<Map<String, dynamic>> fetchContacts(String username) {
    return _get('/api/contacts?username=${Uri.encodeQueryComponent(username)}');
  }

  Future<Map<String, dynamic>> contactStatus(String username, String target) {
    return _get('/api/contacts/status?username=${Uri.encodeQueryComponent(username)}'
        '&target=${Uri.encodeQueryComponent(target)}');
  }

  Future<Map<String, dynamic>> addContact(String username, String target) {
    return _post('/api/contacts/add', {'username': username, 'target': target});
  }

  Future<Map<String, dynamic>> removeContact(String username, String target) {
    return _post('/api/contacts/remove', {'username': username, 'target': target});
  }

  Future<void> respondContact({
    required String username,
    required String requestId,
    required bool accept,
  }) {
    return _post('/api/contacts/respond', {
      'username': username,
      'requestId': requestId,
      'accept': accept,
    });
  }

  // ---------------- Groups ----------------

  Future<Map<String, dynamic>> createGroup(String username, String name) {
    return _post('/api/groups/create', {'username': username, 'name': name});
  }

  Future<Map<String, dynamic>> joinGroup(String username, String code) {
    return _post('/api/groups/join', {'username': username, 'code': code});
  }

  Future<Map<String, dynamic>> groupInfo(String username, String groupId) {
    return _post('/api/groups/info', {'username': username, 'groupId': groupId});
  }

  Future<void> leaveGroup(String username, String groupId) {
    return _post('/api/groups/leave', {'username': username, 'groupId': groupId});
  }

  Future<void> kickFromGroup(String username, String groupId, String target) {
    return _post('/api/groups/kick', {
      'username': username,
      'groupId': groupId,
      'target': target,
    });
  }

  Future<void> promoteInGroup(String username, String groupId, String target) {
    return _post('/api/groups/promote', {
      'username': username,
      'groupId': groupId,
      'target': target,
    });
  }

  Future<void> muteInGroup(String username, String groupId, String target, int minutes) {
    return _post('/api/groups/mute', {
      'username': username,
      'groupId': groupId,
      'target': target,
      'minutes': minutes,
    });
  }

  Future<void> togglePublicGroup(String username, String groupId, bool isPublic) {
    return _post('/api/groups/public-toggle', {
      'username': username,
      'groupId': groupId,
      'isPublic': isPublic,
    });
  }

  // ---------------- Block ----------------

  Future<Map<String, dynamic>> fetchBlockList(String username) {
    return _get('/api/blocks?username=${Uri.encodeQueryComponent(username)}');
  }

  Future<void> blockUser(String username, String target) {
    return _post('/api/block', {'username': username, 'target': target});
  }

  Future<void> unblockUser(String username, String target) {
    return _post('/api/unblock', {'username': username, 'target': target});
  }

  // ---------------- Notifications ----------------

  Future<Map<String, dynamic>> fetchNotifications(String username) {
    return _get('/api/notifications?username=${Uri.encodeQueryComponent(username)}');
  }

  Future<void> markNotificationsRead(String username) {
    return _post('/api/notifications/read', {'username': username});
  }

  // ---------------- Report ----------------

  Future<void> report({
    required String username,
    required String target,
    required String reason,
  }) {
    return _post('/api/report', {
      'username': username,
      'target': target,
      'reason': reason,
    });
  }

  // ---------------- Images ----------------

  /// آپلود عکس به‌صورت base64 (مطابق قرارداد سرور). چون سرور آپلود چندبخشی
  /// ندارد و فقط JSON می‌پذیرد، گزارش پیشرفتِ دقیق در دسترس نیست؛ صدا‌زننده
  /// باید در طول این تماس یک نشانگر «در حال آپلود» نشان دهد.
  Future<Map<String, dynamic>> uploadChatImage({
    required String username,
    required String imageBase64,
    String? to,
    String? groupId,
  }) {
    return _post('/api/chat-image/upload', {
      'username': username,
      'imageBase64': imageBase64,
      if (to != null) 'to': to,
      if (groupId != null) 'groupId': groupId,
    });
  }

  /// آدرس قابل‌نمایش عکس در حباب پیام (توکن به‌صورت کوئری‌استرینگ، چون
  /// Image.network نمی‌تواند هدر سفارشی اضافه کند مگر با NetworkImage headers).
  String imageDisplayUrl(String imageId, String username, {bool download = false}) {
    final base = '${AppConfig.baseUrl}/api/chat-image?id=${Uri.encodeQueryComponent(imageId)}'
        '&username=${Uri.encodeQueryComponent(username)}'
        '${download ? '&download=1' : ''}';
    if (_authToken == null) return base;
    return '$base&token=${Uri.encodeQueryComponent(_authToken!)}';
  }



  Future<Map<String, dynamic>> changeUsername({
    required String username,
    required String newUsername,
  }) {
    return _post('/api/change-username', {
      'username': username,
      'newUsername': newUsername,
    });
  }
}

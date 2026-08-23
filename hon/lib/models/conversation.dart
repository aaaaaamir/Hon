import 'last_message.dart';

class DirectConversation {
  final String username;
  String? displayName;
  String? avatarUrl;
  bool isOnline;
  int unreadCount;
  bool isBlocked;
  LastMessage? lastMessage;

  DirectConversation({
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    this.unreadCount = 0,
    this.isBlocked = false,
    this.lastMessage,
  });

  String get nameForDisplay =>
      (displayName != null && displayName!.trim().isNotEmpty)
          ? displayName!
          : username;

  factory DirectConversation.fromJson(Map<String, dynamic> json) {
    return DirectConversation(
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      avatarUrl: json['avatar']?.toString(),
      isOnline: json['is_online'] == true,
      unreadCount: (json['unreadCount'] is int) ? json['unreadCount'] as int : 0,
      isBlocked: json['isBlocked'] == true,
      lastMessage: json['lastMessage'] is Map
          ? LastMessage.fromJson(Map<String, dynamic>.from(json['lastMessage']))
          : null,
    );
  }
}

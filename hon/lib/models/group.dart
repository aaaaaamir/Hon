import 'last_message.dart';

class GroupConversation {
  final String id;
  String name;
  int memberCount;
  int onlineCount;
  int unreadCount;
  String? role; // owner / admin / member
  bool isPublic;
  LastMessage? lastMessage;

  GroupConversation({
    required this.id,
    required this.name,
    this.memberCount = 0,
    this.onlineCount = 0,
    this.unreadCount = 0,
    this.role,
    this.isPublic = false,
    this.lastMessage,
  });

  factory GroupConversation.fromJson(Map<String, dynamic> json) {
    return GroupConversation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'گروه',
      memberCount: (json['memberCount'] is int) ? json['memberCount'] as int : 0,
      onlineCount: (json['onlineCount'] is int) ? json['onlineCount'] as int : 0,
      unreadCount: (json['unreadCount'] is int) ? json['unreadCount'] as int : 0,
      role: json['role']?.toString(),
      isPublic: json['isPublic'] == true,
      lastMessage: json['lastMessage'] is Map
          ? LastMessage.fromJson(Map<String, dynamic>.from(json['lastMessage']))
          : null,
    );
  }
}

class GroupMember {
  final String username;
  final String? displayName;
  final bool isOnline;
  final String role;

  GroupMember({
    required this.username,
    this.displayName,
    this.isOnline = false,
    this.role = 'member',
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        username: json['username']?.toString() ?? '',
        displayName: json['displayName']?.toString(),
        isOnline: json['is_online'] == true,
        role: json['role']?.toString() ?? 'member',
      );
}

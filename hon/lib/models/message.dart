enum MessageStatus { pending, sent, delivered, seen }

class ReplyPreview {
  final String from;
  final String text;

  ReplyPreview({required this.from, required this.text});

  factory ReplyPreview.fromJson(Map<String, dynamic> json) => ReplyPreview(
        from: json['from']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'from': from, 'text': text};
}

class ImageAttachment {
  final String? id;
  final String? localPath; // مسیر محلی قبل از آپلود کامل (پیش‌نمایش فوری)
  final int? width;
  final int? height;

  ImageAttachment({this.id, this.localPath, this.width, this.height});

  factory ImageAttachment.fromJson(Map<String, dynamic> json) => ImageAttachment(
        id: json['id']?.toString(),
        width: json['width'] is int ? json['width'] as int : null,
        height: json['height'] is int ? json['height'] as int : null,
      );
}

class ChatMessage {
  final String id;
  final String from;
  final String? to;
  final String? groupId;
  final String text;
  final int timestamp;
  final String? replyTo;
  final ReplyPreview? replyPreview;
  MessageStatus status;
  bool pending;
  bool deleted;
  ImageAttachment? image;
  double uploadProgress; // 0..1، فقط برای پیام‌های محلی در حال آپلود
  bool uploadFailed;

  ChatMessage({
    required this.id,
    required this.from,
    this.to,
    this.groupId,
    required this.text,
    required this.timestamp,
    this.replyTo,
    this.replyPreview,
    this.status = MessageStatus.sent,
    this.pending = false,
    this.deleted = false,
    this.image,
    this.uploadProgress = 0,
    this.uploadFailed = false,
  });

  bool isMine(String myUsername) => from == myUsername;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? 'local_${DateTime.now().microsecondsSinceEpoch}')
          .toString(),
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString(),
      groupId: json['groupId']?.toString(),
      text: json['text']?.toString() ?? '',
      timestamp: (json['timestamp'] is int)
          ? json['timestamp'] as int
          : int.tryParse('${json['timestamp']}') ??
              DateTime.now().millisecondsSinceEpoch,
      replyTo: json['replyTo']?.toString(),
      replyPreview: json['replyPreview'] is Map
          ? ReplyPreview.fromJson(
              Map<String, dynamic>.from(json['replyPreview']))
          : null,
      status: MessageStatus.sent,
      pending: json['pending'] == true,
      image: json['image'] is Map
          ? ImageAttachment.fromJson(Map<String, dynamic>.from(json['image']))
          : (json['imageId'] != null ? ImageAttachment(id: json['imageId'].toString()) : null),
    );
  }

  DateTime get time => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

class ContactRequest {
  final String id;
  final String from;

  ContactRequest({required this.id, required this.from});

  factory ContactRequest.fromJson(Map<String, dynamic> json) => ContactRequest(
        id: json['id']?.toString() ?? '',
        from: json['from']?.toString() ?? '',
      );
}

class AppNotification {
  final String id;
  final String type;
  final String? from;
  final int createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.type,
    this.from,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        from: json['from']?.toString(),
        createdAt: (json['createdAt'] is int)
            ? json['createdAt'] as int
            : int.tryParse('${json['createdAt']}') ?? 0,
        read: json['read'] == true,
      );

  String get label {
    switch (type) {
      case 'contact_request':
        return '${from ?? ''} درخواست مخاطب فرستاد';
      case 'contact_accept':
        return '${from ?? ''} درخواست شما را پذیرفت';
      default:
        return 'اعلان جدید';
    }
  }
}

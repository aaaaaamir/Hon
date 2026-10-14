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

  /// آیا این اعلان مربوط به رد شدن یک درخواست مخاطب است؟
  bool get isReject =>
      type.contains('reject') || type.contains('decline') || type.contains('refuse');

  String get label {
    if (type == 'contact_request') {
      return '${from ?? ''} درخواست مخاطب فرستاد';
    }
    if (type == 'contact_accept') {
      return '${from ?? ''} درخواست شما را پذیرفت';
    }
    if (isReject) {
      return '${from ?? ''} درخواست شما را رد کرد';
    }
    return 'اعلان جدید';
  }
}

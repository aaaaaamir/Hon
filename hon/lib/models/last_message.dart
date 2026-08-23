class LastMessage {
  final String? from;
  final String text;
  final int timestamp;
  final bool pending;
  final bool hasImage;

  LastMessage({
    this.from,
    required this.text,
    required this.timestamp,
    this.pending = false,
    this.hasImage = false,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) => LastMessage(
        from: json['from']?.toString(),
        text: json['text']?.toString() ?? '',
        timestamp: (json['timestamp'] is int)
            ? json['timestamp'] as int
            : int.tryParse('${json['timestamp']}') ?? 0,
        pending: json['pending'] == true,
        hasImage: json['image'] != null,
      );
}

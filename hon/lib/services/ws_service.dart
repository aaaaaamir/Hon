import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

enum WsConnectionState { connecting, connected, disconnected }

/// اتصال زنده به سرور برای پیام‌های لحظه‌ای، وضعیت آنلاین، تایپینگ و غیره.
/// با قطعی شبکه خودکار دوباره وصل می‌شود.
///
/// مثل نسخه‌ی وب (index.html)، هر ۲۵ ثانیه یک ping می‌فرستد و اگر سرور
/// پاسخ دهد (pong یا تکرار `t`)، تاخیر اتصال (RTT) محاسبه و روی جریان
/// [latency] سرازیر می‌شود تا در UI به‌صورت «…میلی‌ثانیه» نمایش داده شود.
class WsService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  final _stateController = StreamController<WsConnectionState>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _latencyController = StreamController<int>.broadcast();

  Stream<WsConnectionState> get connectionState => _stateController.stream;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// تاخیر هر بار که یک ping جواب گرفت (بر حسب میلی‌ثانیه).
  Stream<int> get latency => _latencyController.stream;

  String? _username;
  String? _token;
  String? _deviceId;
  int _lastMessageTimestamp = 0;
  bool _closedByUser = false;

  /// زمان ارسال ping در انتظار پاسخ (null = ping در انتظار نیست).
  int? _pendingPingAt;

  void connect({
    required String username,
    required String token,
    required String deviceId,
    int lastMessageTimestamp = 0,
  }) {
    _username = username;
    _token = token;
    _deviceId = deviceId;
    _lastMessageTimestamp = lastMessageTimestamp;
    _closedByUser = false;
    _pendingPingAt = null;
    _open();
  }

  void _open() {
    _stateController.add(WsConnectionState.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl));
    } catch (_) {
      _scheduleReconnect();
      return;
    }

    _sub = _channel!.stream.listen(
      _onData,
      onDone: _onClosed,
      onError: (_) => _onClosed(),
      cancelOnError: true,
    );

    send({
      'type': 'register',
      'username': _username,
      'token': _token,
      'deviceId': _deviceId,
      'lastMessageTimestamp': _lastMessageTimestamp,
    });

    _stateController.add(WsConnectionState.connected);
    _startPing();
  }

  void _onData(dynamic raw) {
    try {
      final data = jsonDecode(raw as String);
      if (data is Map<String, dynamic>) {
        // --- اندازه‌گیری تاخیر: سرور یا `pong` می‌فرستد یا `t` خود ping را
        // تکرار می‌کند؛ هر دو حالت را می‌پذیریم.
        final String? type = data['type']?.toString();
        if (type == 'pong' || data['t'] == _pendingPingAt) {
          final sentAt = _pendingPingAt;
          _pendingPingAt = null;
          if (sentAt != null) {
            final rtt = DateTime.now().millisecondsSinceEpoch - sentAt;
            if (rtt >= 0 && rtt < 30000) {
              _latencyController.add(rtt);
            }
          }
        }

        if (type == 'chat_message' &&
            data['timestamp'] is int &&
            (data['timestamp'] as int) > _lastMessageTimestamp) {
          _lastMessageTimestamp = data['timestamp'] as int;
        }
        _messageController.add(data);
      }
    } catch (_) {
      // پیام غیرقابل‌پارس؛ نادیده گرفته می‌شود
    }
  }

  void _onClosed() {
    _pingTimer?.cancel();
    _pendingPingAt = null;
    _stateController.add(WsConnectionState.disconnected);
    if (!_closedByUser) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_closedByUser && _username != null) _open();
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    // مثل وب: بلافاصله پس از اتصال یک ping بفرست تا تاخیر زودتر معلوم شود.
    _sendPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) => _sendPing());
  }

  void _sendPing() {
    if (_pendingPingAt != null) return; // ping قبلی هنوز جواب نگرفته
    _pendingPingAt = DateTime.now().millisecondsSinceEpoch;
    send({
      'type': 'ping',
      't': _pendingPingAt,
    });
  }

  void send(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (_) {
      // اگر اتصال قطع باشد پیام ارسال نمی‌شود؛ منطق تلاش دوباره در لایه‌ی بالاتر است
    }
  }

  void sendChatMessage({
    String? to,
    String? groupId,
    required String text,
    String? replyTo,
  }) {
    send({
      'type': 'chat_message',
      if (to != null) 'to': to,
      if (groupId != null) 'groupId': groupId,
      'text': text,
      if (replyTo != null) 'replyTo': replyTo,
    });
  }

  void sendMarkRead({String? to, String? groupId}) {
    send({
      'type': 'mark_read',
      if (to != null) 'to': to,
      if (groupId != null) 'groupId': groupId,
    });
  }

  void disconnect() {
    _closedByUser = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _pendingPingAt = null;
    _sub?.cancel();
    _channel?.sink.close();
  }
}

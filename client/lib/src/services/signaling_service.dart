import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SignalingService {
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onMessageReceived;
  String? _roomId;
  String? _userId;

  void connect(String roomId, String userId, String role) {
    _roomId = roomId;
    _userId = userId;

    // Convert http/https to ws/wss
    var apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    if (apiUrl.startsWith('https://')) {
      apiUrl = apiUrl.replaceFirst('https://', 'wss://');
    } else if (apiUrl.startsWith('http://')) {
      apiUrl = apiUrl.replaceFirst('http://', 'ws://');
    }

    final wsUrl = '$apiUrl/ws/interview/$_roomId/$_userId';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Join Room Event
      sendMessage({
        'type': 'join',
        'room_id': _roomId,
        'user_id': _userId,
        'role': role,
      });

      _channel?.stream.listen(
        (data) {
          if (kDebugMode) print('WS Received: $data');
          final decoded = jsonDecode(data);
          onMessageReceived?.call(decoded);
        },
        onError: (error) {
          if (kDebugMode) print('WS Error: $error');
        },
        onDone: () {
          if (kDebugMode) print('WS Closed');
        },
      );
    } catch (e) {
      if (kDebugMode) print('WS Connection Error: $e');
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}

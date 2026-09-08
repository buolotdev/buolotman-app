import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';

/// Authenticated conversation WebSocket. REST remains the source of truth for
/// sending and loading history; the socket only delivers new events instantly.
class RealtimeChatConnection {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  Future<void> connect({
    required dynamic conversationId,
    required void Function(Map<String, dynamic> message) onMessage,
    void Function(Object error)? onError,
  }) async {
    final token = await ApiService().accessToken();
    if (token == null || token.isEmpty) return;
    final scheme = ApiService.serverBase.startsWith('https') ? 'wss' : 'ws';
    final host = ApiService.serverBase.replaceFirst(RegExp(r'^https?://'), '');
    final uri = Uri.parse(
      '$scheme://$host/ws/conversations/$conversationId/?token=${Uri.encodeComponent(token)}',
    );
    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _subscription = _channel!.stream.listen((event) {
        try {
          final decoded = jsonDecode('$event');
          if (decoded is Map) onMessage(Map<String, dynamic>.from(decoded));
        } catch (error) {
          onError?.call(error);
        }
      }, onError: (Object error) => onError?.call(error));
    } catch (error) {
      onError?.call(error);
      await close();
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }
}

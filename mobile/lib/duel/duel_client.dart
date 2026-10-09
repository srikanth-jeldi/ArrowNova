import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DuelClient extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Timer? _retry, _helloTimer;
  String? _token;
  String endpoint = const String.fromEnvironment(
    'DUEL_URL',
    defaultValue: 'ws://127.0.0.1:8788/duel',
  );
  String name = 'Explorer', status = 'disconnected', message = '';
  Map<String, dynamic> state = {'phase': 'lobby'};
  int sequence = 0, blockedEvents = 0, _generation = 0;
  bool _disposed = false, _intentional = false;
  bool get online => status == 'connected';
  void changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> connect([String? url]) async {
    if (_disposed) return;
    if (url != null && url != endpoint) {
      _token = null;
      state = {'phase': 'lobby'};
      sequence = 0;
    }
    endpoint = url ?? endpoint;
    final uri = Uri.tryParse(endpoint);
    if (uri == null ||
        !['ws', 'wss'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      status = 'disconnected';
      message = 'Enter a valid server address.';
      changed();
      return;
    }
    final local = ['localhost', '127.0.0.1', '10.0.2.2'].contains(uri.host);
    if (!kDebugMode && !local && uri.scheme != 'wss') {
      message = 'Online servers require a secure wss connection.';
      changed();
      return;
    }
    _intentional = false;
    _retry?.cancel();
    _helloTimer?.cancel();
    final generation = ++_generation;
    await _subscription?.cancel();
    await _channel?.sink.close();
    if (_disposed || generation != _generation) return;
    status = 'connecting';
    message = '';
    changed();
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready.timeout(const Duration(seconds: 8));
      if (_disposed || generation != _generation) {
        await channel.sink.close();
        return;
      }
      _subscription = channel.stream.listen(
        (raw) {
          if (_disposed || generation != _generation) return;
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            switch (data['type']) {
              case 'hello':
                _helloTimer?.cancel();
                _token = data['token'] as String;
                name = data['name'] as String;
                status = 'connected';
                message = '';
              case 'state':
                if (state['code'] != data['code']) sequence = 0;
                state = data;
              case 'blocked':
                blockedEvents++;
              case 'error':
                message = data['message'] as String;
              case 'expired':
                _token = null;
                sequence = 0;
                state = {'phase': 'lobby'};
                message =
                    'Previous session expired. Connect again for a new duel.';
                _intentional = true;
                status = 'disconnected';
            }
            changed();
          } catch (_) {
            message = 'Unexpected server message.';
            changed();
          }
        },
        onError: (_) => disconnected(generation),
        onDone: () => disconnected(generation),
      );
      channel.sink.add(
        jsonEncode({'type': 'hello', if (_token != null) 'token': _token}),
      );
      _helloTimer = Timer(const Duration(seconds: 8), () {
        if (!online) disconnected(generation);
      });
    } catch (_) {
      disconnected(generation);
    }
  }

  void disconnected(int generation) {
    if (_disposed || generation != _generation || _intentional) return;
    _helloTimer?.cancel();
    status = 'disconnected';
    message = _token == null
        ? 'Server unavailable. Check the connection and try again.'
        : 'Connection lost. Reconnecting; the match clock keeps running.';
    changed();
    if (_token != null) {
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 2), () => connect());
    }
  }

  void send(String type, [Map<String, Object?> extra = const {}]) {
    if (!online) return;
    message = '';
    _channel?.sink.add(jsonEncode({'type': type, ...extra}));
    changed();
  }

  void tap(int id) =>
      send('tap', {'id': id, 'seq': ++sequence, 'board': state['board']});
  @override
  void dispose() {
    if (online) send('leave');
    _disposed = true;
    _intentional = true;
    _generation++;
    _retry?.cancel();
    _helloTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

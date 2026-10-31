import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'api_config.dart';

/// Connexion WebSocket STOMP unique, partagée. Permet de s'abonner à des
/// topics (ex. `/topic/conversations/{id}`) pour recevoir en temps réel.
class StompService {
  StompClient? _client;
  Completer<void>? _ready;

  void _ensureActivated() {
    if (_client != null) return;
    _ready = Completer<void>();
    _client = StompClient(
      config: StompConfig(
        url: ApiConfig.wsUrl,
        onConnect: (_) {
          if (!(_ready?.isCompleted ?? true)) _ready!.complete();
        },
        onWebSocketError: (_) {},
        onStompError: (_) {},
        reconnectDelay: const Duration(seconds: 3),
      ),
    );
    _client!.activate();
  }

  /// S'abonne à [destination]. Renvoie une fonction d'annulation.
  /// Si la connexion échoue, renvoie un no-op (le REST prend le relais).
  Future<void Function()> subscribe(
    String destination,
    void Function(Map<String, dynamic> message) onMessage,
  ) async {
    _ensureActivated();
    try {
      await _ready!.future.timeout(const Duration(seconds: 8));
    } catch (_) {
      return () {};
    }

    final unsubscribe = _client!.subscribe(
      destination: destination,
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        try {
          onMessage(jsonDecode(body) as Map<String, dynamic>);
        } catch (_) {
          // corps non JSON → ignoré
        }
      },
    );
    return () {
      try {
        unsubscribe();
      } catch (_) {}
    };
  }

  void dispose() {
    _client?.deactivate();
    _client = null;
  }
}

final stompServiceProvider = Provider<StompService>((ref) {
  final service = StompService();
  ref.onDispose(service.dispose);
  return service;
});

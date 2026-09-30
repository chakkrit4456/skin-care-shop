import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api.dart';

/// A "data changed" signal from the server. Not value-equal on purpose, so repeats still notify.
class LiveEvent {
  final String topic; // products | categories | orders | users | * (reconnected, refresh everything)
  LiveEvent(this.topic);
}

final liveEventsProvider = StreamProvider<LiveEvent>((ref) {
  final controller = StreamController<LiveEvent>();
  WebSocketChannel? channel;
  Timer? retry;
  var closed = false;
  var connectedBefore = false;

  void connect() {
    if (closed) return;
    final ch = WebSocketChannel.connect(api.liveUri());
    channel = ch;
    ch.ready.then((_) {
      // events may have been missed while disconnected
      if (connectedBefore) controller.add(LiveEvent('*'));
      connectedBefore = true;
    }, onError: (_) {});
    ch.stream.listen(
      (msg) {
        final topic = (jsonDecode(msg as String) as Map)['topic'];
        if (topic is String) controller.add(LiveEvent(topic));
      },
      onDone: () {
        if (!closed) retry = Timer(const Duration(seconds: 3), connect);
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  connect();
  ref.onDispose(() {
    closed = true;
    retry?.cancel();
    channel?.sink.close();
    controller.close();
  });
  return controller.stream;
});

/// Call inside a provider to refetch it whenever one of [topics] changes on the server.
void refreshOnLive(Ref ref, Set<String> topics) {
  ref.listen(liveEventsProvider, (_, next) {
    final t = next.valueOrNull?.topic;
    if (t != null && (t == '*' || topics.contains(t))) ref.invalidateSelf();
  });
}

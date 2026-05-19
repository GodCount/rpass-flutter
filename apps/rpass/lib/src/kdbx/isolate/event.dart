import 'dart:async';

import 'kdbx_data.dart';

abstract class KdbxIsolateEvent<T> {
  KdbxIsolateEvent() : id = ++_count;

  static int _count = 0;
  static final Map<int, Completer<dynamic>> _map = {};

  final int id;

  (Object, StackTrace)? error;

  T? data;

  Future<T> get future {
    if (_map[id] != null) return _map[id]!.future as Future<T>;

    final completer = Completer<T>();

    _map[id] = completer;

    return completer.future;
  }

  void complete() {
    if (_map[id] != null && !_map[id]!.isCompleted) {
      if (error != null) {
        _map[id]!.completeError(error!.$1, error!.$2);
      } else {
        _map[id]!.complete(data);
      }
    }
  }
}

class SreachEntryEvent extends KdbxIsolateEvent<List<KdbxEntryData>> {
  SreachEntryEvent(this.text);

  final String text;
}

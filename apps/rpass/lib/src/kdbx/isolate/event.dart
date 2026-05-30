import 'dart:async';

import 'package:kpasslib/kpasslib.dart';

import '../extension.dart';
import '../field_statistic.dart';
import '../search_handler.dart';
import 'kdbx_data.dart';

abstract class GeneralHandler {
  Future<void> handler(KdbxDatabase db);
}

abstract class KdbxIsolateEvent<T> {
  KdbxIsolateEvent() : id = ++_count;

  static int _count = 0;
  static final Map<int, Completer<dynamic>> _map = {};

  final int id;

  (Object, StackTrace)? error;

  T? data;

  Future<T?> get future {
    if (_map[id] != null) return _map[id]!.future as Future<T?>;

    final completer = Completer<T?>();

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
  SreachEntryEvent(
    this.text, {
    this.useKdbxEntryConfig = false,
    this.groupUuid,
  });

  final String text;

  /// 组 uuid 如果存在则只从此组下搜索
  final String? groupUuid;

  /// 使用 enableDisplay , enableSearching 过滤列表
  final bool useKdbxEntryConfig;

  Future<void> handler(KdbxDatabase db, KbdxSearchHandler searchHandler) async {
    Iterable<KdbxEntry> list;

    final group = groupUuid != null
        ? db.findGroupByUuid(groupUuid!.kdbxUuid)
        : null;

    if (group != null) {
      list = group.allEntries;
    } else {
      list = db.totalEntry;
    }

    data = searchHandler
        .search(text, list, useKdbxEntryConfig: useKdbxEntryConfig)
        .map(
          (item) => KdbxEntryData.formKdbxEntry(item, type: .passwordPageList),
        )
        .toList();
  }
}

class FieldStatisticEvent extends KdbxIsolateEvent<FieldStatistic> {
  Future<void> handler(FieldStatistic fieldStatistic) async {
    data = fieldStatistic;
  }
}

class CustomIconsEvent extends KdbxIsolateEvent<Map<String, KdbxCustomIcon>>
    implements GeneralHandler {
  @override
  Future<void> handler(KdbxDatabase db) async {
    data = db.meta.customIcons.map(
      (item, value) => MapEntry(item.string, value),
    );
  }
}

class DataBinaryEvent extends KdbxIsolateEvent<Map<int, KdbxDataBinary>>
    implements GeneralHandler {
  @override
  Future<void> handler(KdbxDatabase db) async {
    data = Map.fromEntries(
      db.binaries.allAsRefs.map(
        (item) => MapEntry(item.id, db.binaries.getByRef(item)!),
      ),
    );
  }
}

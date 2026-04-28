import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart' as crypto;
import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:flutter/foundation.dart'
    show ObserverList, ValueChanged, protected;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// UI 布局使用, 后续可能会去掉; 而是通过屏幕大小决定
final bool isMobile = Platform.isAndroid || Platform.isIOS;
final bool isDesktop = !isMobile;

// 功能层面判断
final bool kIsMobile = Platform.isAndroid || Platform.isIOS;
final bool kIsDesktop =
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

const storageUnitSuffixes = [
  "B",
  "KB",
  "MB",
  "GB",
  "TB",
  "PB",
  "EB",
  "ZB",
  "YB",
];

enum StorageUnit { B, KB, MB, GB, TB, PB, EB, ZB, YB }

String md5(String data) {
  return crypto.md5.convert(utf8.encode(data)).toString();
}

List<Map<String, dynamic>> csvToJson(
  String csv, {
  String? fieldDelimiter,
  String? textDelimiter,
  String? textEndDelimiter,
  String? eol,
  CsvSettingsDetector? csvSettingsDetector,
  bool? shouldParseNumbers,
  bool? allowInvalid,
  var convertEmptyTo,
}) {
  final list2 = const CsvToListConverter().convert(
    csv,
    fieldDelimiter: fieldDelimiter,
    textDelimiter: textDelimiter,
    textEndDelimiter: textEndDelimiter,
    eol: eol,
    csvSettingsDetector: csvSettingsDetector,
    shouldParseNumbers: shouldParseNumbers,
    allowInvalid: allowInvalid,
    convertEmptyTo: convertEmptyTo,
  );

  final fields = list2.first;

  final List<Map<String, dynamic>> results = [];

  for (var i = 1; i < list2.length; i++) {
    final item = list2[i];
    final Map<String, dynamic> result = {};
    for (var j = 0; j < fields.length; j++) {
      result[fields[j]] = item[j];
    }
    results.add(result);
  }

  return results;
}

String jsonToCsv(
  List<Map<String, dynamic>> list, {
  String? fieldDelimiter,
  String? textDelimiter,
  String? textEndDelimiter,
  String? eol,
  bool? delimitAllFields,
  var convertNullTo,
}) {
  final fields = list.first.keys.toList();
  final List<List> results = [fields];
  for (var item in list) {
    results.add(item.values.toList());
  }
  return const ListToCsvConverter().convert(
    results,
    fieldDelimiter: fieldDelimiter,
    textDelimiter: textDelimiter,
    textEndDelimiter: textEndDelimiter,
    eol: eol,
    delimitAllFields: delimitAllFields,
    convertNullTo: convertNullTo,
  );
}

class CommonRegExp {
  static final RegExp domain = RegExp(r"^(https?:\/\/)?(\w+)\..+");
  static final RegExp email = RegExp(
    r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
    r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
    r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
    r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
    r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
    r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
    r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])',
  );

  static final RegExp oneTimePassword = RegExp(r"^otpauth://totp/.+");
}

/// Simple string to enum
extension StringToEnum<T extends Enum> on Iterable<T> {
  T toEnum(String name, [T? defaultValue]) {
    for (var value in this) {
      if (value.name == name) return value;
    }
    if (defaultValue != null) return defaultValue;
    throw ArgumentError('No enum value found for "$name" in $T');
  }

  T? optEnum(String name, [T? defaultValue]) {
    for (var value in this) {
      if (value.name == name) return value;
    }
    if (defaultValue != null) return defaultValue;
    return null;
  }
}

/// format

double transformStorageUnit<T extends num>(
  T number,
  StorageUnit source,
  StorageUnit target,
) {
  return number / math.pow(1024, target.index - source.index);
}

String bytes2Unit(num bytes, StorageUnit unit, [int decimals = 1]) {
  if (bytes <= 0) return "0 B";
  return "${transformStorageUnit(bytes, .B, unit).toStringAsFixed(decimals)} ${storageUnitSuffixes[unit.index]}";
}

String bytes2BestUnit(num bytes, [int decimals = 1]) {
  final i = (math.log(bytes) / math.log(1024)).floor();
  return bytes2Unit(bytes, StorageUnit.values[i], decimals);
}

extension BytesFormatByInt on num {
  String get bytesToBestUnit => bytes2BestUnit(this);

  String toStorageUnit(StorageUnit unit, [int decimals = 1]) {
    return bytes2Unit(this, unit, decimals);
  }
}

String dateFormat(DateTime date, [bool time = true]) {
  if (time) return DateFormat("yyyy.MM.dd HH:mm:ss").format(date);
  return DateFormat("yyyy.MM.dd").format(date);
}

extension DateFormatByTime on DateTime {
  String get formatDate => dateFormat(this);
}

extension RepeatObject<T> on T {
  List<T> repeat(int len) {
    if (len <= 0) return [];
    return List.filled(len, this);
  }
}

extension CommonString on String {
  bool isRepeatChar() {
    return Set.from(split("")).length != length;
  }

  String simpleToDomain() {
    if (startsWith(RegExp(r"https?://"))) {
      return split("/")[2].trim();
    } else {
      return split("/")[0].trim();
    }
  }

  String? get emptyToNull => isEmpty ? null : this;
}

mixin SimpleObserverListener<T> {
  final ObserverList<T> _listeners = ObserverList<T>();

  List<T> get listeners => List.unmodifiable(_listeners);

  bool get hasListeners => _listeners.isNotEmpty;

  @protected
  void emit(ValueChanged<T> handle) {
    for (final item in listeners) {
      handle(item);
    }
  }

  void addListener(T listener) {
    _listeners.add(listener);
  }

  void removeListener(T listener) {
    _listeners.remove(listener);
  }

  void removeAllListener() {
    _listeners.clear();
  }
}

class SimpleAsyncQueue {
  final _queue = <Future<void> Function()>[];
  bool _isProcessing = false;

  Future<T> add<T>(Future<T> Function() task) {
    final completer = Completer<T>();

    Future<void> wrappedTask() async {
      try {
        final result = await task();
        completer.complete(result);
      } catch (e, stackTrace) {
        completer.completeError(e, stackTrace);
      }
    }

    _queue.add(wrappedTask);
    _processQueue();

    return completer.future;
  }

  void _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      await task(); // 等待当前任务完成
    }

    _isProcessing = false;
  }

  void clear() {
    _queue.clear();
  }

  int get length => _queue.length;

  bool get isProcessing => _isProcessing;
}

///
/// 用于在软件后台时防止定时器因为优化导致偏差较大
///
class SimpleTimestampTimer implements Timer {
  SimpleTimestampTimer._(this.timer);

  final Timer timer;

  factory SimpleTimestampTimer(
    Duration duration,
    VoidCallback callback, {
    Duration? interval,
  }) {
    assert(
      interval == null || interval < duration,
      "Interval should be shorter than duration",
    );

    interval =
        interval ??
        (duration.inSeconds < 1 ? duration : const Duration(seconds: 1));

    final startTime = DateTime.now().millisecondsSinceEpoch;

    return SimpleTimestampTimer._(
      Timer.periodic(interval, (timer) {
        final endTime = DateTime.now().millisecondsSinceEpoch - startTime;

        if (endTime >= duration.inMilliseconds) {
          timer.cancel();
          callback.call();
        }
      }),
    );
  }

  @override
  void cancel() {
    timer.cancel();
  }

  @override
  bool get isActive => timer.isActive;

  @override
  int get tick => timer.tick;
}

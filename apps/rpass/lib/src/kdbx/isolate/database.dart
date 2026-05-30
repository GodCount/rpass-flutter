import 'dart:async';
import 'dart:isolate';

import 'package:kpasslib/kpasslib.dart';

import '../field_statistic.dart';
import 'event.dart';
import 'kdbx_isolate.dart';

class IsolateDataBase {
  IsolateDataBase._(this._isolate, this._receivePort, this._sendPort) {
    _receivePort.handler = _handler;
  }

  final Isolate _isolate;
  final RawReceivePort _receivePort;
  final SendPort _sendPort;

  bool _close = false;
  bool get isClose => _close;

  FieldStatistic _fieldStatistic = FieldStatistic();
  FieldStatistic get fieldStatistic => _fieldStatistic;

  Map<String, KdbxCustomIcon> _customIcons = {};
  Map<String, KdbxCustomIcon> get customIcons => _customIcons;

  Map<int, KdbxDataBinary> _binaries = {};
  Map<int, KdbxDataBinary> get binaries => _binaries;

  static Future<IsolateDataBase> create({
    required String name,
    required String savepath,
    required KdbxCredentials credentials,
  }) {
    return _initialization(
      CreateKdbxIsolateInitState(
        name: name,
        filepath: savepath,
        credentials: credentials,
      ),
    );
  }

  static Future<IsolateDataBase> fromFile({
    required String filepath,
    required KdbxCredentials credentials,
  }) {
    return _initialization(
      OpenKdbxIsolateInitState(filepath: filepath, credentials: credentials),
    );
  }

  static Future<IsolateDataBase> _initialization(
    OpenKdbxIsolateInitState state,
  ) async {
    final receive = RawReceivePort();
    final completer = Completer<IsolateDataBase>();

    Isolate? isolate;

    receive.handler = (response) {
      if (response == null) {
        receive.close();
        completer.completeError(
          RemoteError("Initialization failed", ""),
          StackTrace.empty,
        );
        return;
      }

      if (isolate == null) {
        receive.close();
        return completer.completeError(StateError("isolate is null"));
      }

      if (response is SendPort) {
        completer.complete(IsolateDataBase._(isolate, receive, response));
      } else if (response is List<Object?>) {
        final remoteError = response[0];
        final remoteStack = response[1];
        if (remoteStack is StackTrace) {
          completer.completeError(remoteError!, remoteStack);
        } else {
          final error = RemoteError(
            remoteError.toString(),
            remoteStack.toString(),
          );
          completer.completeError(error, error.stackTrace);
        }
      } else {
        completer.completeError(response);
      }
    };

    try {
      isolate = await Isolate.spawn(
        kdbxIsolate,
        (receive.sendPort, state),
        onError: receive.sendPort,
        onExit: receive.sendPort,
      );
    } catch (e, s) {
      receive.close();
      completer.completeError(e, s);
    }

    final db = await completer.future;

    await db._init();

    return db;
  }

  Future<T?> _sendEvent<T>(KdbxIsolateEvent<T> event) {
    _sendPort.send(event);
    return event.future;
  }

  Future<void> _init() async {
    await _getFieldStatistic();
    await _getCustomIcon();
    await _getBinaries();
  }

  Future<void> _getFieldStatistic() async {
    try {
      final result = await _sendEvent(FieldStatisticEvent());
      _fieldStatistic = result ?? _fieldStatistic;
    } catch (e) {
      print(e);
    }
  }

  Future<void> _getCustomIcon() async {
    try {
      final result = await _sendEvent(CustomIconsEvent());
      _customIcons = result ?? _customIcons;
    } catch (e) {
      print(e);
    }
  }

  Future<void> _getBinaries() async {
    try {
      final result = await _sendEvent(DataBinaryEvent());
      _binaries = result ?? _binaries;
    } catch (e) {
      print(e);
    }
  }

  void _handler(dynamic response) {
    if (response is KdbxIsolateEvent) {
      response.complete();
    } else if (response is List<Object?>) {
      // onError handler message, uncaught async error.
      print("unknown $response");
      close();
    } else {
      print("unknown $response");
    }
  }

  Future<void> close() async {
    if (!_close) {
      _close = true;
      _sendPort.send(null);
      _receivePort.close();
      _isolate.kill(priority: Isolate.immediate);
    }
  }
}

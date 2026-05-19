import 'dart:async';
import 'dart:isolate';

import 'package:kpasslib/kpasslib.dart';

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

    return completer.future;
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

  void close() {
    if (!_close) {
      _close = true;
      _receivePort.close();
      _isolate.kill(priority: Isolate.immediate);
    }
  }
}

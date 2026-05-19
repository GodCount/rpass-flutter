import 'dart:io';
import 'dart:isolate';

import 'package:kpasslib/kpasslib.dart';

class OpenKdbxIsolateInitState {
  OpenKdbxIsolateInitState({
    required this.filepath,
    required this.credentials,
  });

  final String filepath;

  final KdbxCredentials credentials;

  Future<KdbxDatabase> _open() {
    return KdbxDatabase.fromBytes(
      data: File(filepath).readAsBytesSync(),
      credentials: credentials,
    );
  }
}

class CreateKdbxIsolateInitState extends OpenKdbxIsolateInitState {
  CreateKdbxIsolateInitState({
    required super.filepath,
    required super.credentials,
    required this.name,
  });

  final String name;

  @override
  Future<KdbxDatabase> _open() async {
    return KdbxDatabase.create(
      credentials: credentials,
      name: name,
    );
  }
}

void kdbxIsolate((SendPort, OpenKdbxIsolateInitState) data) async {
  final receive = RawReceivePort();

  final (sendPort, state) = data;

  KdbxDatabase db;

  try {
    db = await state._open();
  } catch (e, s) {
    Isolate.exit(sendPort, List.filled(2, e)..[1] = s);
  }

  sendPort.send(receive.sendPort);

  receive.handler = (request) {};
}

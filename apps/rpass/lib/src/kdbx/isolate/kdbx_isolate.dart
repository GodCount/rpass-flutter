import 'dart:io';
import 'dart:isolate';

import 'package:kpasslib/kpasslib.dart';

import '../field_statistic.dart';
import '../search_handler.dart';
import 'event.dart';

class OpenKdbxIsolateInitState {
  OpenKdbxIsolateInitState({required this.filepath, required this.credentials});

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
    return KdbxDatabase.create(credentials: credentials, name: name);
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

  final fieldStatistic = FieldStatistic.formDB(db);
  final searchHandler = KbdxSearchHandler()
    ..setFieldOther(fieldStatistic.customFields);

  receive.handler = (request) async {
    if (request is KdbxIsolateEvent) {
      try {
        switch (request) {
          case GeneralHandler req:
            await req.handler(db);
            break;
          case SreachEntryEvent req:
            await req.handler(db, searchHandler);
            break;
          case FieldStatisticEvent req:
            await req.handler(fieldStatistic);
            break;
          default:
            request.error = (
              UnimplementedError("event ${request.runtimeType}"),
              StackTrace.current,
            );
        }
      } catch (e, s) {
        request.error = (e, s);
      }

      sendPort.send(request);
    }else {
      print("exit");
      Isolate.exit();
    }
  };
}

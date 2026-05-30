import 'dart:io';

import 'package:kpasslib/kpasslib.dart';

import 'database.dart';

void main() async {
  print("PID $pid");

  final db = await IsolateDataBase.fromFile(
    filepath:
        "C:\\Users\\do_yz\\AppData\\Roaming\\com.godcount\\Rpass(Profile)\\kdbx\\default.kdbx",
    credentials: KdbxCredentials(password: ProtectedData.fromString('1111')),
  );

  await Future.delayed(Duration(seconds: 1));

  print("open db done.");

  db.close();

  await Future.delayed(Duration(seconds: 1));

  print("close db done.");
}

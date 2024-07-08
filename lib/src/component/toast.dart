import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<void> showToast(BuildContext context, String msg) async {
  if (Platform.isAndroid || Platform.isIOS) {
    await Fluttertoast.showToast(msg: msg);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
    ));
  }
}

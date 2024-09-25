import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rpass/src/i18n.dart';

Future<void> showToast(BuildContext context, String msg) async {
  if (Platform.isAndroid || Platform.isIOS) {
    await Fluttertoast.showToast(msg: msg);
  } else {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(I18n.of(context)!.confirm),
            )
          ],
        );
      },
    );
  }
}

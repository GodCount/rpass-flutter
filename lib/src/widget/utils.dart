import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../component/toast.dart';
import '../i18n.dart';

mixin HintEmptyTextUtil<T extends StatefulWidget> on State<T> {
  Widget hintEmptyText(bool isEmpty, Widget widget) {
    return isEmpty
        ? Opacity(
            opacity: .5,
            child: Text(
              I18n.of(context)!.empty,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        : widget;
  }
}

mixin CommonWidgetUtil<T extends StatefulWidget> on State<T> {
  void writeClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((value) {
      showToast(context, I18n.of(context)!.copy_done);
    }, onError: (error) {
      showToast(context, error.toString());
    });
  }
}

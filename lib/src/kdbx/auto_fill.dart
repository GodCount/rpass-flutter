import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:enigo_flutter/enigo_flutter.dart';

import '../native/channel.dart';
import 'kdbx.dart';

final _logger = Logger("kdbx:auto_fill");

bool _runing = false;

class NoPermission implements Exception {
  NoPermission(this.message);

  final String message;

  @override
  String toString() {
    return 'NoPermission{message: $message}';
  }
}

Future<void> autoFillSequence(KdbxEntry kdbxEntry, [KdbxKey? kdbxKey]) async {
  if (!Platform.isMacOS && !Platform.isWindows) return;

  if (NativeInstancePlatform.instance.targetAppName != null) {
    // 在运行中不要重复触发
    if (_runing) {
      debugPrint("[auto fill runing]");
      return;
    }
    _runing = true;

    try {
      if (await NativeInstancePlatform.instance.activatePrevWindow()) {
        final List<TextSequenceItem> items;

        if (kdbxKey != null) {
          // 填充单个字段
          items = [KdbxSequenceItem(kdbxKey.key)];
        } else {
          items = AutoTypeSequenceParse.parse(kdbxEntry.getAutoTypeSequence())
              .items;
        }

        debugPrint("[start auto fill]");
        for (final item in items) {
          if (item is ButtonSequenceItem) {
            if (item.button != null) {
              debugPrint("[ButtonSequenceItem] ${item.button!.debugName}");
              enigo.key(key: item.button!, direction: Direction.click);
            }
          } else if (item is ShortcutSequenceItem) {
            for (final key in item.modifiers) {
              debugPrint(
                "[ShortcutSequenceItem][modifiers][press] ${key.debugName}",
              );

              enigo.key(key: key, direction: Direction.press);
            }

            debugPrint(
              "[ShortcutSequenceItem][key][click] ${item.key.debugName}",
            );

            enigo.key(key: item.key, direction: Direction.click);

            for (final key in item.modifiers) {
              debugPrint(
                "[ShortcutSequenceItem][modifiers][release] ${key.debugName}",
              );
              enigo.key(key: key, direction: Direction.release);
            }
          } else if (item is KdbxSequenceItem) {
            final text = kdbxEntry.getActualString(KdbxKey(item.key));

            if (text != null && text.isNotEmpty) {
              debugPrint("[KdbxSequenceItem] ${item.key}");
              enigo.text(text: text);
            }
          } else {
            debugPrint("[TextSequenceItem] ${item.value}");
            enigo.text(text: item.value);
          }
          await Future.delayed(const Duration(milliseconds: 60));
        }
      }
    } catch (e) {
      if (e.toString().contains("NoPermission")) {
        throw NoPermission("Missing auxiliary permissions");
      }
      _logger.warning("fill fail", e);
      rethrow;
    } finally {
      _runing = false;
    }
  }
}

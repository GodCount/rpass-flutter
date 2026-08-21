import 'package:common_native_channel/common_native_channel.dart';
import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart';

import '../util/common.dart';
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

typedef GetValueByKey = String? Function(String key);

Future<bool> _ensureTargetFocus() async {
  if (prevFocusWindow.targetWindowName != null) {
    return await prevFocusWindow.activatePrevWindow();
  } else if (await windowManager.isFocused()) {
    await windowManager.blur();
    await Future.delayed(Duration(milliseconds: 300));
    return true;
  }
  return false;
}

///
/// 桌面端 以模拟键盘输入的方式自动填充信息
///
///
Future<void> autoFillSequence(
  String sequence, {
  required GetValueByKey getValue,
  // 存在则只填充这个字段
  String? key,
}) async {
  if (!kIsDesktop) return;

  // 在运行中不要重复触发
  if (_runing) {
    debugPrint("[auto fill runing]");
    return;
  }
  _runing = true;

  try {
    if (await _ensureTargetFocus()) {
      final List<TextSequenceItem> items;

      if (key != null) {
        // 填充单个字段
        items = [KdbxSequenceItem(key)];
      } else {
        items = AutoTypeSequenceParse.parse(sequence).items;
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
          final text = getValue(item.key);

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

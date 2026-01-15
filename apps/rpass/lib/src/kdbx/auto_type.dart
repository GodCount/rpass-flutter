import 'package:flutter/services.dart';

/// interface https://keepass.info/help/base/autotype.html

class AutoTypeKeys {
  static const BUTTON = [
    "{TAB}",
    "{ENTER}",
    "{UP}",
    "{DOWN}",
    "{LEFT}",
    "{RIGHT}",
    "{INSERT}",
    "{DELETE}",
    "{HOME}",
    "{END}",
    "{PGUP}",
    "{PGDN}",
    "{SPACE}",
    "{BACKSPACE}",
    "{BREAK}",
    "{CAPSLOCK}",
    "{ESC}",
    "{WIN}",
    "{LWIN}",
    "{RWIN}",
    "{APPS}",
    "{HELP}",
    "{NUMLOCK}",
    "{PRTSC}",
    "{SCROLLLOCK}",
    "{F1}",
    "{F2}",
    "{F3}",
    "{F4}",
    "{F5}",
    "{F6}",
    "{F7}",
    "{F8}",
    "{F9}",
    "{F10}",
    "{F11}",
    "{F12}",
    "{F13}",
    "{F14}",
    "{F15}",
    "{F16}",
    "{ADD}",
    "{SUBTRACT}",
    "{MULTIPLY}",
    "{DIVIDE}",
    "{NUMPAD0}",
    "{NUMPAD1}",
    "{NUMPAD2}",
    "{NUMPAD3}",
    "{NUMPAD4}",
    "{NUMPAD5}",
    "{NUMPAD6}",
    "{NUMPAD7}",
    "{NUMPAD8}",
    "{NUMPAD9}",
  ];
}

class AutoTypeRichPattern {
  static const BUTTON = r"({("
      r"TAB|ENTER|UP|DOWN|LEFT|RIGHT|INSERT|INS|DELETE|DEL|"
      r"HOME|END|PGUP|PGDN|SPACE|BACKSPACE|BS|BKSP|BREAK|CAPSLOCK|"
      r"ESC|WIN|LWIN|RWIN|APPS|HELP|NUMLOCK|PRTSC|SCROLLLOCK|(F(1[0-6]|[1-9]))|"
      r"ADD|SUBTRACT|MULTIPLY|DIVIDE|(NUMPAD[0-9])"
      r")})"
      r"|~";

  // TODO! 需要修复重复出现的问题
  static const SHORTCUT_KEY = r"[%^+]{1,3}[a-zA-Z\d]";

  static const KDBX_KEY =
      r"({(Title|URL|UserName|Email|Password|OTPAuth|Notes)})"
      r"|({S:(.*?)})";

  static const _ALL = "($BUTTON)|($SHORTCUT_KEY)|($KDBX_KEY)";
}

class TextSequenceItem {
  TextSequenceItem(this.value);

  final String value;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TextSequenceItem && other.value == value;
  }

  @override
  String toString() {
    return "TextSequenceItem{value=$value}";
  }
}

class ButtonSequenceItem extends TextSequenceItem {
  ButtonSequenceItem(super.value)
      : button = switch (value) {
          "TAB" => PhysicalKeyboardKey.tab,
          "ENTER" || "~" => PhysicalKeyboardKey.enter,
          "UP" => PhysicalKeyboardKey.arrowUp,
          "DOWN" => PhysicalKeyboardKey.arrowDown,
          "LEFT" => PhysicalKeyboardKey.arrowLeft,
          "RIGHT" => PhysicalKeyboardKey.arrowRight,
          "INSERT" || "INS" => PhysicalKeyboardKey.insert,
          "DELETE" || "DEL" => PhysicalKeyboardKey.delete,
          "HOME" => PhysicalKeyboardKey.home,
          "END" => PhysicalKeyboardKey.end,
          "PGUP" => PhysicalKeyboardKey.pageUp,
          "PGDN" => PhysicalKeyboardKey.pageDown,
          "SPACE" => PhysicalKeyboardKey.space,
          "BACKSPACE" || "BS" || "BKSP" => PhysicalKeyboardKey.backspace,
          "BREAK" => PhysicalKeyboardKey.pause,
          "CAPSLOCK" => PhysicalKeyboardKey.capsLock,
          "ESC" => PhysicalKeyboardKey.escape,
          "WIN" || "LWIN" => PhysicalKeyboardKey.metaLeft,
          "RWIN" => PhysicalKeyboardKey.metaRight,
          "HELP" => PhysicalKeyboardKey.help,
          "NUMLOCK" => PhysicalKeyboardKey.numLock,
          "PRTSC" => PhysicalKeyboardKey.printScreen,
          "SCROLLLOCK" => PhysicalKeyboardKey.scrollLock,
          "F1" => PhysicalKeyboardKey.f1,
          "F2" => PhysicalKeyboardKey.f2,
          "F3" => PhysicalKeyboardKey.f3,
          "F4" => PhysicalKeyboardKey.f4,
          "F5" => PhysicalKeyboardKey.f5,
          "F6" => PhysicalKeyboardKey.f6,
          "F7" => PhysicalKeyboardKey.f7,
          "F8" => PhysicalKeyboardKey.f8,
          "F9" => PhysicalKeyboardKey.f9,
          "F10" => PhysicalKeyboardKey.f10,
          "F11" => PhysicalKeyboardKey.f11,
          "F12" => PhysicalKeyboardKey.f12,
          "F13" => PhysicalKeyboardKey.f13,
          "F14" => PhysicalKeyboardKey.f14,
          "F15" => PhysicalKeyboardKey.f15,
          "F16" => PhysicalKeyboardKey.f16,
          "ADD" => PhysicalKeyboardKey.numpadAdd,
          "SUBTRACT" => PhysicalKeyboardKey.numpadSubtract,
          "MULTIPLY" => PhysicalKeyboardKey.numpadMultiply,
          "DIVIDE" => PhysicalKeyboardKey.numpadDivide,
          "NUMPAD0" => PhysicalKeyboardKey.numpad0,
          "NUMPAD1" => PhysicalKeyboardKey.numpad1,
          "NUMPAD2" => PhysicalKeyboardKey.numpad2,
          "NUMPAD3" => PhysicalKeyboardKey.numpad3,
          "NUMPAD4" => PhysicalKeyboardKey.numpad4,
          "NUMPAD5" => PhysicalKeyboardKey.numpad5,
          "NUMPAD6" => PhysicalKeyboardKey.numpad6,
          "NUMPAD7" => PhysicalKeyboardKey.numpad7,
          "NUMPAD8" => PhysicalKeyboardKey.numpad8,
          "NUMPAD9" => PhysicalKeyboardKey.numpad9,
          // 不清楚对应的键
          "APPS" => null,
          _ => null,
        };

  factory ButtonSequenceItem.parse(String value) {
    return ButtonSequenceItem(
      value != "~" ? value.substring(1, value.length - 1) : value,
    );
  }

  final PhysicalKeyboardKey? button;

  @override
  int get hashCode => button.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ButtonSequenceItem && other.button == button;
  }

  @override
  String toString() {
    return "ButtonSequenceItem{value=$value,button=$button}";
  }
}

class ShortcutSequenceItem extends TextSequenceItem {
  ShortcutSequenceItem(
    super.value, {
    required this.modifiers,
    required this.key,
  });

  static PhysicalKeyboardKey? _findKeyByCode(String char) {
    final code = char.toLowerCase().codeUnitAt(0);
    if (code >= 97 && code <= 122) {
      return PhysicalKeyboardKey.findKeyByCode(code + 458659);
    } else if (code >= 49 && code <= 57) {
      return PhysicalKeyboardKey.findKeyByCode(code + 458733);
    } else if (code == 48) {
      return PhysicalKeyboardKey.digit0;
    }
    return null;
  }

  factory ShortcutSequenceItem.parse(String value) {
    final values = value
        .split("")
        .map((item) => switch (item) {
              "^" => PhysicalKeyboardKey.controlLeft,
              "+" => PhysicalKeyboardKey.shiftLeft,
              "%" => PhysicalKeyboardKey.altLeft,
              _ => _findKeyByCode(item)
            })
        .whereType<PhysicalKeyboardKey>()
        .toSet()
        .toList();

    if (values.length > 4) {
      throw Exception("exceeded length $value");
    }

    return ShortcutSequenceItem(
      value,
      modifiers: values.sublist(0, values.length - 1)
        ..sort((a, b) => a.usbHidUsage - b.usbHidUsage),
      key: values.last,
    );
  }

  final List<PhysicalKeyboardKey> modifiers;
  final PhysicalKeyboardKey key;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ShortcutSequenceItem && other.value == value;
  }

  @override
  String toString() {
    return "ShortcutSequenceItem{value=$value,key=$key,modifiers=$modifiers}";
  }
}

class KdbxSequenceItem extends TextSequenceItem {
  KdbxSequenceItem(super.value);

  String get key =>
      value.startsWith("S:") ? value.replaceFirst("S:", "") : value;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is KdbxSequenceItem && other.value == value;
  }

  @override
  String toString() {
    return "KdbxSequenceItem{value=$value,key=$key}";
  }
}

class AutoTypeSequenceParse {
  AutoTypeSequenceParse(this.items);

  final List<TextSequenceItem> items;

  factory AutoTypeSequenceParse.parse(String value) {
    return AutoTypeSequenceParse(_parse(value));
  }

  static List<TextSequenceItem> _parse(String text) {
    final List<TextSequenceItem> items = [];

    final regexp = RegExp(AutoTypeRichPattern._ALL);

    final allMatches = regexp.allMatches(text);

    int lastMatchEnd = 0;

    for (final item in allMatches) {
      final matchStart = item.start;
      final matchEnd = item.end;

      if (matchStart < 0 || matchEnd > text.length) continue;

      if (matchStart > lastMatchEnd) {
        final nonMatchText = text.substring(lastMatchEnd, matchStart);
        items.add(TextSequenceItem(nonMatchText));
      }

      final matchText = item.group(0)!;

      items.add(_createTextSequenceItem(matchText));

      lastMatchEnd = matchEnd;
    }

    if (lastMatchEnd < text.length) {
      final remainingText = text.substring(lastMatchEnd);
      items.add(TextSequenceItem(remainingText));
    }

    return items;
  }

  static TextSequenceItem _createTextSequenceItem(String value) {
    if (RegExp(AutoTypeRichPattern.BUTTON).hasMatch(value)) {
      return ButtonSequenceItem.parse(value);
    } else if (RegExp(AutoTypeRichPattern.SHORTCUT_KEY).hasMatch(value)) {
      return ShortcutSequenceItem.parse(value);
    } else if (RegExp(AutoTypeRichPattern.KDBX_KEY).hasMatch(value)) {
      return KdbxSequenceItem(value.substring(1, value.length - 1));
    }
    return TextSequenceItem(value);
  }
}

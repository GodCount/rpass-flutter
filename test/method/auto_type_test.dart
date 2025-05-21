import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpass/src/kdbx/auto_type.dart';

void main() {
  group("Auto Type Pattern", () {
    test("BUTTON", () {
      final pattern = RegExp(AutoTypeRichPattern.BUTTON);
      expect(pattern.hasMatch("{UserName}{TAB}{Password}{ENTER}"), isTrue);
      expect(pattern.hasMatch("{UserName}{Password}"), isFalse);
      expect(pattern.hasMatch("{TAb}{Password}{ENTEr}"), isFalse);

      expect(pattern.hasMatch("~"), isTrue);

      expect(pattern.hasMatch("{F1}}"), isTrue);
      expect(pattern.hasMatch("{F17}"), isFalse);
      expect(pattern.hasMatch("{NUMPAD}"), isFalse);
      expect(pattern.hasMatch("{NUMPAD9}"), isTrue);
    });

    test("SHORTCUT_KEY", () {
      final pattern = RegExp(AutoTypeRichPattern.SHORTCUT_KEY);
      expect(pattern.hasMatch("^a"), isTrue);
      expect(pattern.hasMatch("^%+ac"), isTrue);

      expect(pattern.stringMatch("^%%+aas") == "%+a", isTrue);
      expect(pattern.stringMatch("^^^ac^ ") == "^a", isTrue);
    });

    test("KDBX_KEY", () {
      final pattern = RegExp(AutoTypeRichPattern.KDBX_KEY);
      expect(pattern.hasMatch("{Title}{}"), isTrue);
      expect(pattern.hasMatch("{S:aaa}"), isTrue);

      // expect(pattern.hasMatch("{S:Title}"), isFalse);
    });
  });

  group("Auto Type Parse", () {
    test("Sequence Item", () {
      expect(TextSequenceItem("aa").value, equals("aa"));

      expect(ButtonSequenceItem(""), isA<ButtonSequenceItem>());

      expect(ButtonSequenceItem("").button, isNull);

      expect(ButtonSequenceItem("TAB").button, equals(PhysicalKeyboardKey.tab));

      expect(ButtonSequenceItem("~").button, equals(PhysicalKeyboardKey.enter));

      expect(ButtonSequenceItem("~"), equals(ButtonSequenceItem("ENTER")));

      expect(
        ButtonSequenceItem("BS").button,
        equals(PhysicalKeyboardKey.backspace),
      );

      expect(PhysicalKeyboardKey.findKeyByCode(97 + 458659),
          equals(PhysicalKeyboardKey.keyA));

      expect(ShortcutSequenceItem.parse("^a").key,
          equals(PhysicalKeyboardKey.keyA));

      expect(ShortcutSequenceItem.parse("^z").key,
          equals(PhysicalKeyboardKey.keyZ));

      expect(ShortcutSequenceItem.parse("^1").key,
          equals(PhysicalKeyboardKey.digit1));

      expect(ShortcutSequenceItem.parse("^9").key,
          equals(PhysicalKeyboardKey.digit9));

      expect(ShortcutSequenceItem.parse("^0").key,
          equals(PhysicalKeyboardKey.digit0));

      expect(ShortcutSequenceItem.parse("^a").modifiers,
          equals([PhysicalKeyboardKey.controlLeft]));

      expect(
        ShortcutSequenceItem.parse("%^+a").modifiers,
        equals([
          PhysicalKeyboardKey.controlLeft,
          PhysicalKeyboardKey.shiftLeft,
          PhysicalKeyboardKey.altLeft,
        ]),
      );

      expect(KdbxSequenceItem("Title").key, equals("Title"));

      expect(KdbxSequenceItem("S:Custom").key, equals("Custom"));

      expect(
          KdbxSequenceItem("S:Custom:S:Custom").key, equals("Custom:S:Custom"));
    });

    test("Sequence Parse", () {
      // expect(
      //   AutoTypeSequenceParse.parse("{UserName}{TAB}{Password}{ENTER}").items,
      //   equals([
      //     KdbxSequenceItem("UserName"),
      //     ButtonSequenceItem("TAB"),
      //     KdbxSequenceItem("Password"),
      //     ButtonSequenceItem("ENTER"),
      //   ]),
      // );

      expect(
        AutoTypeSequenceParse.parse("aa{TAB}{Password}^a~%{c}").items,
        equals([
          TextSequenceItem("aa"),
          ButtonSequenceItem("TAB"),
          KdbxSequenceItem("Password"),
          ShortcutSequenceItem.parse("^a"),
          ButtonSequenceItem("ENTER"),
          TextSequenceItem("%{c}"),
        ]),
      );
    });
  });
}

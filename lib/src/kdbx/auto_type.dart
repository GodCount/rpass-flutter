// ignore: dangling_library_doc_comments
/// interface https://keepass.info/help/base/autotype.html

// const buttons = [
//   "{TAB}",
//   "{ENTER}", "~",
//   "{UP}",
//   "{DOWN}",
//   "{LEFT}",
//   "{RIGHT}",
//   "{INSERT}", "{INS}",
//   "{DELETE}", "{DEL}",
//   "{HOME}",
//   "{END}",
//   "{PGUP}",
//   "{PGDN}",
//   "{SPACE}",
//   "{BACKSPACE}", "{BS}", "{BKSP}",
//   "{BREAK}",
//   "{CAPSLOCK}",
//   "{ESC}",
//   "{WIN}", "{LWIN}",
//   "{RWIN}",
//   "{APPS}",
//   "{HELP}",
//   "{NUMLOCK}",
//   "{PRTSC}",
//   "{SCROLLLOCK}",
//   "{F1}", "{F2}", "{F3}", "{F4}", "{F5}", "{F6}", "{F7}", "{F8}", "{F9}",
//   "{F10}", "{F11}", "{F12}", "{F13}", "{F14}", "{F15}", "{F16}",
//   // +
//   "{ADD}",
//   // -
//   "{SUBTRACT}",
//   // *
//   "{MULTIPLY}",
//   // /
//   "{DIVIDE}",
//   "{NUMPAD0}", "{NUMPAD1}", "{NUMPAD2}", "{NUMPAD3}", "{NUMPAD4}", "{NUMPAD5}",
//   "{NUMPAD6}", "{NUMPAD7}", "{NUMPAD8}", "{NUMPAD9}",
//   // Shift
//   "+",
//   // Ctrl
//   "^",
//   // Alt
//   "%",
//   "{+}",
//   "{%}",
//   "{^}",
//   "{)}", "{(}",
//   "{[}", "{]}",
//   "{{}", "{}}",
// ];

class AutoTypeRichPattern {
  static final button = RegExp(
    r"{"
    r"TAB|ENTER|UP|DOWN|LEFT|RIGHT|INSERT|INS|DELETE|DEL|"
    r"HOME|END|PGUP|PGDN|SPACE|BACKSPACE|BS|BKSP|BREAK|CAPSLOCK|"
    r"ESC|WIN|LWIN|RWIN|APPS|HELP|NUMLOCK|PRTSC|SCROLLLOCK|(F(0|1[0-6]|[1-9]))|"
    r"ADD|SUBTRACT|MULTIPLY|DIVIDE|(NUMPAD[0-9])"
    r"}"
    r"|~",
  );
  static final shortcut_key = RegExp(r"");
  static final kdbx_key = RegExp(r"");
}

class AutoTypeParse {}

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
    "{WIN}", "{LWIN}",
    "{RWIN}",
    "{APPS}",
    "{HELP}",
    "{NUMLOCK}",
    "{PRTSC}",
    "{SCROLLLOCK}",
    "{F1}", "{F2}", "{F3}", "{F4}", "{F5}", "{F6}", "{F7}", "{F8}", "{F9}",
    "{F10}", "{F11}", "{F12}", "{F13}", "{F14}", "{F15}", "{F16}",
    // +
    "{ADD}",
    // -
    "{SUBTRACT}",
    // *
    "{MULTIPLY}",
    // /
    "{DIVIDE}",
    "{NUMPAD0}", "{NUMPAD1}", "{NUMPAD2}", "{NUMPAD3}", "{NUMPAD4}",
    "{NUMPAD5}",
    "{NUMPAD6}", "{NUMPAD7}", "{NUMPAD8}", "{NUMPAD9}",
  ];
}

class AutoTypeRichPattern {
  static const BUTTON = r"({("
      r"TAB|ENTER|UP|DOWN|LEFT|RIGHT|INSERT|INS|DELETE|DEL|"
      r"HOME|END|PGUP|PGDN|SPACE|BACKSPACE|BS|BKSP|BREAK|CAPSLOCK|"
      r"ESC|WIN|LWIN|RWIN|APPS|HELP|NUMLOCK|PRTSC|SCROLLLOCK|(F(0|1[0-6]|[1-9]))|"
      r"ADD|SUBTRACT|MULTIPLY|DIVIDE|(NUMPAD[0-9])"
      r")})"
      r"|~";

  static const SHORTCUT_KEY = r"([+^%]){1,3}[a-zA-Z\d]";

  static const KDBX_KEY = r"({(Title|URL|UserName|Email|Password|OTPAuth|Notes)})"
      r"|({S:(.*?)})";
}

class AutoTypeParse {}

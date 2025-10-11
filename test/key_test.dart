import 'dart:io';

import 'package:enigo_flutter/src/rust/api/enigo.dart';
import 'package:enigo_flutter/src/rust/frb_generated.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';

///
/// [https://github.com/flutter/flutter/blob/master/dev/tools/gen_keycodes/data/physical_key_data.g.json]
/// 从 physical_key_data 提取的不支持键值
///
const macosUnpportKeys = [
// Hyper
  16,
// Super
  17,
// FnLock
  19,
// Suspend
  20,
// Resume
  21,
// Turbo
  22,
// PrivacyScreenToggle
  23,
// MicrophoneMuteToggle
  24,
// Sleep
  65666,
// WakeUp
  65667,
// DisplayToggleIntExt
  65717,
// GameButton1
  392961,
// GameButton2
  392962,
// GameButton3
  392963,
// GameButton4
  392964,
// GameButton5
  392965,
// GameButton6
  392966,
// GameButton7
  392967,
// GameButton8
  392968,
// GameButton9
  392969,
// GameButton10
  392970,
// GameButton11
  392971,
// GameButton12
  392972,
// GameButton13
  392973,
// GameButton14
  392974,
// GameButton15
  392975,
// GameButton16
  392976,
// GameButtonA
  392977,
// GameButtonB
  392978,
// GameButtonC
  392979,
// GameButtonLeft1
  392980,
// GameButtonLeft2
  392981,
// GameButtonMode
  392982,
// GameButtonRight1
  392983,
// GameButtonRight2
  392984,
// GameButtonSelect
  392985,
// GameButtonStart
  392986,
// GameButtonThumbLeft
  392987,
// GameButtonThumbRight
  392988,
// GameButtonX
  392989,
// GameButtonY
  392990,
// GameButtonZ
  392991,
// UsbReserved
  458752,
// UsbErrorRollOver
  458753,
// UsbPostFail
  458754,
// UsbErrorUndefined
  458755,
// PrintScreen
  458822,
// ScrollLock
  458823,
// Pause
  458824,
// Power
  458854,
// F21
  458864,
// F22
  458865,
// F23
  458866,
// F24
  458867,
// Open
  458868,
// Help
  458869,
// Select
  458871,
// Again
  458873,
// Undo
  458874,
// Cut
  458875,
// Copy
  458876,
// Paste
  458877,
// Find
  458878,
// KanaMode
  458888,
// Convert
  458890,
// NonConvert
  458891,
// Lang3
  458898,
// Lang4
  458899,
// Lang5
  458900,
// Abort
  458907,
// Props
  458915,
// NumpadParenLeft
  458934,
// NumpadParenRight
  458935,
// NumpadBackspace
  458939,
// NumpadMemoryStore
  458960,
// NumpadMemoryRecall
  458961,
// NumpadMemoryClear
  458962,
// NumpadMemoryAdd
  458963,
// NumpadMemorySubtract
  458964,
// NumpadSignChange
  458967,
// NumpadClear
  458968,
// NumpadClearEntry
  458969,
// Info
  786528,
// ClosedCaptionToggle
  786529,
// BrightnessUp
  786543,
// BrightnessDown
  786544,
// BrightnessToggle
  786546,
// BrightnessMinimum
  786547,
// BrightnessMaximum
  786548,
// BrightnessAuto
  786549,
// KbdIllumUp
  786553,
// KbdIllumDown
  786554,
// MediaLast
  786563,
// LaunchPhone
  786572,
// ProgramGuide
  786573,
// Exit
  786580,
// ChannelUp
  786588,
// ChannelDown
  786589,
// MediaPlay
  786608,
// MediaPause
  786609,
// MediaRecord
  786610,
// MediaFastForward
  786611,
// MediaRewind
  786612,
// MediaTrackNext
  786613,
// MediaTrackPrevious
  786614,
// MediaStop
  786615,
// Eject
  786616,
// MediaPlayPause
  786637,
// SpeechInputToggle
  786639,
// BassBoost
  786661,
// MediaSelect
  786819,
// LaunchWordProcessor
  786820,
// LaunchSpreadsheet
  786822,
// LaunchMail
  786826,
// LaunchContacts
  786829,
// LaunchCalendar
  786830,
// LaunchApp2
  786834,
// LaunchApp1
  786836,
// LaunchInternetBrowser
  786838,
// LogOff
  786844,
// LockScreen
  786846,
// LaunchControlPanel
  786847,
// SelectTask
  786850,
// LaunchDocuments
  786855,
// SpellCheck
  786859,
// LaunchKeyboardLayout
  786862,
// LaunchScreenSaver
  786865,
// LaunchAudioBrowser
  786871,
// LaunchAssistant
  786891,
// New
  786945,
// Close
  786947,
// Save
  786951,
// Print
  786952,
// BrowserSearch
  786977,
// BrowserHome
  786979,
// BrowserBack
  786980,
// BrowserForward
  786981,
// BrowserStop
  786982,
// BrowserRefresh
  786983,
// BrowserFavorites
  786986,
// ZoomIn
  786989,
// ZoomOut
  786990,
// ZoomToggle
  786994,
// Redo
  787065,
// MailReply
  787081,
// MailForward
  787083,
// MailSend
  787084,
// KeyboardLayoutSelect
  787101,
// ShowAllWindows
  787103,
];
const windowsUnpportKeys = [
// Hyper
  16,
// Super
  17,
// Fn
  18,
// FnLock
  19,
// Suspend
  20,
// Resume
  21,
// Turbo
  22,
// PrivacyScreenToggle
  23,
// MicrophoneMuteToggle
  24,
// DisplayToggleIntExt
  65717,
// GameButton1
  392961,
// GameButton2
  392962,
// GameButton3
  392963,
// GameButton4
  392964,
// GameButton5
  392965,
// GameButton6
  392966,
// GameButton7
  392967,
// GameButton8
  392968,
// GameButton9
  392969,
// GameButton10
  392970,
// GameButton11
  392971,
// GameButton12
  392972,
// GameButton13
  392973,
// GameButton14
  392974,
// GameButton15
  392975,
// GameButton16
  392976,
// GameButtonA
  392977,
// GameButtonB
  392978,
// GameButtonC
  392979,
// GameButtonLeft1
  392980,
// GameButtonLeft2
  392981,
// GameButtonMode
  392982,
// GameButtonRight1
  392983,
// GameButtonRight2
  392984,
// GameButtonSelect
  392985,
// GameButtonStart
  392986,
// GameButtonThumbLeft
  392987,
// GameButtonThumbRight
  392988,
// GameButtonX
  392989,
// GameButtonY
  392990,
// GameButtonZ
  392991,
// UsbReserved
  458752,
// UsbErrorUndefined
  458755,
// Open
  458868,
// Select
  458871,
// Again
  458873,
// Find
  458878,
// Lang5
  458900,
// Abort
  458907,
// Props
  458915,
// NumpadParenLeft
  458934,
// NumpadParenRight
  458935,
// NumpadBackspace
  458939,
// NumpadMemoryStore
  458960,
// NumpadMemoryRecall
  458961,
// NumpadMemoryClear
  458962,
// NumpadMemoryAdd
  458963,
// NumpadMemorySubtract
  458964,
// NumpadSignChange
  458967,
// NumpadClear
  458968,
// NumpadClearEntry
  458969,
// Info
  786528,
// ClosedCaptionToggle
  786529,
// BrightnessUp
  786543,
// BrightnessDown
  786544,
// BrightnessToggle
  786546,
// BrightnessMinimum
  786547,
// BrightnessMaximum
  786548,
// BrightnessAuto
  786549,
// KbdIllumUp
  786553,
// KbdIllumDown
  786554,
// MediaLast
  786563,
// LaunchPhone
  786572,
// ProgramGuide
  786573,
// Exit
  786580,
// ChannelUp
  786588,
// ChannelDown
  786589,
// MediaPlay
  786608,
// MediaPause
  786609,
// MediaRecord
  786610,
// MediaFastForward
  786611,
// MediaRewind
  786612,
// SpeechInputToggle
  786639,
// BassBoost
  786661,
// LaunchWordProcessor
  786820,
// LaunchSpreadsheet
  786822,
// LaunchContacts
  786829,
// LaunchCalendar
  786830,
// LaunchInternetBrowser
  786838,
// LogOff
  786844,
// LockScreen
  786846,
// LaunchControlPanel
  786847,
// SelectTask
  786850,
// LaunchDocuments
  786855,
// SpellCheck
  786859,
// LaunchKeyboardLayout
  786862,
// LaunchScreenSaver
  786865,
// LaunchAudioBrowser
  786871,
// LaunchAssistant
  786891,
// New
  786945,
// Close
  786947,
// Save
  786951,
// Print
  786952,
// ZoomIn
  786989,
// ZoomOut
  786990,
// ZoomToggle
  786994,
// Redo
  787065,
// MailReply
  787081,
// MailForward
  787083,
// MailSend
  787084,
// KeyboardLayoutSelect
  787101,
// ShowAllWindows
  787103,
];

Future<void> main() async {
  // TODO! 必须要这样加载动态库才能初始化成功!!!
  // libenigo_flutter.dylib 库不会自动生成, 需要 cd rust && cargo build
  setUpAll(
    () async => await RustLib.init(
      externalLibrary: ExternalLibrary.open(
        'rust/target/debug/libenigo_flutter.${Platform.isWindows ? "dll" : Platform.isMacOS ? "dylib" : "so"}',
      ),
    ),
  );

  test("Dart PhysicalKeyboardKey transform Enigo Key", () {
    for (final it in PhysicalKeyboardKey.knownPhysicalKeys) {
      if ((Platform.isMacOS && macosUnpportKeys.contains(it.usbHidUsage)) ||
          (Platform.isWindows && windowsUnpportKeys.contains(it.usbHidUsage))) {
        continue;
      }

      expect(testKey2Key(key: it), it);
    }
  });
}

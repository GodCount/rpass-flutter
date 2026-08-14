pub use enigo::{Key, Settings};
use enigo::{Keyboard, Mouse};
use flutter_rust_bridge::*;
use std::sync::Mutex;

pub use enigo::{Axis, Coordinate, Direction};

#[frb(mirror(Settings))]
pub struct _Settings {
    pub linux_delay: u32,
    pub x11_display: Option<String>,
    pub wayland_display: Option<String>,
    pub windows_dw_extra_info: Option<usize>,
    pub event_source_user_data: Option<i64>,
    pub release_keys_when_dropped: bool,
    pub open_prompt_to_get_permissions: bool,
    pub independent_of_keyboard_state: bool,
    pub windows_subject_to_mouse_speed_and_acceleration_level: bool,
}

#[cfg(target_os = "macos")]
#[frb(ignore)]
mod permission {
    use core_foundation::{
        base::TCFType,
        dictionary::{CFDictionary, CFDictionaryRef},
        string::{CFString, CFStringRef},
    };

    #[link(name = "ApplicationServices", kind = "framework")]
    extern "C" {
        pub fn AXIsProcessTrustedWithOptions(options: CFDictionaryRef) -> bool;
        static kAXTrustedCheckOptionPrompt: CFStringRef;
    }

    pub fn has_permission(open_prompt_to_get_permissions: bool) -> bool {
        let key = unsafe { kAXTrustedCheckOptionPrompt };
        let key = unsafe { CFString::wrap_under_create_rule(key) };

        let value = if open_prompt_to_get_permissions {
            core_foundation::boolean::CFBoolean::true_value()
        } else {
            core_foundation::boolean::CFBoolean::false_value()
        };

        let options = CFDictionary::from_CFType_pairs(&[(key, value)]);
        let options = options.as_concrete_TypeRef();
        unsafe { AXIsProcessTrustedWithOptions(options) }
    }
}
#[cfg(any(target_os = "windows", target_os = "linux"))]
#[frb(ignore)]
mod permission {
    pub fn has_permission(open_prompt_to_get_permissions: bool) -> bool {
        true
    }
}

#[frb]
pub struct Enigo {
    #[frb(ignore)]
    enigo: Mutex<enigo::Enigo>,
}

unsafe impl Send for Enigo {}

unsafe impl Sync for Enigo {}

impl Enigo {
    #[frb(sync)]
    pub fn new(settings: &Settings) -> Self {
        Self {
            enigo: Mutex::new(enigo::Enigo::new(settings).unwrap()),
        }
    }

    #[frb(sync)]
    pub fn preset() -> Self {
        Self {
            enigo: Mutex::new(enigo::Enigo::new(&Settings::default()).unwrap()),
        }
    }

    #[frb(sync)]
    pub fn has_permission(open_prompt: bool) -> bool {
        permission::has_permission(open_prompt)
    }

    #[frb(sync)]
    pub fn button(&mut self, button: _Button, direction: Direction) {
        self.enigo
            .lock()
            .unwrap()
            .button(button.value, direction)
            .unwrap();
    }

    #[frb(sync)]
    pub fn move_mouse(&mut self, x: i32, y: i32, coordinate: Coordinate) {
        self.enigo
            .lock()
            .unwrap()
            .move_mouse(x, y, coordinate)
            .unwrap();
    }

    #[frb(sync)]
    pub fn scroll(&mut self, length: i32, axis: Axis) {
        self.enigo.lock().unwrap().scroll(length, axis).unwrap();
    }

    #[frb(sync)]
    pub fn main_display(&self) -> (i32, i32) {
        self.enigo.lock().unwrap().main_display().unwrap()
    }

    #[frb(sync)]
    pub fn location(&self) -> (i32, i32) {
        self.enigo.lock().unwrap().location().unwrap()
    }

    #[frb(sync)]
    pub fn text(&mut self, text: &str) {
        self.enigo.lock().unwrap().text(text).unwrap();
    }

    #[frb(sync)]
    pub fn key(&mut self, key: Key, direction: Direction) {
        self.enigo.lock().unwrap().key(key, direction).unwrap();
    }

    #[frb(sync)]
    pub fn raw(&mut self, keycode: u16, direction: Direction) {
        self.enigo.lock().unwrap().raw(keycode, direction).unwrap()
    }
}

#[frb(mirror(Direction))]
pub enum _Direction {
    Press,
    Release,
    Click,
}

#[frb(mirror(Coordinate))]
pub enum _Coordinate {
    Abs,
    Rel,
}

#[frb(mirror(Axis))]
pub enum _Axis {
    Horizontal,
    Vertical,
}

#[frb(name = "Button")]
pub struct _Button {
    #[frb(ignore)]
    pub(crate) value: enigo::Button,
}

impl _Button {
    #[frb(sync)]
    pub fn new(value: &str) -> Self {
        Self {
            value: match value {
                "left" => enigo::Button::Left,
                "middle" => enigo::Button::Middle,
                "right" => enigo::Button::Right,
                "back" => enigo::Button::Back,
                "forward" => enigo::Button::Forward,
                "scroll_up" => enigo::Button::ScrollUp,
                "scroll_down" => enigo::Button::ScrollDown,
                "scroll_left" => enigo::Button::ScrollLeft,
                "scroll_right" => enigo::Button::ScrollRight,
                _ => panic!("Unspport!"),
            },
        }
    }

    #[frb(sync, getter)]
    pub fn left() -> Self {
        Self::new("left")
    }
    #[frb(sync, getter)]
    pub fn middle() -> Self {
        Self::new("middle")
    }
    #[frb(sync, getter)]
    pub fn right() -> Self {
        Self::new("right")
    }
    #[frb(sync, getter)]
    pub fn back() -> Self {
        Self::new("back")
    }
    #[frb(sync, getter)]
    pub fn forward() -> Self {
        Self::new("forward")
    }
    #[frb(sync, getter)]
    pub fn scroll_up() -> Self {
        Self::new("scroll_up")
    }

    #[frb(sync, getter)]
    pub fn scroll_down() -> Self {
        Self::new("scroll_down")
    }
    #[frb(sync, getter)]
    pub fn scroll_left() -> Self {
        Self::new("scroll_left")
    }
    #[frb(sync, getter)]
    pub fn scroll_right() -> Self {
        Self::new("scroll_right")
    }

    #[frb(sync)]
    pub fn to_string(&mut self) -> String {
        match self.value {
            enigo::Button::Left => "left",
            enigo::Button::Middle => "middle",
            enigo::Button::Right => "right",
            enigo::Button::Back => "back",
            enigo::Button::Forward => "forward",
            enigo::Button::ScrollUp => "scroll_up",
            enigo::Button::ScrollDown => "scroll_down",
            enigo::Button::ScrollLeft => "scroll_left",
            enigo::Button::ScrollRight => "scroll_right",
        }
        .to_string()
    }
}

#[frb(sync)]
pub fn test_key2key(key: Key) -> Key {
    key
}

// key code corresponding table
// https://github.com/flutter/flutter/blob/master/dev/tools/gen_keycodes/data/physical_key_data.g.json
//
// `PhysicalKeyboardKey.usbHidUsage` is a USB HID usage: the upper 16 bits are the usage page
// (0x0007 is the keyboard/keypad page, 0x000c the consumer page, 0x0000 a range Flutter
// reserved for keys that have no HID usage at all) and the lower 16 bits are the usage id.
//
// Character producing keys have no named `Key` variant in enigo, they are expressed as
// `Key::Unicode` and resolved through the keyboard layout that is active while typing. They are
// therefore translated using the US layout, which is the layout the HID keyboard page is named
// after and the same assumption Flutter makes when it labels a physical key.

/// Generates both directions of the named key mapping from a single table so that they can not
/// drift apart. Keys that only exist on some platforms carry the matching `cfg` on their entry.
macro_rules! named_key_table {
    ($($(#[$meta:meta])* $usb:literal => $variant:ident),* $(,)?) => {
        fn usb_hid_to_named_key(usb: u32) -> Option<Key> {
            match usb {
                $($(#[$meta])* $usb => Some(Key::$variant),)*
                _ => None,
            }
        }

        fn named_key_to_usb_hid(key: Key) -> Option<u32> {
            match key {
                $($(#[$meta])* Key::$variant => Some($usb),)*
                _ => None,
            }
        }
    };
}

named_key_table! {
    // Generic desktop page.
    #[cfg(target_os = "windows")]
    0x0001_0082 => Sleep,

    // Keyboard / keypad page.
    0x0007_0028 => Return,
    0x0007_0029 => Escape,
    0x0007_002a => Backspace,
    0x0007_002b => Tab,
    0x0007_002c => Space,
    0x0007_0039 => CapsLock,
    0x0007_003a => F1,
    0x0007_003b => F2,
    0x0007_003c => F3,
    0x0007_003d => F4,
    0x0007_003e => F5,
    0x0007_003f => F6,
    0x0007_0040 => F7,
    0x0007_0041 => F8,
    0x0007_0042 => F9,
    0x0007_0043 => F10,
    0x0007_0044 => F11,
    0x0007_0045 => F12,
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x0007_0046 => PrintScr,
    #[cfg(target_os = "windows")]
    0x0007_0047 => Scroll,
    #[cfg(all(unix, not(target_os = "macos")))]
    0x0007_0047 => ScrollLock,
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x0007_0048 => Pause,
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x0007_0049 => Insert,
    0x0007_004a => Home,
    0x0007_004b => PageUp,
    0x0007_004c => Delete,
    0x0007_004d => End,
    0x0007_004e => PageDown,
    0x0007_004f => RightArrow,
    0x0007_0050 => LeftArrow,
    0x0007_0051 => DownArrow,
    0x0007_0052 => UpArrow,
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x0007_0053 => Numlock,
    0x0007_0054 => Divide,
    0x0007_0055 => Multiply,
    0x0007_0056 => Subtract,
    0x0007_0057 => Add,
    0x0007_0059 => Numpad1,
    0x0007_005a => Numpad2,
    0x0007_005b => Numpad3,
    0x0007_005c => Numpad4,
    0x0007_005d => Numpad5,
    0x0007_005e => Numpad6,
    0x0007_005f => Numpad7,
    0x0007_0060 => Numpad8,
    0x0007_0061 => Numpad9,
    0x0007_0062 => Numpad0,
    0x0007_0063 => Decimal,
    // ContextMenu. On Linux enigo maps `LMenu` to the `XK_Menu` keysym, not to the left alt key.
    #[cfg(target_os = "windows")]
    0x0007_0065 => Apps,
    #[cfg(all(unix, not(target_os = "macos")))]
    0x0007_0065 => LMenu,
    #[cfg(target_os = "macos")]
    0x0007_0066 => Power,
    0x0007_0068 => F13,
    0x0007_0069 => F14,
    0x0007_006a => F15,
    0x0007_006b => F16,
    0x0007_006c => F17,
    0x0007_006d => F18,
    0x0007_006e => F19,
    0x0007_006f => F20,
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x0007_0070 => F21,
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x0007_0071 => F22,
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x0007_0072 => F23,
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x0007_0073 => F24,
    0x0007_0075 => Help,
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x0007_0077 => Select,
    #[cfg(all(unix, not(target_os = "macos")))]
    0x0007_007a => Undo,
    #[cfg(all(unix, not(target_os = "macos")))]
    0x0007_007e => Find,
    0x0007_007f => VolumeMute,
    0x0007_0080 => VolumeUp,
    0x0007_0081 => VolumeDown,
    #[cfg(target_os = "windows")]
    0x0007_0088 => Kana,
    #[cfg(target_os = "windows")]
    0x0007_008a => Convert,
    #[cfg(target_os = "windows")]
    0x0007_008b => NonConvert,
    // Lang1 / Lang2 are the Hangul and Hanja keys on Korean keyboards.
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x0007_0090 => Hangul,
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x0007_0091 => Hanja,
    0x0007_00e0 => LControl,
    0x0007_00e1 => LShift,
    #[cfg(target_os = "macos")]
    0x0007_00e2 => Option,
    #[cfg(target_os = "windows")]
    0x0007_00e2 => LMenu,
    #[cfg(all(unix, not(target_os = "macos")))]
    0x0007_00e2 => Alt,
    #[cfg(not(target_os = "windows"))]
    0x0007_00e3 => Meta,
    #[cfg(target_os = "windows")]
    0x0007_00e3 => LWin,
    0x0007_00e4 => RControl,
    0x0007_00e5 => RShift,
    #[cfg(target_os = "macos")]
    0x0007_00e6 => ROption,
    #[cfg(target_os = "windows")]
    0x0007_00e6 => RMenu,
    #[cfg(target_os = "macos")]
    0x0007_00e7 => RCommand,
    #[cfg(target_os = "windows")]
    0x0007_00e7 => RWin,

    // Consumer page.
    #[cfg(target_os = "macos")]
    0x000c_006f => BrightnessUp,
    #[cfg(target_os = "macos")]
    0x000c_0070 => BrightnessDown,
    #[cfg(target_os = "macos")]
    0x000c_0079 => IlluminationUp,
    #[cfg(target_os = "macos")]
    0x000c_007a => IlluminationDown,
    #[cfg(target_os = "macos")]
    0x000c_00b3 => MediaFast,
    #[cfg(target_os = "macos")]
    0x000c_00b4 => MediaRewind,
    0x000c_00b5 => MediaNextTrack,
    0x000c_00b6 => MediaPrevTrack,
    #[cfg(any(target_os = "windows", all(unix, not(target_os = "macos"))))]
    0x000c_00b7 => MediaStop,
    #[cfg(target_os = "macos")]
    0x000c_00b8 => Eject,
    0x000c_00cd => MediaPlayPause,
    #[cfg(target_os = "windows")]
    0x000c_0183 => LaunchMediaSelect,
    #[cfg(target_os = "windows")]
    0x000c_018a => LaunchMail,
    #[cfg(target_os = "windows")]
    0x000c_0192 => LaunchApp2,
    #[cfg(target_os = "windows")]
    0x000c_0194 => LaunchApp1,
    #[cfg(target_os = "windows")]
    0x000c_0221 => BrowserSearch,
    #[cfg(target_os = "windows")]
    0x000c_0223 => BrowserHome,
    #[cfg(target_os = "windows")]
    0x000c_0224 => BrowserBack,
    #[cfg(target_os = "windows")]
    0x000c_0225 => BrowserForward,
    #[cfg(target_os = "windows")]
    0x000c_0226 => BrowserStop,
    #[cfg(target_os = "windows")]
    0x000c_0227 => BrowserRefresh,
    #[cfg(target_os = "windows")]
    0x000c_022a => BrowserFavorites,
    #[cfg(target_os = "windows")]
    0x000c_0232 => Zoom,
    #[cfg(all(unix, not(target_os = "macos")))]
    0x000c_0279 => Redo,
    #[cfg(target_os = "macos")]
    0x000c_029f => MissionControl,

    // Keys Flutter placed outside of the HID pages.
    #[cfg(target_os = "macos")]
    0x0000_0012 => Function,
    #[cfg(all(unix, not(target_os = "macos")))]
    0x0000_0018 => MicMute,
}

/// The characters the US layout produces for the printable keys that are neither a letter nor a
/// digit.
const CHAR_KEYS: &[(u32, char)] = &[
    (0x0007_002d, '-'),
    (0x0007_002e, '='),
    (0x0007_002f, '['),
    (0x0007_0030, ']'),
    (0x0007_0031, '\\'),
    (0x0007_0033, ';'),
    (0x0007_0034, '\''),
    (0x0007_0035, '`'),
    (0x0007_0036, ','),
    (0x0007_0037, '.'),
    (0x0007_0038, '/'),
];

/// What those same keys produce while shift is held. Only consulted while encoding, so that a
/// `Key::Unicode('?')` still resolves to the key it is printed on.
const SHIFTED_CHAR_KEYS: &[(u32, char)] = &[
    (0x0007_001e, '!'),
    (0x0007_001f, '@'),
    (0x0007_0020, '#'),
    (0x0007_0021, '$'),
    (0x0007_0022, '%'),
    (0x0007_0023, '^'),
    (0x0007_0024, '&'),
    (0x0007_0025, '*'),
    (0x0007_0026, '('),
    (0x0007_0027, ')'),
    (0x0007_002d, '_'),
    (0x0007_002e, '+'),
    (0x0007_002f, '{'),
    (0x0007_0030, '}'),
    (0x0007_0031, '|'),
    (0x0007_0033, ':'),
    (0x0007_0034, '"'),
    (0x0007_0035, '~'),
    (0x0007_0036, '<'),
    (0x0007_0037, '>'),
    (0x0007_0038, '?'),
];

fn usb_hid_to_char(usb: u32) -> Option<char> {
    match usb {
        0x0007_0004..=0x0007_001d => char::from_u32('a' as u32 + (usb - 0x0007_0004)),
        0x0007_001e..=0x0007_0026 => char::from_u32('1' as u32 + (usb - 0x0007_001e)),
        0x0007_0027 => Some('0'),
        _ => CHAR_KEYS.iter().find(|(u, _)| *u == usb).map(|(_, c)| *c),
    }
}

fn char_to_usb_hid(c: char) -> Option<u32> {
    match c.to_ascii_lowercase() {
        lower @ 'a'..='z' => return Some(0x0007_0004 + (lower as u32 - 'a' as u32)),
        digit @ '1'..='9' => return Some(0x0007_001e + (digit as u32 - '1' as u32)),
        '0' => return Some(0x0007_0027),
        ' ' => return Some(0x0007_002c),
        '\n' | '\r' => return Some(0x0007_0028),
        '\t' => return Some(0x0007_002b),
        '\u{8}' => return Some(0x0007_002a),
        '\u{1b}' => return Some(0x0007_0029),
        _ => {}
    }

    CHAR_KEYS
        .iter()
        .chain(SHIFTED_CHAR_KEYS)
        .find(|(_, ch)| *ch == c)
        .map(|(usb, _)| *usb)
}

/// Best effort mapping for physical keys that have no dedicated `Key` variant on this platform.
/// These are decode only, so encoding stays unambiguous.
fn usb_hid_to_substitute_key(usb: u32) -> Option<Key> {
    Some(match usb {
        // NumpadEnter behaves like Return for everything enigo can express.
        0x0007_0058 => Key::Return,
        // IntlBackslash is the extra key next to the left shift key on ISO keyboards.
        0x0007_0064 => Key::Unicode('\\'),
        #[cfg(all(unix, not(target_os = "macos")))]
        0x0007_00e6 => Key::Alt,
        #[cfg(all(unix, not(target_os = "macos")))]
        0x0007_00e7 => Key::Meta,
        _ => return None,
    })
}

/// The side agnostic modifiers, plus the deprecated aliases of `Key::Meta`, all resolve to the
/// left hand side key.
#[allow(deprecated)]
fn modifier_alias_to_usb_hid(key: Key) -> Option<u32> {
    Some(match key {
        Key::Control => 0x0007_00e0,
        Key::Shift => 0x0007_00e1,
        Key::Alt | Key::Option => 0x0007_00e2,
        Key::Meta | Key::Command | Key::Super | Key::Windows => 0x0007_00e3,
        _ => return None,
    })
}

/// Keys without a known usage encode to `0`, which is `PhysicalKeyboardKey.none` on the Dart side.
#[frb(rust2dart(
    dart_type = "PhysicalKeyboardKey",
    dart_code = "PhysicalKeyboardKey({})"
))]
pub fn encode_physical_keyboard_key_type(raw: Key) -> u32 {
    if let Some(usb) = named_key_to_usb_hid(raw).or_else(|| modifier_alias_to_usb_hid(raw)) {
        return usb;
    }

    match raw {
        Key::Unicode(c) => char_to_usb_hid(c).unwrap_or(0),
        Key::Other(code) => code,
        _ => 0,
    }
}

/// Usages that enigo can not express fall back to `Key::Other`, which keeps them stable across a
/// round trip even though pressing them is platform dependent.
#[frb(dart2rust(dart_type = "PhysicalKeyboardKey", dart_code = "{}.usbHidUsage"))]
pub fn decode_physical_keyboard_key_type(raw: u32) -> Key {
    usb_hid_to_named_key(raw)
        .or_else(|| usb_hid_to_char(raw).map(Key::Unicode))
        .or_else(|| usb_hid_to_substitute_key(raw))
        .unwrap_or(Key::Other(raw))
}

#[cfg(test)]
#[frb(ignore)]
mod tests {
    use super::*;

    fn round_trip(usb: u32) {
        assert_eq!(
            encode_physical_keyboard_key_type(decode_physical_keyboard_key_type(usb)),
            usb,
            "usage {usb:#010x} did not survive a round trip"
        );
    }

    #[test]
    fn letters_and_digits_use_the_us_layout() {
        assert_eq!(
            decode_physical_keyboard_key_type(0x0007_0004),
            Key::Unicode('a')
        );
        assert_eq!(
            decode_physical_keyboard_key_type(0x0007_001d),
            Key::Unicode('z')
        );
        assert_eq!(
            decode_physical_keyboard_key_type(0x0007_001e),
            Key::Unicode('1')
        );
        assert_eq!(
            decode_physical_keyboard_key_type(0x0007_0027),
            Key::Unicode('0')
        );

        for usb in 0x0007_0004..=0x0007_0027 {
            round_trip(usb);
        }
    }

    #[test]
    fn named_keys_round_trip() {
        // The substitute mappings are deliberately one way, everything else has to be bijective.
        for usb in (0x0007_0028..=0x0007_00e7).chain([0x000c_00b5, 0x000c_00cd]) {
            if usb_hid_to_substitute_key(usb).is_none() {
                round_trip(usb);
            }
        }
    }

    #[test]
    fn shifted_characters_resolve_to_their_unshifted_key() {
        assert_eq!(
            encode_physical_keyboard_key_type(Key::Unicode('?')),
            0x0007_0038
        );
        assert_eq!(
            encode_physical_keyboard_key_type(Key::Unicode('A')),
            0x0007_0004
        );
        assert_eq!(
            encode_physical_keyboard_key_type(Key::Unicode('!')),
            0x0007_001e
        );
    }

    #[test]
    fn unknown_usages_stay_unknown() {
        assert_eq!(
            decode_physical_keyboard_key_type(0x0005_ff01),
            Key::Other(0x0005_ff01)
        );
        round_trip(0x0005_ff01);
        assert_eq!(encode_physical_keyboard_key_type(Key::Unicode('中')), 0);
    }
}

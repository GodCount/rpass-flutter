pub use enigo::Settings;
use enigo::{Key, Keyboard, Mouse};
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
#[cfg(target_os = "windows")]
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

#[frb(rust2dart(
    dart_type = "PhysicalKeyboardKey",
    dart_code = "PhysicalKeyboardKey({})"
))]
pub fn encode_physical_keyboard_key_type(raw: Key) -> u32 {
    match raw {
        // 需要特殊处理
        Key::VolumeUp => 0x00070080,
        Key::VolumeDown => 0x00070081,
        Key::VolumeMute => 0x0007007f,
        #[cfg(target_os = "macos")]
        Key::BrightnessUp => 0x000c0079,
        #[cfg(target_os = "macos")]
        Key::BrightnessDown => 0x000c007a,
        #[cfg(target_os = "macos")]
        Key::Power => 0x00070066,
        #[cfg(target_os = "macos")]
        Key::LaunchPanel => 0x000c019f,
        #[cfg(target_os = "macos")]
        Key::Eject => 0x000c00b8,
        Key::MediaPlayPause => 0x000c00cd,
        Key::MediaNextTrack => 0x000c00b5,
        Key::MediaPrevTrack => 0x000c00b6,
        #[cfg(target_os = "macos")]
        Key::MediaFast => 0x000c0083,
        #[cfg(target_os = "macos")]
        Key::MediaRewind => 0x000c00b4,
        #[cfg(target_os = "macos")]
        Key::IlluminationUp => 0x000c006f,
        #[cfg(target_os = "macos")]
        Key::IlluminationDown => 0x000c0070,
        #[cfg(target_os = "macos")]
        Key::IlluminationToggle => 0x000c0072,
        Key::Other(value) => match value {
            // Fn
            #[cfg(target_os = "macos")]
            63 => 0x00000012,
            // PrivacyScreenToggle
            #[cfg(target_os = "linux")]
            633 => 0x00000017,
            // MicrophoneMuteToggle
            #[cfg(target_os = "linux")]
            248 => 0x00000018,
            // Sleep
            #[cfg(target_os = "windows")]
            95 => 0x00010082,
            #[cfg(target_os = "linux")]
            142 => 0x00010082,
            // WakeUp
            #[cfg(target_os = "windows")]
            232 => 0x00010083,
            #[cfg(target_os = "linux")]
            143 => 0x00010083,
            // DisplayToggleIntExt
            #[cfg(target_os = "linux")]
            227 => 0x000100b5,
            // KeyA
            #[cfg(target_os = "macos")]
            0 => 0x00070004,
            #[cfg(target_os = "windows")]
            65 => 0x00070004,
            #[cfg(target_os = "linux")]
            30 => 0x00070004,
            // KeyB
            #[cfg(target_os = "macos")]
            11 => 0x00070005,
            #[cfg(target_os = "windows")]
            66 => 0x00070005,
            #[cfg(target_os = "linux")]
            48 => 0x00070005,
            // KeyC
            #[cfg(target_os = "macos")]
            8 => 0x00070006,
            #[cfg(target_os = "windows")]
            67 => 0x00070006,
            #[cfg(target_os = "linux")]
            46 => 0x00070006,
            // KeyD
            #[cfg(target_os = "macos")]
            2 => 0x00070007,
            #[cfg(target_os = "windows")]
            68 => 0x00070007,
            #[cfg(target_os = "linux")]
            32 => 0x00070007,
            // KeyE
            #[cfg(target_os = "macos")]
            14 => 0x00070008,
            #[cfg(target_os = "windows")]
            69 => 0x00070008,
            #[cfg(target_os = "linux")]
            18 => 0x00070008,
            // KeyF
            #[cfg(target_os = "macos")]
            3 => 0x00070009,
            #[cfg(target_os = "windows")]
            70 => 0x00070009,
            #[cfg(target_os = "linux")]
            33 => 0x00070009,
            // KeyG
            #[cfg(target_os = "macos")]
            5 => 0x0007000a,
            #[cfg(target_os = "windows")]
            71 => 0x0007000a,
            #[cfg(target_os = "linux")]
            34 => 0x0007000a,
            // KeyH
            #[cfg(target_os = "macos")]
            4 => 0x0007000b,
            #[cfg(target_os = "windows")]
            72 => 0x0007000b,
            #[cfg(target_os = "linux")]
            35 => 0x0007000b,
            // KeyI
            #[cfg(target_os = "macos")]
            34 => 0x0007000c,
            #[cfg(target_os = "windows")]
            73 => 0x0007000c,
            #[cfg(target_os = "linux")]
            23 => 0x0007000c,
            // KeyJ
            #[cfg(target_os = "macos")]
            38 => 0x0007000d,
            #[cfg(target_os = "windows")]
            74 => 0x0007000d,
            #[cfg(target_os = "linux")]
            36 => 0x0007000d,
            // KeyK
            #[cfg(target_os = "macos")]
            40 => 0x0007000e,
            #[cfg(target_os = "windows")]
            75 => 0x0007000e,
            #[cfg(target_os = "linux")]
            37 => 0x0007000e,
            // KeyL
            #[cfg(target_os = "macos")]
            37 => 0x0007000f,
            #[cfg(target_os = "windows")]
            76 => 0x0007000f,
            #[cfg(target_os = "linux")]
            38 => 0x0007000f,
            // KeyM
            #[cfg(target_os = "macos")]
            46 => 0x00070010,
            #[cfg(target_os = "windows")]
            77 => 0x00070010,
            #[cfg(target_os = "linux")]
            50 => 0x00070010,
            // KeyN
            #[cfg(target_os = "macos")]
            45 => 0x00070011,
            #[cfg(target_os = "windows")]
            78 => 0x00070011,
            #[cfg(target_os = "linux")]
            49 => 0x00070011,
            // KeyO
            #[cfg(target_os = "macos")]
            31 => 0x00070012,
            #[cfg(target_os = "windows")]
            79 => 0x00070012,
            #[cfg(target_os = "linux")]
            24 => 0x00070012,
            // KeyP
            #[cfg(target_os = "macos")]
            35 => 0x00070013,
            #[cfg(target_os = "windows")]
            80 => 0x00070013,
            #[cfg(target_os = "linux")]
            25 => 0x00070013,
            // KeyQ
            #[cfg(target_os = "macos")]
            12 => 0x00070014,
            #[cfg(target_os = "windows")]
            81 => 0x00070014,
            #[cfg(target_os = "linux")]
            16 => 0x00070014,
            // KeyR
            #[cfg(target_os = "macos")]
            15 => 0x00070015,
            #[cfg(target_os = "windows")]
            82 => 0x00070015,
            #[cfg(target_os = "linux")]
            19 => 0x00070015,
            // KeyS
            #[cfg(target_os = "macos")]
            1 => 0x00070016,
            #[cfg(target_os = "windows")]
            83 => 0x00070016,
            #[cfg(target_os = "linux")]
            31 => 0x00070016,
            // KeyT
            #[cfg(target_os = "macos")]
            17 => 0x00070017,
            #[cfg(target_os = "windows")]
            84 => 0x00070017,
            #[cfg(target_os = "linux")]
            20 => 0x00070017,
            // KeyU
            #[cfg(target_os = "macos")]
            32 => 0x00070018,
            #[cfg(target_os = "windows")]
            85 => 0x00070018,
            #[cfg(target_os = "linux")]
            22 => 0x00070018,
            // KeyV
            #[cfg(target_os = "macos")]
            9 => 0x00070019,
            #[cfg(target_os = "windows")]
            86 => 0x00070019,
            #[cfg(target_os = "linux")]
            47 => 0x00070019,
            // KeyW
            #[cfg(target_os = "macos")]
            13 => 0x0007001a,
            #[cfg(target_os = "windows")]
            87 => 0x0007001a,
            #[cfg(target_os = "linux")]
            17 => 0x0007001a,
            // KeyX
            #[cfg(target_os = "macos")]
            7 => 0x0007001b,
            #[cfg(target_os = "windows")]
            88 => 0x0007001b,
            #[cfg(target_os = "linux")]
            45 => 0x0007001b,
            // KeyY
            #[cfg(target_os = "macos")]
            16 => 0x0007001c,
            #[cfg(target_os = "windows")]
            89 => 0x0007001c,
            #[cfg(target_os = "linux")]
            21 => 0x0007001c,
            // KeyZ
            #[cfg(target_os = "macos")]
            6 => 0x0007001d,
            #[cfg(target_os = "windows")]
            90 => 0x0007001d,
            #[cfg(target_os = "linux")]
            44 => 0x0007001d,
            // Digit1
            #[cfg(target_os = "macos")]
            18 => 0x0007001e,
            #[cfg(target_os = "windows")]
            49 => 0x0007001e,
            #[cfg(target_os = "linux")]
            2 => 0x0007001e,
            // Digit2
            #[cfg(target_os = "macos")]
            19 => 0x0007001f,
            #[cfg(target_os = "windows")]
            50 => 0x0007001f,
            #[cfg(target_os = "linux")]
            3 => 0x0007001f,
            // Digit3
            #[cfg(target_os = "macos")]
            20 => 0x00070020,
            #[cfg(target_os = "windows")]
            51 => 0x00070020,
            #[cfg(target_os = "linux")]
            4 => 0x00070020,
            // Digit4
            #[cfg(target_os = "macos")]
            21 => 0x00070021,
            #[cfg(target_os = "windows")]
            52 => 0x00070021,
            #[cfg(target_os = "linux")]
            5 => 0x00070021,
            // Digit5
            #[cfg(target_os = "macos")]
            23 => 0x00070022,
            #[cfg(target_os = "windows")]
            53 => 0x00070022,
            #[cfg(target_os = "linux")]
            6 => 0x00070022,
            // Digit6
            #[cfg(target_os = "macos")]
            22 => 0x00070023,
            #[cfg(target_os = "windows")]
            54 => 0x00070023,
            #[cfg(target_os = "linux")]
            7 => 0x00070023,
            // Digit7
            #[cfg(target_os = "macos")]
            26 => 0x00070024,
            #[cfg(target_os = "windows")]
            55 => 0x00070024,
            #[cfg(target_os = "linux")]
            8 => 0x00070024,
            // Digit8
            #[cfg(target_os = "macos")]
            28 => 0x00070025,
            #[cfg(target_os = "windows")]
            56 => 0x00070025,
            #[cfg(target_os = "linux")]
            9 => 0x00070025,
            // Digit9
            #[cfg(target_os = "macos")]
            25 => 0x00070026,
            #[cfg(target_os = "windows")]
            57 => 0x00070026,
            #[cfg(target_os = "linux")]
            10 => 0x00070026,
            // Digit0
            #[cfg(target_os = "macos")]
            29 => 0x00070027,
            #[cfg(target_os = "windows")]
            48 => 0x00070027,
            #[cfg(target_os = "linux")]
            11 => 0x00070027,
            // Enter
            #[cfg(target_os = "macos")]
            36 => 0x00070028,
            #[cfg(target_os = "windows")]
            13 => 0x00070028,
            #[cfg(target_os = "linux")]
            28 => 0x00070028,
            // Escape
            #[cfg(target_os = "macos")]
            53 => 0x00070029,
            #[cfg(target_os = "windows")]
            27 => 0x00070029,
            #[cfg(target_os = "linux")]
            1 => 0x00070029,
            // Backspace
            #[cfg(target_os = "macos")]
            51 => 0x0007002a,
            #[cfg(target_os = "windows")]
            8 => 0x0007002a,
            #[cfg(target_os = "linux")]
            14 => 0x0007002a,
            // Tab
            #[cfg(target_os = "macos")]
            48 => 0x0007002b,
            #[cfg(target_os = "windows")]
            9 => 0x0007002b,
            #[cfg(target_os = "linux")]
            15 => 0x0007002b,
            // Space
            #[cfg(target_os = "macos")]
            49 => 0x0007002c,
            #[cfg(target_os = "windows")]
            32 => 0x0007002c,
            #[cfg(target_os = "linux")]
            57 => 0x0007002c,
            // Minus
            #[cfg(target_os = "macos")]
            27 => 0x0007002d,
            #[cfg(target_os = "windows")]
            189 => 0x0007002d,
            #[cfg(target_os = "linux")]
            12 => 0x0007002d,
            // Equal
            #[cfg(target_os = "macos")]
            24 => 0x0007002e,
            #[cfg(target_os = "windows")]
            187 => 0x0007002e,
            #[cfg(target_os = "linux")]
            13 => 0x0007002e,
            // BracketLeft
            #[cfg(target_os = "macos")]
            33 => 0x0007002f,
            #[cfg(target_os = "windows")]
            219 => 0x0007002f,
            #[cfg(target_os = "linux")]
            26 => 0x0007002f,
            // BracketRight
            #[cfg(target_os = "macos")]
            30 => 0x00070030,
            #[cfg(target_os = "windows")]
            221 => 0x00070030,
            #[cfg(target_os = "linux")]
            27 => 0x00070030,
            // Backslash
            #[cfg(target_os = "macos")]
            42 => 0x00070031,
            #[cfg(target_os = "windows")]
            220 => 0x00070031,
            #[cfg(target_os = "linux")]
            43 => 0x00070031,
            // Semicolon
            #[cfg(target_os = "macos")]
            41 => 0x00070033,
            #[cfg(target_os = "windows")]
            186 => 0x00070033,
            #[cfg(target_os = "linux")]
            39 => 0x00070033,
            // Quote
            #[cfg(target_os = "macos")]
            39 => 0x00070034,
            #[cfg(target_os = "windows")]
            222 => 0x00070034,
            #[cfg(target_os = "linux")]
            40 => 0x00070034,
            // Backquote
            #[cfg(target_os = "macos")]
            50 => 0x00070035,
            #[cfg(target_os = "windows")]
            192 => 0x00070035,
            #[cfg(target_os = "linux")]
            41 => 0x00070035,
            // Comma
            #[cfg(target_os = "macos")]
            43 => 0x00070036,
            #[cfg(target_os = "windows")]
            188 => 0x00070036,
            #[cfg(target_os = "linux")]
            51 => 0x00070036,
            // Period
            #[cfg(target_os = "macos")]
            47 => 0x00070037,
            #[cfg(target_os = "windows")]
            190 => 0x00070037,
            #[cfg(target_os = "linux")]
            52 => 0x00070037,
            // Slash
            #[cfg(target_os = "macos")]
            44 => 0x00070038,
            #[cfg(target_os = "windows")]
            191 => 0x00070038,
            #[cfg(target_os = "linux")]
            53 => 0x00070038,
            // CapsLock
            #[cfg(target_os = "macos")]
            57 => 0x00070039,
            #[cfg(target_os = "windows")]
            20 => 0x00070039,
            #[cfg(target_os = "linux")]
            58 => 0x00070039,
            // F1
            #[cfg(target_os = "macos")]
            122 => 0x0007003a,
            #[cfg(target_os = "windows")]
            112 => 0x0007003a,
            #[cfg(target_os = "linux")]
            59 => 0x0007003a,
            // F2
            #[cfg(target_os = "macos")]
            120 => 0x0007003b,
            #[cfg(target_os = "windows")]
            113 => 0x0007003b,
            #[cfg(target_os = "linux")]
            60 => 0x0007003b,
            // F3
            #[cfg(target_os = "macos")]
            99 => 0x0007003c,
            #[cfg(target_os = "windows")]
            114 => 0x0007003c,
            #[cfg(target_os = "linux")]
            61 => 0x0007003c,
            // F4
            #[cfg(target_os = "macos")]
            118 => 0x0007003d,
            #[cfg(target_os = "windows")]
            115 => 0x0007003d,
            #[cfg(target_os = "linux")]
            62 => 0x0007003d,
            // F5
            #[cfg(target_os = "macos")]
            96 => 0x0007003e,
            #[cfg(target_os = "windows")]
            116 => 0x0007003e,
            #[cfg(target_os = "linux")]
            63 => 0x0007003e,
            // F6
            #[cfg(target_os = "macos")]
            97 => 0x0007003f,
            #[cfg(target_os = "windows")]
            117 => 0x0007003f,
            #[cfg(target_os = "linux")]
            64 => 0x0007003f,
            // F7
            #[cfg(target_os = "macos")]
            98 => 0x00070040,
            #[cfg(target_os = "windows")]
            118 => 0x00070040,
            #[cfg(target_os = "linux")]
            65 => 0x00070040,
            // F8
            #[cfg(target_os = "macos")]
            100 => 0x00070041,
            #[cfg(target_os = "windows")]
            119 => 0x00070041,
            #[cfg(target_os = "linux")]
            66 => 0x00070041,
            // F9
            #[cfg(target_os = "macos")]
            101 => 0x00070042,
            #[cfg(target_os = "windows")]
            120 => 0x00070042,
            #[cfg(target_os = "linux")]
            67 => 0x00070042,
            // F10
            #[cfg(target_os = "macos")]
            109 => 0x00070043,
            #[cfg(target_os = "windows")]
            121 => 0x00070043,
            #[cfg(target_os = "linux")]
            68 => 0x00070043,
            // F11
            #[cfg(target_os = "macos")]
            103 => 0x00070044,
            #[cfg(target_os = "windows")]
            122 => 0x00070044,
            #[cfg(target_os = "linux")]
            87 => 0x00070044,
            // F12
            #[cfg(target_os = "macos")]
            111 => 0x00070045,
            #[cfg(target_os = "windows")]
            123 => 0x00070045,
            #[cfg(target_os = "linux")]
            88 => 0x00070045,
            // PrintScreen
            #[cfg(target_os = "windows")]
            44 => 0x00070046,
            #[cfg(target_os = "linux")]
            99 => 0x00070046,
            // ScrollLock
            #[cfg(target_os = "windows")]
            3 => 0x00070047,
            #[cfg(target_os = "linux")]
            70 => 0x00070047,
            // Pause
            #[cfg(target_os = "windows")]
            19 => 0x00070048,
            #[cfg(target_os = "linux")]
            119 => 0x00070048,
            // Insert
            #[cfg(target_os = "macos")]
            114 => 0x00070049,
            #[cfg(target_os = "windows")]
            45 => 0x00070049,
            #[cfg(target_os = "linux")]
            110 => 0x00070049,
            // Home
            #[cfg(target_os = "macos")]
            115 => 0x0007004a,
            #[cfg(target_os = "windows")]
            36 => 0x0007004a,
            #[cfg(target_os = "linux")]
            102 => 0x0007004a,
            // PageUp
            #[cfg(target_os = "macos")]
            116 => 0x0007004b,
            #[cfg(target_os = "windows")]
            33 => 0x0007004b,
            #[cfg(target_os = "linux")]
            104 => 0x0007004b,
            // Delete
            #[cfg(target_os = "macos")]
            117 => 0x0007004c,
            #[cfg(target_os = "windows")]
            46 => 0x0007004c,
            #[cfg(target_os = "linux")]
            111 => 0x0007004c,
            // End
            #[cfg(target_os = "macos")]
            119 => 0x0007004d,
            #[cfg(target_os = "windows")]
            35 => 0x0007004d,
            #[cfg(target_os = "linux")]
            107 => 0x0007004d,
            // PageDown
            #[cfg(target_os = "macos")]
            121 => 0x0007004e,
            #[cfg(target_os = "windows")]
            34 => 0x0007004e,
            #[cfg(target_os = "linux")]
            109 => 0x0007004e,
            // ArrowRight
            #[cfg(target_os = "macos")]
            124 => 0x0007004f,
            #[cfg(target_os = "windows")]
            39 => 0x0007004f,
            #[cfg(target_os = "linux")]
            106 => 0x0007004f,
            // ArrowLeft
            #[cfg(target_os = "macos")]
            123 => 0x00070050,
            #[cfg(target_os = "windows")]
            37 => 0x00070050,
            #[cfg(target_os = "linux")]
            105 => 0x00070050,
            // ArrowDown
            #[cfg(target_os = "macos")]
            125 => 0x00070051,
            #[cfg(target_os = "windows")]
            40 => 0x00070051,
            #[cfg(target_os = "linux")]
            108 => 0x00070051,
            // ArrowUp
            #[cfg(target_os = "macos")]
            126 => 0x00070052,
            #[cfg(target_os = "windows")]
            38 => 0x00070052,
            #[cfg(target_os = "linux")]
            103 => 0x00070052,
            // NumLock
            #[cfg(target_os = "macos")]
            71 => 0x00070053,
            #[cfg(target_os = "windows")]
            144 => 0x00070053,
            #[cfg(target_os = "linux")]
            69 => 0x00070053,
            // NumpadDivide
            #[cfg(target_os = "macos")]
            75 => 0x00070054,
            #[cfg(target_os = "windows")]
            111 => 0x00070054,
            #[cfg(target_os = "linux")]
            98 => 0x00070054,
            // NumpadMultiply
            #[cfg(target_os = "macos")]
            67 => 0x00070055,
            #[cfg(target_os = "windows")]
            106 => 0x00070055,
            #[cfg(target_os = "linux")]
            55 => 0x00070055,
            // NumpadSubtract
            #[cfg(target_os = "macos")]
            78 => 0x00070056,
            #[cfg(target_os = "windows")]
            109 => 0x00070056,
            #[cfg(target_os = "linux")]
            74 => 0x00070056,
            // NumpadAdd
            #[cfg(target_os = "macos")]
            69 => 0x00070057,
            #[cfg(target_os = "windows")]
            107 => 0x00070057,
            #[cfg(target_os = "linux")]
            78 => 0x00070057,
            // NumpadEnter
            #[cfg(target_os = "macos")]
            76 => 0x00070058,
            #[cfg(target_os = "windows")]
            13 => 0x00070058,
            #[cfg(target_os = "linux")]
            96 => 0x00070058,
            // Numpad1
            #[cfg(target_os = "macos")]
            83 => 0x00070059,
            #[cfg(target_os = "windows")]
            97 => 0x00070059,
            #[cfg(target_os = "linux")]
            79 => 0x00070059,
            // Numpad2
            #[cfg(target_os = "macos")]
            84 => 0x0007005a,
            #[cfg(target_os = "windows")]
            98 => 0x0007005a,
            #[cfg(target_os = "linux")]
            80 => 0x0007005a,
            // Numpad3
            #[cfg(target_os = "macos")]
            85 => 0x0007005b,
            #[cfg(target_os = "windows")]
            99 => 0x0007005b,
            #[cfg(target_os = "linux")]
            81 => 0x0007005b,
            // Numpad4
            #[cfg(target_os = "macos")]
            86 => 0x0007005c,
            #[cfg(target_os = "windows")]
            100 => 0x0007005c,
            #[cfg(target_os = "linux")]
            75 => 0x0007005c,
            // Numpad5
            #[cfg(target_os = "macos")]
            87 => 0x0007005d,
            #[cfg(target_os = "windows")]
            101 => 0x0007005d,
            #[cfg(target_os = "linux")]
            76 => 0x0007005d,
            // Numpad6
            #[cfg(target_os = "macos")]
            88 => 0x0007005e,
            #[cfg(target_os = "windows")]
            102 => 0x0007005e,
            #[cfg(target_os = "linux")]
            77 => 0x0007005e,
            // Numpad7
            #[cfg(target_os = "macos")]
            89 => 0x0007005f,
            #[cfg(target_os = "windows")]
            103 => 0x0007005f,
            #[cfg(target_os = "linux")]
            71 => 0x0007005f,
            // Numpad8
            #[cfg(target_os = "macos")]
            91 => 0x00070060,
            #[cfg(target_os = "windows")]
            104 => 0x00070060,
            #[cfg(target_os = "linux")]
            72 => 0x00070060,
            // Numpad9
            #[cfg(target_os = "macos")]
            92 => 0x00070061,
            #[cfg(target_os = "windows")]
            105 => 0x00070061,
            #[cfg(target_os = "linux")]
            73 => 0x00070061,
            // Numpad0
            #[cfg(target_os = "macos")]
            82 => 0x00070062,
            #[cfg(target_os = "windows")]
            96 => 0x00070062,
            #[cfg(target_os = "linux")]
            82 => 0x00070062,
            // NumpadDecimal
            #[cfg(target_os = "macos")]
            65 => 0x00070063,
            #[cfg(target_os = "windows")]
            110 => 0x00070063,
            #[cfg(target_os = "linux")]
            83 => 0x00070063,
            // IntlBackslash
            #[cfg(target_os = "macos")]
            10 => 0x00070064,
            #[cfg(target_os = "windows")]
            226 => 0x00070064,
            #[cfg(target_os = "linux")]
            86 => 0x00070064,
            // ContextMenu
            #[cfg(target_os = "macos")]
            110 => 0x00070065,
            #[cfg(target_os = "windows")]
            93 => 0x00070065,
            #[cfg(target_os = "linux")]
            127 => 0x00070065,
            // Power
            #[cfg(target_os = "windows")]
            229 => 0x00070066,
            #[cfg(target_os = "linux")]
            116 => 0x00070066,
            // NumpadEqual
            #[cfg(target_os = "macos")]
            81 => 0x00070067,
            #[cfg(target_os = "windows")]
            146 => 0x00070067,
            #[cfg(target_os = "linux")]
            117 => 0x00070067,
            // F13
            #[cfg(target_os = "macos")]
            105 => 0x00070068,
            #[cfg(target_os = "windows")]
            124 => 0x00070068,
            #[cfg(target_os = "linux")]
            183 => 0x00070068,
            // F14
            #[cfg(target_os = "macos")]
            107 => 0x00070069,
            #[cfg(target_os = "windows")]
            125 => 0x00070069,
            #[cfg(target_os = "linux")]
            184 => 0x00070069,
            // F15
            #[cfg(target_os = "macos")]
            113 => 0x0007006a,
            #[cfg(target_os = "windows")]
            126 => 0x0007006a,
            #[cfg(target_os = "linux")]
            185 => 0x0007006a,
            // F16
            #[cfg(target_os = "macos")]
            106 => 0x0007006b,
            #[cfg(target_os = "windows")]
            127 => 0x0007006b,
            #[cfg(target_os = "linux")]
            186 => 0x0007006b,
            // F17
            #[cfg(target_os = "macos")]
            64 => 0x0007006c,
            #[cfg(target_os = "windows")]
            128 => 0x0007006c,
            #[cfg(target_os = "linux")]
            187 => 0x0007006c,
            // F18
            #[cfg(target_os = "macos")]
            79 => 0x0007006d,
            #[cfg(target_os = "windows")]
            129 => 0x0007006d,
            #[cfg(target_os = "linux")]
            188 => 0x0007006d,
            // F19
            #[cfg(target_os = "macos")]
            80 => 0x0007006e,
            #[cfg(target_os = "windows")]
            130 => 0x0007006e,
            #[cfg(target_os = "linux")]
            189 => 0x0007006e,
            // F20
            #[cfg(target_os = "macos")]
            90 => 0x0007006f,
            #[cfg(target_os = "windows")]
            131 => 0x0007006f,
            #[cfg(target_os = "linux")]
            190 => 0x0007006f,
            // F21
            #[cfg(target_os = "windows")]
            132 => 0x00070070,
            #[cfg(target_os = "linux")]
            191 => 0x00070070,
            // F22
            #[cfg(target_os = "windows")]
            133 => 0x00070071,
            #[cfg(target_os = "linux")]
            192 => 0x00070071,
            // F23
            #[cfg(target_os = "windows")]
            134 => 0x00070072,
            #[cfg(target_os = "linux")]
            193 => 0x00070072,
            // F24
            #[cfg(target_os = "windows")]
            135 => 0x00070073,
            #[cfg(target_os = "linux")]
            194 => 0x00070073,
            // Open
            #[cfg(target_os = "linux")]
            134 => 0x00070074,
            // Help
            #[cfg(target_os = "windows")]
            47 => 0x00070075,
            #[cfg(target_os = "linux")]
            138 => 0x00070075,
            // Select
            #[cfg(target_os = "linux")]
            132 => 0x00070077,
            // Again
            #[cfg(target_os = "linux")]
            129 => 0x00070079,
            // Undo
            #[cfg(target_os = "linux")]
            131 => 0x0007007a,
            // Cut
            #[cfg(target_os = "linux")]
            137 => 0x0007007b,
            // Copy
            #[cfg(target_os = "linux")]
            133 => 0x0007007c,
            // Paste
            #[cfg(target_os = "linux")]
            135 => 0x0007007d,
            // Find
            #[cfg(target_os = "linux")]
            136 => 0x0007007e,
            // NumpadComma
            #[cfg(target_os = "macos")]
            95 => 0x00070085,
            #[cfg(target_os = "windows")]
            188 => 0x00070085,
            #[cfg(target_os = "linux")]
            121 => 0x00070085,
            // IntlRo
            #[cfg(target_os = "macos")]
            94 => 0x00070087,
            #[cfg(target_os = "windows")]
            115 => 0x00070087,
            #[cfg(target_os = "linux")]
            89 => 0x00070087,
            // KanaMode
            #[cfg(target_os = "windows")]
            21 => 0x00070088,
            #[cfg(target_os = "linux")]
            93 => 0x00070088,
            // IntlYen
            #[cfg(target_os = "macos")]
            93 => 0x00070089,
            #[cfg(target_os = "windows")]
            125 => 0x00070089,
            #[cfg(target_os = "linux")]
            124 => 0x00070089,
            // Convert
            #[cfg(target_os = "windows")]
            28 => 0x0007008a,
            #[cfg(target_os = "linux")]
            92 => 0x0007008a,
            // NonConvert
            #[cfg(target_os = "windows")]
            29 => 0x0007008b,
            #[cfg(target_os = "linux")]
            94 => 0x0007008b,
            // Lang1
            #[cfg(target_os = "macos")]
            104 => 0x00070090,
            #[cfg(target_os = "windows")]
            114 => 0x00070090,
            #[cfg(target_os = "linux")]
            122 => 0x00070090,
            // Lang2
            #[cfg(target_os = "macos")]
            102 => 0x00070091,
            #[cfg(target_os = "windows")]
            113 => 0x00070091,
            #[cfg(target_os = "linux")]
            123 => 0x00070091,
            // Lang3
            #[cfg(target_os = "windows")]
            120 => 0x00070092,
            #[cfg(target_os = "linux")]
            90 => 0x00070092,
            // Lang4
            #[cfg(target_os = "windows")]
            119 => 0x00070093,
            #[cfg(target_os = "linux")]
            91 => 0x00070093,
            // Lang5
            #[cfg(target_os = "linux")]
            85 => 0x00070094,
            // NumpadParenLeft
            #[cfg(target_os = "linux")]
            179 => 0x000700b6,
            // NumpadParenRight
            #[cfg(target_os = "linux")]
            180 => 0x000700b7,
            // NumpadSignChange
            #[cfg(target_os = "linux")]
            118 => 0x000700d7,
            // ControlLeft
            #[cfg(target_os = "macos")]
            59 => 0x000700e0,
            #[cfg(target_os = "windows")]
            17 => 0x000700e0,
            #[cfg(target_os = "linux")]
            29 => 0x000700e0,
            // ShiftLeft
            #[cfg(target_os = "macos")]
            56 => 0x000700e1,
            #[cfg(target_os = "windows")]
            16 => 0x000700e1,
            #[cfg(target_os = "linux")]
            42 => 0x000700e1,
            // AltLeft
            #[cfg(target_os = "macos")]
            58 => 0x000700e2,
            #[cfg(target_os = "windows")]
            18 => 0x000700e2,
            #[cfg(target_os = "linux")]
            56 => 0x000700e2,
            // MetaLeft
            #[cfg(target_os = "macos")]
            55 => 0x000700e3,
            #[cfg(target_os = "windows")]
            91 => 0x000700e3,
            #[cfg(target_os = "linux")]
            125 => 0x000700e3,
            // ControlRight
            #[cfg(target_os = "macos")]
            62 => 0x000700e4,
            #[cfg(target_os = "windows")]
            163 => 0x000700e4,
            #[cfg(target_os = "linux")]
            97 => 0x000700e4,
            // ShiftRight
            #[cfg(target_os = "macos")]
            60 => 0x000700e5,
            #[cfg(target_os = "windows")]
            161 => 0x000700e5,
            #[cfg(target_os = "linux")]
            54 => 0x000700e5,
            // AltRight
            #[cfg(target_os = "macos")]
            61 => 0x000700e6,
            #[cfg(target_os = "windows")]
            165 => 0x000700e6,
            #[cfg(target_os = "linux")]
            100 => 0x000700e6,
            // MetaRight
            #[cfg(target_os = "macos")]
            54 => 0x000700e7,
            #[cfg(target_os = "windows")]
            92 => 0x000700e7,
            #[cfg(target_os = "linux")]
            126 => 0x000700e7,
            // Info
            #[cfg(target_os = "linux")]
            358 => 0x000c0060,
            // ClosedCaptionToggle
            #[cfg(target_os = "linux")]
            370 => 0x000c0061,
            // BrightnessToggle
            #[cfg(target_os = "linux")]
            431 => 0x000c0072,
            // BrightnessMinimum
            #[cfg(target_os = "linux")]
            592 => 0x000c0073,
            // BrightnessMaximum
            #[cfg(target_os = "linux")]
            593 => 0x000c0074,
            // BrightnessAuto
            #[cfg(target_os = "linux")]
            244 => 0x000c0075,
            // MediaLast
            #[cfg(target_os = "linux")]
            405 => 0x000c0083,
            // LaunchPhone
            #[cfg(target_os = "linux")]
            169 => 0x000c008c,
            // ProgramGuide
            #[cfg(target_os = "linux")]
            362 => 0x000c008d,
            // Exit
            #[cfg(target_os = "linux")]
            174 => 0x000c0094,
            // ChannelUp
            #[cfg(target_os = "linux")]
            410 => 0x000c009c,
            // ChannelDown
            #[cfg(target_os = "linux")]
            411 => 0x000c009d,
            // MediaPlay
            #[cfg(target_os = "linux")]
            207 => 0x000c00b0,
            // MediaPause
            #[cfg(target_os = "linux")]
            201 => 0x000c00b1,
            // MediaRecord
            #[cfg(target_os = "linux")]
            167 => 0x000c00b2,
            // MediaStop
            #[cfg(target_os = "windows")]
            233 => 0x000c00b7,
            #[cfg(target_os = "linux")]
            166 => 0x000c00b7,
            // Eject
            #[cfg(target_os = "windows")]
            238 => 0x000c00b8,
            #[cfg(target_os = "linux")]
            161 => 0x000c00b8,
            // SpeechInputToggle
            #[cfg(target_os = "linux")]
            582 => 0x000c00cf,
            // BassBoost
            #[cfg(target_os = "linux")]
            209 => 0x000c00e5,
            // MediaSelect
            #[cfg(target_os = "windows")]
            237 => 0x000c0183,
            #[cfg(target_os = "linux")]
            171 => 0x000c0183,
            // LaunchWordProcessor
            #[cfg(target_os = "linux")]
            421 => 0x000c0184,
            // LaunchSpreadsheet
            #[cfg(target_os = "linux")]
            423 => 0x000c0186,
            // LaunchMail
            #[cfg(target_os = "windows")]
            236 => 0x000c018a,
            #[cfg(target_os = "linux")]
            155 => 0x000c018a,
            // LaunchContacts
            #[cfg(target_os = "linux")]
            429 => 0x000c018d,
            // LaunchCalendar
            #[cfg(target_os = "linux")]
            397 => 0x000c018e,
            // LaunchApp2
            #[cfg(target_os = "windows")]
            225 => 0x000c0192,
            #[cfg(target_os = "linux")]
            140 => 0x000c0192,
            // LaunchApp1
            #[cfg(target_os = "windows")]
            235 => 0x000c0194,
            #[cfg(target_os = "linux")]
            144 => 0x000c0194,
            // LaunchInternetBrowser
            #[cfg(target_os = "linux")]
            150 => 0x000c0196,
            // LogOff
            #[cfg(target_os = "linux")]
            433 => 0x000c019c,
            // LockScreen
            #[cfg(target_os = "linux")]
            152 => 0x000c019e,
            // LaunchControlPanel
            #[cfg(target_os = "linux")]
            579 => 0x000c019f,
            // SelectTask
            #[cfg(target_os = "linux")]
            580 => 0x000c01a2,
            // LaunchDocuments
            #[cfg(target_os = "linux")]
            235 => 0x000c01a7,
            // SpellCheck
            #[cfg(target_os = "linux")]
            432 => 0x000c01ab,
            // LaunchKeyboardLayout
            #[cfg(target_os = "linux")]
            374 => 0x000c01ae,
            // LaunchScreenSaver
            #[cfg(target_os = "linux")]
            581 => 0x000c01b1,
            // LaunchAudioBrowser
            #[cfg(target_os = "linux")]
            392 => 0x000c01b7,
            // LaunchAssistant
            #[cfg(target_os = "linux")]
            583 => 0x000c01cb,
            // New
            #[cfg(target_os = "linux")]
            181 => 0x000c0201,
            // Close
            #[cfg(target_os = "linux")]
            206 => 0x000c0203,
            // Save
            #[cfg(target_os = "linux")]
            234 => 0x000c0207,
            // Print
            #[cfg(target_os = "linux")]
            210 => 0x000c0208,
            // BrowserSearch
            #[cfg(target_os = "windows")]
            229 => 0x000c0221,
            #[cfg(target_os = "linux")]
            217 => 0x000c0221,
            // BrowserHome
            #[cfg(target_os = "windows")]
            226 => 0x000c0223,
            #[cfg(target_os = "linux")]
            172 => 0x000c0223,
            // BrowserBack
            #[cfg(target_os = "windows")]
            234 => 0x000c0224,
            #[cfg(target_os = "linux")]
            158 => 0x000c0224,
            // BrowserForward
            #[cfg(target_os = "windows")]
            233 => 0x000c0225,
            #[cfg(target_os = "linux")]
            159 => 0x000c0225,
            // BrowserStop
            #[cfg(target_os = "windows")]
            232 => 0x000c0226,
            #[cfg(target_os = "linux")]
            128 => 0x000c0226,
            // BrowserRefresh
            #[cfg(target_os = "windows")]
            231 => 0x000c0227,
            #[cfg(target_os = "linux")]
            173 => 0x000c0227,
            // BrowserFavorites
            #[cfg(target_os = "windows")]
            230 => 0x000c022a,
            #[cfg(target_os = "linux")]
            156 => 0x000c022a,
            // ZoomIn
            #[cfg(target_os = "linux")]
            418 => 0x000c022d,
            // ZoomOut
            #[cfg(target_os = "linux")]
            419 => 0x000c022e,
            // ZoomToggle
            #[cfg(target_os = "linux")]
            372 => 0x000c0232,
            // Redo
            #[cfg(target_os = "linux")]
            182 => 0x000c0279,
            // MailReply
            #[cfg(target_os = "linux")]
            232 => 0x000c0289,
            // MailForward
            #[cfg(target_os = "linux")]
            233 => 0x000c028b,
            // MailSend
            #[cfg(target_os = "linux")]
            231 => 0x000c028c,
            // KeyboardLayoutSelect
            #[cfg(target_os = "linux")]
            584 => 0x000c029d,
            // ShowAllWindows
            #[cfg(target_os = "linux")]
            120 => 0x000c029f,

            _ => 0,
        },
        _ => 0,
    }
}

#[frb(dart2rust(dart_type = "PhysicalKeyboardKey", dart_code = "{}.usbHidUsage"))]
pub fn decode_physical_keyboard_key_type(raw: u32) -> Key {
    match raw {
        // Fn
        #[cfg(target_os = "macos")]
        0x00000012 => Key::Other(63),
        // PrivacyScreenToggle
        #[cfg(target_os = "linux")]
        0x00000017 => Key::Other(633),
        // MicrophoneMuteToggle
        #[cfg(target_os = "linux")]
        0x00000018 => Key::Other(248),
        // Sleep
        #[cfg(target_os = "windows")]
        0x00010082 => Key::Other(95),
        #[cfg(target_os = "linux")]
        0x00010082 => Key::Other(142),
        // WakeUp
        #[cfg(target_os = "windows")]
        0x00010083 => Key::Other(232),
        #[cfg(target_os = "linux")]
        0x00010083 => Key::Other(143),
        // DisplayToggleIntExt
        #[cfg(target_os = "linux")]
        0x000100b5 => Key::Other(227),
        // KeyA
        #[cfg(target_os = "macos")]
        0x00070004 => Key::Other(0),
        #[cfg(target_os = "windows")]
        0x00070004 => Key::Other(65),
        #[cfg(target_os = "linux")]
        0x00070004 => Key::Other(30),
        // KeyB
        #[cfg(target_os = "macos")]
        0x00070005 => Key::Other(11),
        #[cfg(target_os = "windows")]
        0x00070005 => Key::Other(66),
        #[cfg(target_os = "linux")]
        0x00070005 => Key::Other(48),
        // KeyC
        #[cfg(target_os = "macos")]
        0x00070006 => Key::Other(8),
        #[cfg(target_os = "windows")]
        0x00070006 => Key::Other(67),
        #[cfg(target_os = "linux")]
        0x00070006 => Key::Other(46),
        // KeyD
        #[cfg(target_os = "macos")]
        0x00070007 => Key::Other(2),
        #[cfg(target_os = "windows")]
        0x00070007 => Key::Other(68),
        #[cfg(target_os = "linux")]
        0x00070007 => Key::Other(32),
        // KeyE
        #[cfg(target_os = "macos")]
        0x00070008 => Key::Other(14),
        #[cfg(target_os = "windows")]
        0x00070008 => Key::Other(69),
        #[cfg(target_os = "linux")]
        0x00070008 => Key::Other(18),
        // KeyF
        #[cfg(target_os = "macos")]
        0x00070009 => Key::Other(3),
        #[cfg(target_os = "windows")]
        0x00070009 => Key::Other(70),
        #[cfg(target_os = "linux")]
        0x00070009 => Key::Other(33),
        // KeyG
        #[cfg(target_os = "macos")]
        0x0007000a => Key::Other(5),
        #[cfg(target_os = "windows")]
        0x0007000a => Key::Other(71),
        #[cfg(target_os = "linux")]
        0x0007000a => Key::Other(34),
        // KeyH
        #[cfg(target_os = "macos")]
        0x0007000b => Key::Other(4),
        #[cfg(target_os = "windows")]
        0x0007000b => Key::Other(72),
        #[cfg(target_os = "linux")]
        0x0007000b => Key::Other(35),
        // KeyI
        #[cfg(target_os = "macos")]
        0x0007000c => Key::Other(34),
        #[cfg(target_os = "windows")]
        0x0007000c => Key::Other(73),
        #[cfg(target_os = "linux")]
        0x0007000c => Key::Other(23),
        // KeyJ
        #[cfg(target_os = "macos")]
        0x0007000d => Key::Other(38),
        #[cfg(target_os = "windows")]
        0x0007000d => Key::Other(74),
        #[cfg(target_os = "linux")]
        0x0007000d => Key::Other(36),
        // KeyK
        #[cfg(target_os = "macos")]
        0x0007000e => Key::Other(40),
        #[cfg(target_os = "windows")]
        0x0007000e => Key::Other(75),
        #[cfg(target_os = "linux")]
        0x0007000e => Key::Other(37),
        // KeyL
        #[cfg(target_os = "macos")]
        0x0007000f => Key::Other(37),
        #[cfg(target_os = "windows")]
        0x0007000f => Key::Other(76),
        #[cfg(target_os = "linux")]
        0x0007000f => Key::Other(38),
        // KeyM
        #[cfg(target_os = "macos")]
        0x00070010 => Key::Other(46),
        #[cfg(target_os = "windows")]
        0x00070010 => Key::Other(77),
        #[cfg(target_os = "linux")]
        0x00070010 => Key::Other(50),
        // KeyN
        #[cfg(target_os = "macos")]
        0x00070011 => Key::Other(45),
        #[cfg(target_os = "windows")]
        0x00070011 => Key::Other(78),
        #[cfg(target_os = "linux")]
        0x00070011 => Key::Other(49),
        // KeyO
        #[cfg(target_os = "macos")]
        0x00070012 => Key::Other(31),
        #[cfg(target_os = "windows")]
        0x00070012 => Key::Other(79),
        #[cfg(target_os = "linux")]
        0x00070012 => Key::Other(24),
        // KeyP
        #[cfg(target_os = "macos")]
        0x00070013 => Key::Other(35),
        #[cfg(target_os = "windows")]
        0x00070013 => Key::Other(80),
        #[cfg(target_os = "linux")]
        0x00070013 => Key::Other(25),
        // KeyQ
        #[cfg(target_os = "macos")]
        0x00070014 => Key::Other(12),
        #[cfg(target_os = "windows")]
        0x00070014 => Key::Other(81),
        #[cfg(target_os = "linux")]
        0x00070014 => Key::Other(16),
        // KeyR
        #[cfg(target_os = "macos")]
        0x00070015 => Key::Other(15),
        #[cfg(target_os = "windows")]
        0x00070015 => Key::Other(82),
        #[cfg(target_os = "linux")]
        0x00070015 => Key::Other(19),
        // KeyS
        #[cfg(target_os = "macos")]
        0x00070016 => Key::Other(1),
        #[cfg(target_os = "windows")]
        0x00070016 => Key::Other(83),
        #[cfg(target_os = "linux")]
        0x00070016 => Key::Other(31),
        // KeyT
        #[cfg(target_os = "macos")]
        0x00070017 => Key::Other(17),
        #[cfg(target_os = "windows")]
        0x00070017 => Key::Other(84),
        #[cfg(target_os = "linux")]
        0x00070017 => Key::Other(20),
        // KeyU
        #[cfg(target_os = "macos")]
        0x00070018 => Key::Other(32),
        #[cfg(target_os = "windows")]
        0x00070018 => Key::Other(85),
        #[cfg(target_os = "linux")]
        0x00070018 => Key::Other(22),
        // KeyV
        #[cfg(target_os = "macos")]
        0x00070019 => Key::Other(9),
        #[cfg(target_os = "windows")]
        0x00070019 => Key::Other(86),
        #[cfg(target_os = "linux")]
        0x00070019 => Key::Other(47),
        // KeyW
        #[cfg(target_os = "macos")]
        0x0007001a => Key::Other(13),
        #[cfg(target_os = "windows")]
        0x0007001a => Key::Other(87),
        #[cfg(target_os = "linux")]
        0x0007001a => Key::Other(17),
        // KeyX
        #[cfg(target_os = "macos")]
        0x0007001b => Key::Other(7),
        #[cfg(target_os = "windows")]
        0x0007001b => Key::Other(88),
        #[cfg(target_os = "linux")]
        0x0007001b => Key::Other(45),
        // KeyY
        #[cfg(target_os = "macos")]
        0x0007001c => Key::Other(16),
        #[cfg(target_os = "windows")]
        0x0007001c => Key::Other(89),
        #[cfg(target_os = "linux")]
        0x0007001c => Key::Other(21),
        // KeyZ
        #[cfg(target_os = "macos")]
        0x0007001d => Key::Other(6),
        #[cfg(target_os = "windows")]
        0x0007001d => Key::Other(90),
        #[cfg(target_os = "linux")]
        0x0007001d => Key::Other(44),
        // Digit1
        #[cfg(target_os = "macos")]
        0x0007001e => Key::Other(18),
        #[cfg(target_os = "windows")]
        0x0007001e => Key::Other(49),
        #[cfg(target_os = "linux")]
        0x0007001e => Key::Other(2),
        // Digit2
        #[cfg(target_os = "macos")]
        0x0007001f => Key::Other(19),
        #[cfg(target_os = "windows")]
        0x0007001f => Key::Other(50),
        #[cfg(target_os = "linux")]
        0x0007001f => Key::Other(3),
        // Digit3
        #[cfg(target_os = "macos")]
        0x00070020 => Key::Other(20),
        #[cfg(target_os = "windows")]
        0x00070020 => Key::Other(51),
        #[cfg(target_os = "linux")]
        0x00070020 => Key::Other(4),
        // Digit4
        #[cfg(target_os = "macos")]
        0x00070021 => Key::Other(21),
        #[cfg(target_os = "windows")]
        0x00070021 => Key::Other(52),
        #[cfg(target_os = "linux")]
        0x00070021 => Key::Other(5),
        // Digit5
        #[cfg(target_os = "macos")]
        0x00070022 => Key::Other(23),
        #[cfg(target_os = "windows")]
        0x00070022 => Key::Other(53),
        #[cfg(target_os = "linux")]
        0x00070022 => Key::Other(6),
        // Digit6
        #[cfg(target_os = "macos")]
        0x00070023 => Key::Other(22),
        #[cfg(target_os = "windows")]
        0x00070023 => Key::Other(54),
        #[cfg(target_os = "linux")]
        0x00070023 => Key::Other(7),
        // Digit7
        #[cfg(target_os = "macos")]
        0x00070024 => Key::Other(26),
        #[cfg(target_os = "windows")]
        0x00070024 => Key::Other(55),
        #[cfg(target_os = "linux")]
        0x00070024 => Key::Other(8),
        // Digit8
        #[cfg(target_os = "macos")]
        0x00070025 => Key::Other(28),
        #[cfg(target_os = "windows")]
        0x00070025 => Key::Other(56),
        #[cfg(target_os = "linux")]
        0x00070025 => Key::Other(9),
        // Digit9
        #[cfg(target_os = "macos")]
        0x00070026 => Key::Other(25),
        #[cfg(target_os = "windows")]
        0x00070026 => Key::Other(57),
        #[cfg(target_os = "linux")]
        0x00070026 => Key::Other(10),
        // Digit0
        #[cfg(target_os = "macos")]
        0x00070027 => Key::Other(29),
        #[cfg(target_os = "windows")]
        0x00070027 => Key::Other(48),
        #[cfg(target_os = "linux")]
        0x00070027 => Key::Other(11),
        // Enter
        #[cfg(target_os = "macos")]
        0x00070028 => Key::Other(36),
        #[cfg(target_os = "windows")]
        0x00070028 => Key::Other(13),
        #[cfg(target_os = "linux")]
        0x00070028 => Key::Other(28),
        // Escape
        #[cfg(target_os = "macos")]
        0x00070029 => Key::Other(53),
        #[cfg(target_os = "windows")]
        0x00070029 => Key::Other(27),
        #[cfg(target_os = "linux")]
        0x00070029 => Key::Other(1),
        // Backspace
        #[cfg(target_os = "macos")]
        0x0007002a => Key::Other(51),
        #[cfg(target_os = "windows")]
        0x0007002a => Key::Other(8),
        #[cfg(target_os = "linux")]
        0x0007002a => Key::Other(14),
        // Tab
        #[cfg(target_os = "macos")]
        0x0007002b => Key::Other(48),
        #[cfg(target_os = "windows")]
        0x0007002b => Key::Other(9),
        #[cfg(target_os = "linux")]
        0x0007002b => Key::Other(15),
        // Space
        #[cfg(target_os = "macos")]
        0x0007002c => Key::Other(49),
        #[cfg(target_os = "windows")]
        0x0007002c => Key::Other(32),
        #[cfg(target_os = "linux")]
        0x0007002c => Key::Other(57),
        // Minus
        #[cfg(target_os = "macos")]
        0x0007002d => Key::Other(27),
        #[cfg(target_os = "windows")]
        0x0007002d => Key::Other(189),
        #[cfg(target_os = "linux")]
        0x0007002d => Key::Other(12),
        // Equal
        #[cfg(target_os = "macos")]
        0x0007002e => Key::Other(24),
        #[cfg(target_os = "windows")]
        0x0007002e => Key::Other(187),
        #[cfg(target_os = "linux")]
        0x0007002e => Key::Other(13),
        // BracketLeft
        #[cfg(target_os = "macos")]
        0x0007002f => Key::Other(33),
        #[cfg(target_os = "windows")]
        0x0007002f => Key::Other(219),
        #[cfg(target_os = "linux")]
        0x0007002f => Key::Other(26),
        // BracketRight
        #[cfg(target_os = "macos")]
        0x00070030 => Key::Other(30),
        #[cfg(target_os = "windows")]
        0x00070030 => Key::Other(221),
        #[cfg(target_os = "linux")]
        0x00070030 => Key::Other(27),
        // Backslash
        #[cfg(target_os = "macos")]
        0x00070031 => Key::Other(42),
        #[cfg(target_os = "windows")]
        0x00070031 => Key::Other(220),
        #[cfg(target_os = "linux")]
        0x00070031 => Key::Other(43),
        // Semicolon
        #[cfg(target_os = "macos")]
        0x00070033 => Key::Other(41),
        #[cfg(target_os = "windows")]
        0x00070033 => Key::Other(186),
        #[cfg(target_os = "linux")]
        0x00070033 => Key::Other(39),
        // Quote
        #[cfg(target_os = "macos")]
        0x00070034 => Key::Other(39),
        #[cfg(target_os = "windows")]
        0x00070034 => Key::Other(222),
        #[cfg(target_os = "linux")]
        0x00070034 => Key::Other(40),
        // Backquote
        #[cfg(target_os = "macos")]
        0x00070035 => Key::Other(50),
        #[cfg(target_os = "windows")]
        0x00070035 => Key::Other(192),
        #[cfg(target_os = "linux")]
        0x00070035 => Key::Other(41),
        // Comma
        #[cfg(target_os = "macos")]
        0x00070036 => Key::Other(43),
        #[cfg(target_os = "windows")]
        0x00070036 => Key::Other(188),
        #[cfg(target_os = "linux")]
        0x00070036 => Key::Other(51),
        // Period
        #[cfg(target_os = "macos")]
        0x00070037 => Key::Other(47),
        #[cfg(target_os = "windows")]
        0x00070037 => Key::Other(190),
        #[cfg(target_os = "linux")]
        0x00070037 => Key::Other(52),
        // Slash
        #[cfg(target_os = "macos")]
        0x00070038 => Key::Other(44),
        #[cfg(target_os = "windows")]
        0x00070038 => Key::Other(191),
        #[cfg(target_os = "linux")]
        0x00070038 => Key::Other(53),
        // CapsLock
        #[cfg(target_os = "macos")]
        0x00070039 => Key::Other(57),
        #[cfg(target_os = "windows")]
        0x00070039 => Key::Other(20),
        #[cfg(target_os = "linux")]
        0x00070039 => Key::Other(58),
        // F1
        #[cfg(target_os = "macos")]
        0x0007003a => Key::Other(122),
        #[cfg(target_os = "windows")]
        0x0007003a => Key::Other(112),
        #[cfg(target_os = "linux")]
        0x0007003a => Key::Other(59),
        // F2
        #[cfg(target_os = "macos")]
        0x0007003b => Key::Other(120),
        #[cfg(target_os = "windows")]
        0x0007003b => Key::Other(113),
        #[cfg(target_os = "linux")]
        0x0007003b => Key::Other(60),
        // F3
        #[cfg(target_os = "macos")]
        0x0007003c => Key::Other(99),
        #[cfg(target_os = "windows")]
        0x0007003c => Key::Other(114),
        #[cfg(target_os = "linux")]
        0x0007003c => Key::Other(61),
        // F4
        #[cfg(target_os = "macos")]
        0x0007003d => Key::Other(118),
        #[cfg(target_os = "windows")]
        0x0007003d => Key::Other(115),
        #[cfg(target_os = "linux")]
        0x0007003d => Key::Other(62),
        // F5
        #[cfg(target_os = "macos")]
        0x0007003e => Key::Other(96),
        #[cfg(target_os = "windows")]
        0x0007003e => Key::Other(116),
        #[cfg(target_os = "linux")]
        0x0007003e => Key::Other(63),
        // F6
        #[cfg(target_os = "macos")]
        0x0007003f => Key::Other(97),
        #[cfg(target_os = "windows")]
        0x0007003f => Key::Other(117),
        #[cfg(target_os = "linux")]
        0x0007003f => Key::Other(64),
        // F7
        #[cfg(target_os = "macos")]
        0x00070040 => Key::Other(98),
        #[cfg(target_os = "windows")]
        0x00070040 => Key::Other(118),
        #[cfg(target_os = "linux")]
        0x00070040 => Key::Other(65),
        // F8
        #[cfg(target_os = "macos")]
        0x00070041 => Key::Other(100),
        #[cfg(target_os = "windows")]
        0x00070041 => Key::Other(119),
        #[cfg(target_os = "linux")]
        0x00070041 => Key::Other(66),
        // F9
        #[cfg(target_os = "macos")]
        0x00070042 => Key::Other(101),
        #[cfg(target_os = "windows")]
        0x00070042 => Key::Other(120),
        #[cfg(target_os = "linux")]
        0x00070042 => Key::Other(67),
        // F10
        #[cfg(target_os = "macos")]
        0x00070043 => Key::Other(109),
        #[cfg(target_os = "windows")]
        0x00070043 => Key::Other(121),
        #[cfg(target_os = "linux")]
        0x00070043 => Key::Other(68),
        // F11
        #[cfg(target_os = "macos")]
        0x00070044 => Key::Other(103),
        #[cfg(target_os = "windows")]
        0x00070044 => Key::Other(122),
        #[cfg(target_os = "linux")]
        0x00070044 => Key::Other(87),
        // F12
        #[cfg(target_os = "macos")]
        0x00070045 => Key::Other(111),
        #[cfg(target_os = "windows")]
        0x00070045 => Key::Other(123),
        #[cfg(target_os = "linux")]
        0x00070045 => Key::Other(88),
        // PrintScreen
        #[cfg(target_os = "windows")]
        0x00070046 => Key::Other(44),
        #[cfg(target_os = "linux")]
        0x00070046 => Key::Other(99),
        // ScrollLock
        #[cfg(target_os = "windows")]
        0x00070047 => Key::Other(3),
        #[cfg(target_os = "linux")]
        0x00070047 => Key::Other(70),
        // Pause
        #[cfg(target_os = "windows")]
        0x00070048 => Key::Other(19),
        #[cfg(target_os = "linux")]
        0x00070048 => Key::Other(119),
        // Insert
        #[cfg(target_os = "macos")]
        0x00070049 => Key::Other(114),
        #[cfg(target_os = "windows")]
        0x00070049 => Key::Other(45),
        #[cfg(target_os = "linux")]
        0x00070049 => Key::Other(110),
        // Home
        #[cfg(target_os = "macos")]
        0x0007004a => Key::Other(115),
        #[cfg(target_os = "windows")]
        0x0007004a => Key::Other(36),
        #[cfg(target_os = "linux")]
        0x0007004a => Key::Other(102),
        // PageUp
        #[cfg(target_os = "macos")]
        0x0007004b => Key::Other(116),
        #[cfg(target_os = "windows")]
        0x0007004b => Key::Other(33),
        #[cfg(target_os = "linux")]
        0x0007004b => Key::Other(104),
        // Delete
        #[cfg(target_os = "macos")]
        0x0007004c => Key::Other(117),
        #[cfg(target_os = "windows")]
        0x0007004c => Key::Other(46),
        #[cfg(target_os = "linux")]
        0x0007004c => Key::Other(111),
        // End
        #[cfg(target_os = "macos")]
        0x0007004d => Key::Other(119),
        #[cfg(target_os = "windows")]
        0x0007004d => Key::Other(35),
        #[cfg(target_os = "linux")]
        0x0007004d => Key::Other(107),
        // PageDown
        #[cfg(target_os = "macos")]
        0x0007004e => Key::Other(121),
        #[cfg(target_os = "windows")]
        0x0007004e => Key::Other(34),
        #[cfg(target_os = "linux")]
        0x0007004e => Key::Other(109),
        // ArrowRight
        #[cfg(target_os = "macos")]
        0x0007004f => Key::Other(124),
        #[cfg(target_os = "windows")]
        0x0007004f => Key::Other(39),
        #[cfg(target_os = "linux")]
        0x0007004f => Key::Other(106),
        // ArrowLeft
        #[cfg(target_os = "macos")]
        0x00070050 => Key::Other(123),
        #[cfg(target_os = "windows")]
        0x00070050 => Key::Other(37),
        #[cfg(target_os = "linux")]
        0x00070050 => Key::Other(105),
        // ArrowDown
        #[cfg(target_os = "macos")]
        0x00070051 => Key::Other(125),
        #[cfg(target_os = "windows")]
        0x00070051 => Key::Other(40),
        #[cfg(target_os = "linux")]
        0x00070051 => Key::Other(108),
        // ArrowUp
        #[cfg(target_os = "macos")]
        0x00070052 => Key::Other(126),
        #[cfg(target_os = "windows")]
        0x00070052 => Key::Other(38),
        #[cfg(target_os = "linux")]
        0x00070052 => Key::Other(103),
        // NumLock
        #[cfg(target_os = "macos")]
        0x00070053 => Key::Other(71),
        #[cfg(target_os = "windows")]
        0x00070053 => Key::Other(144),
        #[cfg(target_os = "linux")]
        0x00070053 => Key::Other(69),
        // NumpadDivide
        #[cfg(target_os = "macos")]
        0x00070054 => Key::Other(75),
        #[cfg(target_os = "windows")]
        0x00070054 => Key::Other(111),
        #[cfg(target_os = "linux")]
        0x00070054 => Key::Other(98),
        // NumpadMultiply
        #[cfg(target_os = "macos")]
        0x00070055 => Key::Other(67),
        #[cfg(target_os = "windows")]
        0x00070055 => Key::Other(106),
        #[cfg(target_os = "linux")]
        0x00070055 => Key::Other(55),
        // NumpadSubtract
        #[cfg(target_os = "macos")]
        0x00070056 => Key::Other(78),
        #[cfg(target_os = "windows")]
        0x00070056 => Key::Other(109),
        #[cfg(target_os = "linux")]
        0x00070056 => Key::Other(74),
        // NumpadAdd
        #[cfg(target_os = "macos")]
        0x00070057 => Key::Other(69),
        #[cfg(target_os = "windows")]
        0x00070057 => Key::Other(107),
        #[cfg(target_os = "linux")]
        0x00070057 => Key::Other(78),
        // NumpadEnter
        #[cfg(target_os = "macos")]
        0x00070058 => Key::Other(76),
        #[cfg(target_os = "windows")]
        0x00070058 => Key::Other(13),
        #[cfg(target_os = "linux")]
        0x00070058 => Key::Other(96),
        // Numpad1
        #[cfg(target_os = "macos")]
        0x00070059 => Key::Other(83),
        #[cfg(target_os = "windows")]
        0x00070059 => Key::Other(97),
        #[cfg(target_os = "linux")]
        0x00070059 => Key::Other(79),
        // Numpad2
        #[cfg(target_os = "macos")]
        0x0007005a => Key::Other(84),
        #[cfg(target_os = "windows")]
        0x0007005a => Key::Other(98),
        #[cfg(target_os = "linux")]
        0x0007005a => Key::Other(80),
        // Numpad3
        #[cfg(target_os = "macos")]
        0x0007005b => Key::Other(85),
        #[cfg(target_os = "windows")]
        0x0007005b => Key::Other(99),
        #[cfg(target_os = "linux")]
        0x0007005b => Key::Other(81),
        // Numpad4
        #[cfg(target_os = "macos")]
        0x0007005c => Key::Other(86),
        #[cfg(target_os = "windows")]
        0x0007005c => Key::Other(100),
        #[cfg(target_os = "linux")]
        0x0007005c => Key::Other(75),
        // Numpad5
        #[cfg(target_os = "macos")]
        0x0007005d => Key::Other(87),
        #[cfg(target_os = "windows")]
        0x0007005d => Key::Other(101),
        #[cfg(target_os = "linux")]
        0x0007005d => Key::Other(76),
        // Numpad6
        #[cfg(target_os = "macos")]
        0x0007005e => Key::Other(88),
        #[cfg(target_os = "windows")]
        0x0007005e => Key::Other(102),
        #[cfg(target_os = "linux")]
        0x0007005e => Key::Other(77),
        // Numpad7
        #[cfg(target_os = "macos")]
        0x0007005f => Key::Other(89),
        #[cfg(target_os = "windows")]
        0x0007005f => Key::Other(103),
        #[cfg(target_os = "linux")]
        0x0007005f => Key::Other(71),
        // Numpad8
        #[cfg(target_os = "macos")]
        0x00070060 => Key::Other(91),
        #[cfg(target_os = "windows")]
        0x00070060 => Key::Other(104),
        #[cfg(target_os = "linux")]
        0x00070060 => Key::Other(72),
        // Numpad9
        #[cfg(target_os = "macos")]
        0x00070061 => Key::Other(92),
        #[cfg(target_os = "windows")]
        0x00070061 => Key::Other(105),
        #[cfg(target_os = "linux")]
        0x00070061 => Key::Other(73),
        // Numpad0
        #[cfg(target_os = "macos")]
        0x00070062 => Key::Other(82),
        #[cfg(target_os = "windows")]
        0x00070062 => Key::Other(96),
        #[cfg(target_os = "linux")]
        0x00070062 => Key::Other(82),
        // NumpadDecimal
        #[cfg(target_os = "macos")]
        0x00070063 => Key::Other(65),
        #[cfg(target_os = "windows")]
        0x00070063 => Key::Other(110),
        #[cfg(target_os = "linux")]
        0x00070063 => Key::Other(83),
        // IntlBackslash
        #[cfg(target_os = "macos")]
        0x00070064 => Key::Other(10),
        #[cfg(target_os = "windows")]
        0x00070064 => Key::Other(226),
        #[cfg(target_os = "linux")]
        0x00070064 => Key::Other(86),
        // ContextMenu
        #[cfg(target_os = "macos")]
        0x00070065 => Key::Other(110),
        #[cfg(target_os = "windows")]
        0x00070065 => Key::Other(93),
        #[cfg(target_os = "linux")]
        0x00070065 => Key::Other(127),
        // Power
        #[cfg(target_os = "windows")]
        0x00070066 => Key::Other(229),
        #[cfg(target_os = "linux")]
        0x00070066 => Key::Other(116),
        // NumpadEqual
        #[cfg(target_os = "macos")]
        0x00070067 => Key::Other(81),
        #[cfg(target_os = "windows")]
        0x00070067 => Key::Other(146),
        #[cfg(target_os = "linux")]
        0x00070067 => Key::Other(117),
        // F13
        #[cfg(target_os = "macos")]
        0x00070068 => Key::Other(105),
        #[cfg(target_os = "windows")]
        0x00070068 => Key::Other(124),
        #[cfg(target_os = "linux")]
        0x00070068 => Key::Other(183),
        // F14
        #[cfg(target_os = "macos")]
        0x00070069 => Key::Other(107),
        #[cfg(target_os = "windows")]
        0x00070069 => Key::Other(125),
        #[cfg(target_os = "linux")]
        0x00070069 => Key::Other(184),
        // F15
        #[cfg(target_os = "macos")]
        0x0007006a => Key::Other(113),
        #[cfg(target_os = "windows")]
        0x0007006a => Key::Other(126),
        #[cfg(target_os = "linux")]
        0x0007006a => Key::Other(185),
        // F16
        #[cfg(target_os = "macos")]
        0x0007006b => Key::Other(106),
        #[cfg(target_os = "windows")]
        0x0007006b => Key::Other(127),
        #[cfg(target_os = "linux")]
        0x0007006b => Key::Other(186),
        // F17
        #[cfg(target_os = "macos")]
        0x0007006c => Key::Other(64),
        #[cfg(target_os = "windows")]
        0x0007006c => Key::Other(128),
        #[cfg(target_os = "linux")]
        0x0007006c => Key::Other(187),
        // F18
        #[cfg(target_os = "macos")]
        0x0007006d => Key::Other(79),
        #[cfg(target_os = "windows")]
        0x0007006d => Key::Other(129),
        #[cfg(target_os = "linux")]
        0x0007006d => Key::Other(188),
        // F19
        #[cfg(target_os = "macos")]
        0x0007006e => Key::Other(80),
        #[cfg(target_os = "windows")]
        0x0007006e => Key::Other(130),
        #[cfg(target_os = "linux")]
        0x0007006e => Key::Other(189),
        // F20
        #[cfg(target_os = "macos")]
        0x0007006f => Key::Other(90),
        #[cfg(target_os = "windows")]
        0x0007006f => Key::Other(131),
        #[cfg(target_os = "linux")]
        0x0007006f => Key::Other(190),
        // F21
        #[cfg(target_os = "windows")]
        0x00070070 => Key::Other(132),
        #[cfg(target_os = "linux")]
        0x00070070 => Key::Other(191),
        // F22
        #[cfg(target_os = "windows")]
        0x00070071 => Key::Other(133),
        #[cfg(target_os = "linux")]
        0x00070071 => Key::Other(192),
        // F23
        #[cfg(target_os = "windows")]
        0x00070072 => Key::Other(134),
        #[cfg(target_os = "linux")]
        0x00070072 => Key::Other(193),
        // F24
        #[cfg(target_os = "windows")]
        0x00070073 => Key::Other(135),
        #[cfg(target_os = "linux")]
        0x00070073 => Key::Other(194),
        // Open
        #[cfg(target_os = "linux")]
        0x00070074 => Key::Other(134),
        // Help
        #[cfg(target_os = "windows")]
        0x00070075 => Key::Other(47),
        #[cfg(target_os = "linux")]
        0x00070075 => Key::Other(138),
        // Select
        #[cfg(target_os = "linux")]
        0x00070077 => Key::Other(132),
        // Again
        #[cfg(target_os = "linux")]
        0x00070079 => Key::Other(129),
        // Undo
        #[cfg(target_os = "linux")]
        0x0007007a => Key::Other(131),
        // Cut
        #[cfg(target_os = "linux")]
        0x0007007b => Key::Other(137),
        // Copy
        #[cfg(target_os = "linux")]
        0x0007007c => Key::Other(133),
        // Paste
        #[cfg(target_os = "linux")]
        0x0007007d => Key::Other(135),
        // Find
        #[cfg(target_os = "linux")]
        0x0007007e => Key::Other(136),
        // NumpadComma
        #[cfg(target_os = "macos")]
        0x00070085 => Key::Other(95),
        #[cfg(target_os = "windows")]
        0x00070085 => Key::Other(188),
        #[cfg(target_os = "linux")]
        0x00070085 => Key::Other(121),
        // IntlRo
        #[cfg(target_os = "macos")]
        0x00070087 => Key::Other(94),
        #[cfg(target_os = "windows")]
        0x00070087 => Key::Other(115),
        #[cfg(target_os = "linux")]
        0x00070087 => Key::Other(89),
        // KanaMode
        #[cfg(target_os = "windows")]
        0x00070088 => Key::Other(21),
        #[cfg(target_os = "linux")]
        0x00070088 => Key::Other(93),
        // IntlYen
        #[cfg(target_os = "macos")]
        0x00070089 => Key::Other(93),
        #[cfg(target_os = "windows")]
        0x00070089 => Key::Other(125),
        #[cfg(target_os = "linux")]
        0x00070089 => Key::Other(124),
        // Convert
        #[cfg(target_os = "windows")]
        0x0007008a => Key::Other(28),
        #[cfg(target_os = "linux")]
        0x0007008a => Key::Other(92),
        // NonConvert
        #[cfg(target_os = "windows")]
        0x0007008b => Key::Other(29),
        #[cfg(target_os = "linux")]
        0x0007008b => Key::Other(94),
        // Lang1
        #[cfg(target_os = "macos")]
        0x00070090 => Key::Other(104),
        #[cfg(target_os = "windows")]
        0x00070090 => Key::Other(114),
        #[cfg(target_os = "linux")]
        0x00070090 => Key::Other(122),
        // Lang2
        #[cfg(target_os = "macos")]
        0x00070091 => Key::Other(102),
        #[cfg(target_os = "windows")]
        0x00070091 => Key::Other(113),
        #[cfg(target_os = "linux")]
        0x00070091 => Key::Other(123),
        // Lang3
        #[cfg(target_os = "windows")]
        0x00070092 => Key::Other(120),
        #[cfg(target_os = "linux")]
        0x00070092 => Key::Other(90),
        // Lang4
        #[cfg(target_os = "windows")]
        0x00070093 => Key::Other(119),
        #[cfg(target_os = "linux")]
        0x00070093 => Key::Other(91),
        // Lang5
        #[cfg(target_os = "linux")]
        0x00070094 => Key::Other(85),
        // NumpadParenLeft
        #[cfg(target_os = "linux")]
        0x000700b6 => Key::Other(179),
        // NumpadParenRight
        #[cfg(target_os = "linux")]
        0x000700b7 => Key::Other(180),
        // NumpadSignChange
        #[cfg(target_os = "linux")]
        0x000700d7 => Key::Other(118),
        // ControlLeft
        #[cfg(target_os = "macos")]
        0x000700e0 => Key::Other(59),
        #[cfg(target_os = "windows")]
        0x000700e0 => Key::Other(17),
        #[cfg(target_os = "linux")]
        0x000700e0 => Key::Other(29),
        // ShiftLeft
        #[cfg(target_os = "macos")]
        0x000700e1 => Key::Other(56),
        #[cfg(target_os = "windows")]
        0x000700e1 => Key::Other(16),
        #[cfg(target_os = "linux")]
        0x000700e1 => Key::Other(42),
        // AltLeft
        #[cfg(target_os = "macos")]
        0x000700e2 => Key::Other(58),
        #[cfg(target_os = "windows")]
        0x000700e2 => Key::Other(18),
        #[cfg(target_os = "linux")]
        0x000700e2 => Key::Other(56),
        // MetaLeft
        #[cfg(target_os = "macos")]
        0x000700e3 => Key::Other(55),
        #[cfg(target_os = "windows")]
        0x000700e3 => Key::Other(91),
        #[cfg(target_os = "linux")]
        0x000700e3 => Key::Other(125),
        // ControlRight
        #[cfg(target_os = "macos")]
        0x000700e4 => Key::Other(62),
        #[cfg(target_os = "windows")]
        0x000700e4 => Key::Other(163),
        #[cfg(target_os = "linux")]
        0x000700e4 => Key::Other(97),
        // ShiftRight
        #[cfg(target_os = "macos")]
        0x000700e5 => Key::Other(60),
        #[cfg(target_os = "windows")]
        0x000700e5 => Key::Other(161),
        #[cfg(target_os = "linux")]
        0x000700e5 => Key::Other(54),
        // AltRight
        #[cfg(target_os = "macos")]
        0x000700e6 => Key::Other(61),
        #[cfg(target_os = "windows")]
        0x000700e6 => Key::Other(165),
        #[cfg(target_os = "linux")]
        0x000700e6 => Key::Other(100),
        // MetaRight
        #[cfg(target_os = "macos")]
        0x000700e7 => Key::Other(54),
        #[cfg(target_os = "windows")]
        0x000700e7 => Key::Other(92),
        #[cfg(target_os = "linux")]
        0x000700e7 => Key::Other(126),
        // Info
        #[cfg(target_os = "linux")]
        0x000c0060 => Key::Other(358),
        // ClosedCaptionToggle
        #[cfg(target_os = "linux")]
        0x000c0061 => Key::Other(370),
        // BrightnessToggle
        #[cfg(target_os = "linux")]
        0x000c0072 => Key::Other(431),
        // BrightnessMinimum
        #[cfg(target_os = "linux")]
        0x000c0073 => Key::Other(592),
        // BrightnessMaximum
        #[cfg(target_os = "linux")]
        0x000c0074 => Key::Other(593),
        // BrightnessAuto
        #[cfg(target_os = "linux")]
        0x000c0075 => Key::Other(244),
        // MediaLast
        #[cfg(target_os = "linux")]
        0x000c0083 => Key::Other(405),
        // LaunchPhone
        #[cfg(target_os = "linux")]
        0x000c008c => Key::Other(169),
        // ProgramGuide
        #[cfg(target_os = "linux")]
        0x000c008d => Key::Other(362),
        // Exit
        #[cfg(target_os = "linux")]
        0x000c0094 => Key::Other(174),
        // ChannelUp
        #[cfg(target_os = "linux")]
        0x000c009c => Key::Other(410),
        // ChannelDown
        #[cfg(target_os = "linux")]
        0x000c009d => Key::Other(411),
        // MediaPlay
        #[cfg(target_os = "linux")]
        0x000c00b0 => Key::Other(207),
        // MediaPause
        #[cfg(target_os = "linux")]
        0x000c00b1 => Key::Other(201),
        // MediaRecord
        #[cfg(target_os = "linux")]
        0x000c00b2 => Key::Other(167),
        // MediaStop
        #[cfg(target_os = "windows")]
        0x000c00b7 => Key::Other(233),
        #[cfg(target_os = "linux")]
        0x000c00b7 => Key::Other(166),
        // Eject
        #[cfg(target_os = "windows")]
        0x000c00b8 => Key::Other(238),
        #[cfg(target_os = "linux")]
        0x000c00b8 => Key::Other(161),
        // SpeechInputToggle
        #[cfg(target_os = "linux")]
        0x000c00cf => Key::Other(582),
        // BassBoost
        #[cfg(target_os = "linux")]
        0x000c00e5 => Key::Other(209),
        // MediaSelect
        #[cfg(target_os = "windows")]
        0x000c0183 => Key::Other(237),
        #[cfg(target_os = "linux")]
        0x000c0183 => Key::Other(171),
        // LaunchWordProcessor
        #[cfg(target_os = "linux")]
        0x000c0184 => Key::Other(421),
        // LaunchSpreadsheet
        #[cfg(target_os = "linux")]
        0x000c0186 => Key::Other(423),
        // LaunchMail
        #[cfg(target_os = "windows")]
        0x000c018a => Key::Other(236),
        #[cfg(target_os = "linux")]
        0x000c018a => Key::Other(155),
        // LaunchContacts
        #[cfg(target_os = "linux")]
        0x000c018d => Key::Other(429),
        // LaunchCalendar
        #[cfg(target_os = "linux")]
        0x000c018e => Key::Other(397),
        // LaunchApp2
        #[cfg(target_os = "windows")]
        0x000c0192 => Key::Other(225),
        #[cfg(target_os = "linux")]
        0x000c0192 => Key::Other(140),
        // LaunchApp1
        #[cfg(target_os = "windows")]
        0x000c0194 => Key::Other(235),
        #[cfg(target_os = "linux")]
        0x000c0194 => Key::Other(144),
        // LaunchInternetBrowser
        #[cfg(target_os = "linux")]
        0x000c0196 => Key::Other(150),
        // LogOff
        #[cfg(target_os = "linux")]
        0x000c019c => Key::Other(433),
        // LockScreen
        #[cfg(target_os = "linux")]
        0x000c019e => Key::Other(152),
        // LaunchControlPanel
        #[cfg(target_os = "linux")]
        0x000c019f => Key::Other(579),
        // SelectTask
        #[cfg(target_os = "linux")]
        0x000c01a2 => Key::Other(580),
        // LaunchDocuments
        #[cfg(target_os = "linux")]
        0x000c01a7 => Key::Other(235),
        // SpellCheck
        #[cfg(target_os = "linux")]
        0x000c01ab => Key::Other(432),
        // LaunchKeyboardLayout
        #[cfg(target_os = "linux")]
        0x000c01ae => Key::Other(374),
        // LaunchScreenSaver
        #[cfg(target_os = "linux")]
        0x000c01b1 => Key::Other(581),
        // LaunchAudioBrowser
        #[cfg(target_os = "linux")]
        0x000c01b7 => Key::Other(392),
        // LaunchAssistant
        #[cfg(target_os = "linux")]
        0x000c01cb => Key::Other(583),
        // New
        #[cfg(target_os = "linux")]
        0x000c0201 => Key::Other(181),
        // Close
        #[cfg(target_os = "linux")]
        0x000c0203 => Key::Other(206),
        // Save
        #[cfg(target_os = "linux")]
        0x000c0207 => Key::Other(234),
        // Print
        #[cfg(target_os = "linux")]
        0x000c0208 => Key::Other(210),
        // BrowserSearch
        #[cfg(target_os = "windows")]
        0x000c0221 => Key::Other(229),
        #[cfg(target_os = "linux")]
        0x000c0221 => Key::Other(217),
        // BrowserHome
        #[cfg(target_os = "windows")]
        0x000c0223 => Key::Other(226),
        #[cfg(target_os = "linux")]
        0x000c0223 => Key::Other(172),
        // BrowserBack
        #[cfg(target_os = "windows")]
        0x000c0224 => Key::Other(234),
        #[cfg(target_os = "linux")]
        0x000c0224 => Key::Other(158),
        // BrowserForward
        #[cfg(target_os = "windows")]
        0x000c0225 => Key::Other(233),
        #[cfg(target_os = "linux")]
        0x000c0225 => Key::Other(159),
        // BrowserStop
        #[cfg(target_os = "windows")]
        0x000c0226 => Key::Other(232),
        #[cfg(target_os = "linux")]
        0x000c0226 => Key::Other(128),
        // BrowserRefresh
        #[cfg(target_os = "windows")]
        0x000c0227 => Key::Other(231),
        #[cfg(target_os = "linux")]
        0x000c0227 => Key::Other(173),
        // BrowserFavorites
        #[cfg(target_os = "windows")]
        0x000c022a => Key::Other(230),
        #[cfg(target_os = "linux")]
        0x000c022a => Key::Other(156),
        // ZoomIn
        #[cfg(target_os = "linux")]
        0x000c022d => Key::Other(418),
        // ZoomOut
        #[cfg(target_os = "linux")]
        0x000c022e => Key::Other(419),
        // ZoomToggle
        #[cfg(target_os = "linux")]
        0x000c0232 => Key::Other(372),
        // Redo
        #[cfg(target_os = "linux")]
        0x000c0279 => Key::Other(182),
        // MailReply
        #[cfg(target_os = "linux")]
        0x000c0289 => Key::Other(232),
        // MailForward
        #[cfg(target_os = "linux")]
        0x000c028b => Key::Other(233),
        // MailSend
        #[cfg(target_os = "linux")]
        0x000c028c => Key::Other(231),
        // KeyboardLayoutSelect
        #[cfg(target_os = "linux")]
        0x000c029d => Key::Other(584),
        // ShowAllWindows
        #[cfg(target_os = "linux")]
        0x000c029f => Key::Other(120),

        // 需要特殊处理
        0x00070080 => Key::VolumeUp,
        0x00070081 => Key::VolumeDown,
        0x0007007f => Key::VolumeMute,
        #[cfg(target_os = "macos")]
        0x000c0079 => Key::BrightnessUp,
        #[cfg(target_os = "macos")]
        0x000c007a => Key::BrightnessDown,
        #[cfg(target_os = "macos")]
        0x00070066 => Key::Power,
        // => Key::ContrastUp ,
        // => Key::ContrastDown ,
        #[cfg(target_os = "macos")]
        0x000c019f => Key::LaunchPanel,
        #[cfg(target_os = "macos")]
        0x000c00b8 => Key::Eject,
        // => Key::VidMirror ,
        0x000c00cd => Key::MediaPlayPause,
        0x000c00b5 => Key::MediaNextTrack,
        0x000c00b6 => Key::MediaPrevTrack,
        #[cfg(target_os = "macos")]
        0x000c0083 => Key::MediaFast,
        #[cfg(target_os = "macos")]
        0x000c00b4 => Key::MediaRewind,
        #[cfg(target_os = "macos")]
        0x000c006f => Key::IlluminationUp,
        #[cfg(target_os = "macos")]
        0x000c0070 => Key::IlluminationDown,
        #[cfg(target_os = "macos")]
        0x000c0072 => Key::IlluminationToggle,

        _ => Key::Other(0),
    }
}

#[frb(init)]
pub fn init_app() {
    setup_default_user_utils();
}

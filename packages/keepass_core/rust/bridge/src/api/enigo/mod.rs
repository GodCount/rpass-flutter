use flutter_rust_bridge::*;

#[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
mod desktop;
#[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
pub use desktop::Key;

#[cfg(not(any(target_os = "windows", target_os = "linux", target_os = "macos")))]
mod mobile;
#[cfg(not(any(target_os = "windows", target_os = "linux", target_os = "macos")))]
pub use mobile::Key;

#[frb]
pub enum Button {
    Left,
    Middle,
    Right,
    Back,
    Forward,
    ScrollUp,
    ScrollDown,
    ScrollLeft,
    ScrollRight,
}

#[frb]
pub enum Direction {
    Press,
    Release,
    Click,
}

#[frb]
pub enum Coordinate {
    Abs,
    Rel,
}

#[frb]
pub enum Axis {
    Horizontal,
    Vertical,
}

#[frb(opaque)]
pub struct Enigo {
    #[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
    enigo_impl: desktop::EnigoImpl,
    #[cfg(not(any(target_os = "windows", target_os = "linux", target_os = "macos")))]
    enigo_impl: mobile::EnigoImpl,
}

impl Enigo {
    #[frb(sync)]
    pub fn preset() -> anyhow::Result<Self> {
        Ok(Self {
            #[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
            enigo_impl: desktop::EnigoImpl::preset()?,
            #[cfg(not(any(target_os = "windows", target_os = "linux", target_os = "macos")))]
            enigo_impl: mobile::EnigoImpl::preset()?,
        })
    }

    #[frb(sync)]
    pub fn has_permission(open_prompt: bool) -> bool {
        #[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
        {
            return desktop::EnigoImpl::has_permission(open_prompt);
        }
        #[cfg(not(any(target_os = "windows", target_os = "linux", target_os = "macos")))]
        {
            return mobile::EnigoImpl::has_permission(open_prompt);
        }
    }

    #[frb(sync)]
    pub fn button(&mut self, button: Button, direction: Direction) -> anyhow::Result<()> {
        self.enigo_impl.button(button, direction)
    }

    #[frb(sync)]
    pub fn move_mouse(&mut self, x: i32, y: i32, coordinate: Coordinate) -> anyhow::Result<()> {
        self.enigo_impl.move_mouse(x, y, coordinate)
    }

    #[frb(sync)]
    pub fn scroll(&mut self, length: i32, axis: Axis) -> anyhow::Result<()> {
        self.enigo_impl.scroll(length, axis)
    }

    #[frb(sync)]
    pub fn main_display(&self) -> anyhow::Result<(i32, i32)> {
        self.enigo_impl.main_display()
    }

    #[frb(sync)]
    pub fn location(&self) -> anyhow::Result<(i32, i32)> {
        self.enigo_impl.location()
    }

    #[frb(sync)]
    pub fn text(&mut self, text: &str) -> anyhow::Result<()> {
        self.enigo_impl.text(text)
    }

    #[frb(sync)]
    pub fn key(&mut self, key: Key, direction: Direction) -> anyhow::Result<()> {
        self.enigo_impl.key(key, direction)
    }

    #[frb(sync)]
    pub fn raw(&mut self, keycode: u16, direction: Direction) -> anyhow::Result<()> {
        self.enigo_impl.raw(keycode, direction)
    }
}

#[frb(rust2dart(
    dart_type = "PhysicalKeyboardKey",
    dart_code = "PhysicalKeyboardKey({})"
))]
pub fn encode_physical_keyboard_key_type(raw: Key) -> u32 {
    #[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
    {
        return desktop::encode_physical_keyboard_key_type(raw);
    }
    #[cfg(not(any(target_os = "windows", target_os = "linux", target_os = "macos")))]
    {
        return mobile::encode_physical_keyboard_key_type(raw);
    }
}

#[frb(dart2rust(dart_type = "PhysicalKeyboardKey", dart_code = "{}.usbHidUsage"))]
pub fn decode_physical_keyboard_key_type(raw: u32) -> Key {
    #[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
    {
        return desktop::decode_physical_keyboard_key_type(raw);
    }
    #[cfg(not(any(target_os = "windows", target_os = "linux", target_os = "macos")))]
    {
        return mobile::decode_physical_keyboard_key_type(raw);
    }
}

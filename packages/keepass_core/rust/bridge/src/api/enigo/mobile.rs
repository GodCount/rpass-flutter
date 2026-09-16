use flutter_rust_bridge::frb;

#[frb(ignore)]
pub(super) struct EnigoImpl {}

impl EnigoImpl {
    pub(super) fn preset() -> anyhow::Result<Self> {
        unimplemented!("Mobile terminal does not support simulated keyboard and mouse")
    }

    pub(super) fn has_permission(_open_prompt: bool) -> bool {
        unimplemented!("Mobile terminal does not support simulated keyboard and mouse")
    }

    pub(super) fn button(
        &mut self,
        _button: super::Button,
        _direction: super::Direction,
    ) -> anyhow::Result<()> {
        unimplemented!("Mobile terminal does not support simulated keyboard and mouse")
    }

    pub(super) fn move_mouse(
        &mut self,
        _x: i32,
        _y: i32,
        _coordinate: super::Coordinate,
    ) -> anyhow::Result<()> {
        unimplemented!("Mobile terminal does not support simulated keyboard and mouse")
    }

    pub(super) fn scroll(&mut self, _length: i32, _axis: super::Axis) -> anyhow::Result<()> {
        unimplemented!("Mobile terminal does not support simulated keyboard and mouse")
    }

    pub(super) fn main_display(&self) -> anyhow::Result<(i32, i32)> {
        unimplemented!("Mobile terminal does not support simulated keyboard and mouse")
    }

    pub(super) fn location(&self) -> anyhow::Result<(i32, i32)> {
        unimplemented!("Mobile terminal does not support simulated keyboard and mouse")
    }

    pub(super) fn text(&mut self, _text: &str) -> anyhow::Result<()> {
        unimplemented!("Mobile terminal does not support simulated keyboard and mouse")
    }

    pub(super) fn key(&mut self, _key: Key, _direction: super::Direction) -> anyhow::Result<()> {
        unimplemented!("Mobile terminal does not support simulated keyboard and mouse")
    }

    pub(super) fn raw(&mut self, _keycode: u16, _direction: super::Direction) -> anyhow::Result<()> {
        unimplemented!("Mobile terminal does not support simulated keyboard and mouse")
    }
}

pub enum Key {
    Other(u32),
}

pub(super) fn encode_physical_keyboard_key_type(raw: Key) -> u32 {
    match raw {
        Key::Other(code) => code,
    }
}

pub(super) fn decode_physical_keyboard_key_type(raw: u32) -> Key {
    Key::Other(raw)
}

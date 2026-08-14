pub(crate) mod utils;

pub mod enigo;
pub mod kdbx;

flutter_rust_bridge::enable_frb_rust_to_dart_logging!();

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

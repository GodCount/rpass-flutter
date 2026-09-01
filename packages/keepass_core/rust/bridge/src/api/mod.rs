pub(crate) mod utils;

pub mod enigo;
pub mod kdbx;

flutter_rust_bridge::enable_frb_rust_to_dart_logging!();

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    #[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
    if let Err(e) = secmem_proc::harden_process() {
        panic!(
            "ERROR: fatal error during process hardening, exiting: {}",
            e
        );
    }

    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

#![allow(dead_code)]

pub use windows;

use windows::{
    core::PCSTR,
    Win32::{
        Foundation::HWND,
        UI::WindowsAndMessaging::{MessageBoxA, MESSAGEBOX_STYLE},
    },
};

pub unsafe fn msgbox(msg: &str) {
    MessageBoxA(
        HWND::default(),
        PCSTR::from_raw(format!("{}\0", msg).as_bytes().as_ptr() as *const u8),
        PCSTR::from_raw(b"Message Box\0" as *const u8),
        MESSAGEBOX_STYLE(0),
    );
}

pub mod misc;
pub mod monitor;
pub mod window;
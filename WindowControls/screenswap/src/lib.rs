#![allow(dead_code)]

use std::cmp::min;

use ctor::ctor;
use windows::{core::PCSTR, Win32::{
    Foundation::{BOOL, HWND, LPARAM, RECT},
    Graphics::Gdi::{EnumDisplayMonitors, MonitorFromWindow, HDC, HMONITOR, MONITOR_FROM_FLAGS},
    UI::WindowsAndMessaging::{EnumWindows, GetForegroundWindow, GetWindowLongPtrW, GetWindowRect, MessageBoxA, MoveWindow, ShowWindow, MESSAGEBOX_STYLE, SHOW_WINDOW_CMD, WINDOW_LONG_PTR_INDEX},
}};

struct MoveWinInfo {
    old_monitor_handle: HMONITOR,
    old_monitor: RECT,
    new_monitor: RECT,
}

/// Moves all windows on the active monitor in the specified direction
#[no_mangle]
unsafe fn move_all_win(dir: Direction) {
    let hwnd = GetForegroundWindow();
    let old_monitor = MonitorFromWindow(hwnd, MONITOR_FROM_FLAGS(2));
    let mut old_monitor = MonitorInfo { 
        handle: old_monitor,
        rect: get_monitor_rect(old_monitor),
        left: None,
        up: None,
        right: None,
        down: None,
    };
    let old_monitor_handle = old_monitor.handle;
    let old_monitor_rect = old_monitor.rect;
    let new_monitor = get_monitor_in_dir(&mut old_monitor, dir);

    // If there is no monitor to move to, abort
    if new_monitor.is_none() {
        return;
    }
    
    let new_monitor = new_monitor.unwrap();

    let info = MoveWinInfo {
        old_monitor_handle: old_monitor_handle,
        old_monitor: old_monitor_rect.unwrap(),
        new_monitor: new_monitor.rect.unwrap(),
    };
 
    let _ = EnumWindows(Some(move_win_enum_proc), LPARAM(&info as *const MoveWinInfo as isize));
        
    unsafe extern "system" fn move_win_enum_proc(param0: HWND, param1: LPARAM) -> BOOL {
        let info = (param1.0 as *const MoveWinInfo).as_ref().unwrap();
        let monitor = MonitorFromWindow(param0, MONITOR_FROM_FLAGS(2));
        if monitor != info.old_monitor_handle {
            return BOOL::from(true);
        }
        
        let win_style = window_get_style(param0);
        let win_is_max = (win_style & 0x1000000) != 0;
        let win_is_min = (win_style & 0x20000000) != 0;
        if win_is_max || win_is_min {
            return BOOL::from(true);
        }

        let old_monitor = info.old_monitor;
        let new_monitor = info.new_monitor;
        let _ = move_win_restored(param0, old_monitor, new_monitor);

        BOOL::from(true)
    }
}

unsafe fn is_win_visible(hwnd: HWND) -> u8 {
    let corner_radius = 20;
    
}

#[no_mangle]
unsafe fn hello_world() {
    MessageBoxA(
        HWND::default(), 
        PCSTR::from_raw(b"Hello, World\0" as *const u8), 
        PCSTR::from_raw(b"Hello, World - Message Box\0" as *const u8), 
        MESSAGEBOX_STYLE(0));
}

unsafe fn msgbox(msg: &str) {
    MessageBoxA(
        HWND::default(), 
        PCSTR::from_raw(format!("{}\0", msg).as_bytes().as_ptr() as *const u8), 
        PCSTR::from_raw(b"Message Box\0" as *const u8), 
        MESSAGEBOX_STYLE(0));
}

/// Moves the active window in the specified direction
#[no_mangle]
unsafe fn move_active_win(dir: Direction) {
    let mut win = WindowInfo { handle: GetForegroundWindow(), rect: None };
    move_win(&mut win, dir);
}

#[no_mangle]
#[ctor]
unsafe fn ctor() {
    // hello_world();
}

unsafe fn move_win(win: &mut WindowInfo, dir: Direction) {
    let hwnd = win.handle;
    let win_style = window_get_style(hwnd);
    let win_is_max = (win_style & 0x1000000) != 0;
    let old_monitor_handle = MonitorFromWindow(hwnd, MONITOR_FROM_FLAGS(2));
    let mut old_monitor = MonitorInfo { 
        handle: old_monitor_handle,
        rect: get_monitor_rect(old_monitor_handle),
        left: None,
        up: None,
        right: None,
        down: None,
    };
    let new_monitor = get_monitor_in_dir(&mut old_monitor, dir);
   
    // If there is no monitor to move to, abort
    if new_monitor.is_none() {
        return;
    }
    let new_monitor = new_monitor.unwrap();
    
    // If the window is maximized, restore it
    if win_is_max {
        restore_window(hwnd);
    }
    
    // Move the window
    let mut new_monitor_rect = new_monitor.rect;
    if new_monitor_rect.is_none() {
        new_monitor_rect = get_monitor_rect(new_monitor.handle);
    }
    let _ = move_win_restored(&win, old_monitor.rect.unwrap(), new_monitor_rect.unwrap());
    
    // If the window was maximized, maximize it again
    if win_is_max {
        maximize_window(hwnd);
    }
}

unsafe fn window_get_style(hwnd: HWND) -> isize {
    let ret = GetWindowLongPtrW(hwnd, WINDOW_LONG_PTR_INDEX(-16));
    return ret;
}

unsafe fn restore_window(hwnd: HWND) {
    let _ = ShowWindow(hwnd, SHOW_WINDOW_CMD(9));
}

unsafe fn maximize_window(hwnd: HWND) {
    let _ = ShowWindow(hwnd, SHOW_WINDOW_CMD(3));
}

unsafe fn move_win_restored(
    win: &WindowInfo,
    old_monitor: RECT,
    new_monitor: RECT,
) -> windows::core::Result<()> {
    let win_rect = win.rect.or_else(|| {
        let mut rect = RECT::default();
        let _ = GetWindowRect(win.handle, &mut rect);
        Some(rect)
    }).unwrap();

    let old_mon_w = old_monitor.right - old_monitor.left;
    let old_mon_h = old_monitor.bottom - old_monitor.top;
    let old_aspect_ratio = old_mon_w as f32 / old_mon_h as f32;
    let old_rel_x = win_rect.left - old_monitor.left;
    let old_rel_y = win_rect.top - old_monitor.top;
    let old_mon_norm_x = old_rel_x as f32 / old_mon_w as f32;
    let old_mon_norm_y = old_rel_y as f32 / old_mon_h as f32;
    let old_w = win_rect.right - win_rect.left;
    let old_h = win_rect.bottom - win_rect.top;
    let old_scale_x = old_w as f32 / old_mon_w as f32;
    let old_scale_y = old_h as f32 / old_mon_h as f32;

    let new_mon_w = new_monitor.right - new_monitor.left;
    let new_mon_h = new_monitor.bottom - new_monitor.top;
    let new_aspect_ratio = new_mon_w as f32 / new_mon_h as f32;

    // The default:
    // scale the window such that it fits the new monitor size,
    // and keeps it's aspect ratio
    let mut new_rel_x = old_mon_norm_x * new_mon_w as f32;
    let mut new_rel_y = old_mon_norm_y * new_mon_h as f32;
    let mut new_w = old_scale_x * new_mon_w as f32;
    let mut new_h = old_scale_y * new_mon_h as f32;

    // Smart swap:
    // If the new monitor has a wastly different aspect ratio,
    // hinting at a different monitor orientations:
    if (old_aspect_ratio < 1.0 && new_aspect_ratio > 1.0)
        || (old_aspect_ratio > 1.0 && new_aspect_ratio < 1.0)
    {
        // scale the window to a fitting size
        new_rel_x = old_mon_norm_y * new_mon_w as f32;
        new_rel_y = old_mon_norm_x * new_mon_h as f32;
        new_w = old_scale_y * new_mon_w as f32;
        new_h = old_scale_x * new_mon_h as f32;
    }

    let new_abs_x = new_monitor.left + new_rel_x as i32;
    let new_abs_y = new_monitor.top + new_rel_y as i32;

    MoveWindow(win.handle, new_abs_x, new_abs_y, new_w as i32, new_h as i32, true)
}

struct GetMonitorRectInfo {
    monitor_to_find: HMONITOR,
    result: Option<RECT>,
}

pub unsafe fn get_monitor_rect(monitor: HMONITOR) -> Option<RECT> {
    let mut info = GetMonitorRectInfo {
        monitor_to_find: monitor,
        result: None,
    };
    let _ = EnumDisplayMonitors(
        HDC::default(),
        None,
        Some(monitor_enum_proc),
        LPARAM(&mut info as *mut GetMonitorRectInfo as isize),
    );
    return info.result;

    /// param0:
    ///     A handle to the display monitor. This value will always be non-NULL.
    /// param1:
    ///     A handle to a device context.
    ///     The device context has color attributes that are appropriate for the display monitor identified by hMonitor. The clipping area of the device context is set to the intersection of the visible region of the device context identified by the hdc parameter of EnumDisplayMonitors, the rectangle pointed to by the lprcClip parameter of EnumDisplayMonitors, and the display monitor rectangle.
    ///     This value is NULL if the hdc parameter of EnumDisplayMonitors was NULL.
    /// param2:
    ///     A pointer to a RECT structure.
    ///     If hdcMonitor is non-NULL, this rectangle is the intersection of the clipping area of the device context identified by hdcMonitor and the display monitor rectangle. The rectangle coordinates are device-context coordinates.
    ///     If hdcMonitor is NULL, this rectangle is the display monitor rectangle. The rectangle coordinates are virtual-screen coordinates.
    /// param3:
    ///     Application-defined data that EnumDisplayMonitors passes directly to the enumeration function.
    /// returns:
    ///     A value that indicates whether the enumeration should continue. If the return value is TRUE, the enumeration continues. If the return value is FALSE, the enumeration stops.
    unsafe extern "system" fn monitor_enum_proc(
        param0: HMONITOR,
        _param1: HDC,
        param2: *mut RECT,
        param3: LPARAM,
    ) -> BOOL {
        let mi = param3.0 as *mut GetMonitorRectInfo;
        let mi = mi.as_mut();
        match mi {
            None => {
                // This should be impossible. Exit early.
                BOOL::from(false)
            }
            Some(mi) => {
                if param0 == mi.monitor_to_find {
                    // We found the monitor we are looking for, return.
                    mi.result = Some(*param2);
                    return BOOL::from(false);
                }

                // Continue enumerating
                BOOL::from(true)
            }
        }
    }
}

unsafe fn get_monitor_in_dir<'a>(monitor: &'a mut MonitorInfo, dir: Direction) -> Option<&'a Box<MonitorInfo>> {
    if monitor.rect.is_none() {
        return None;
    }
    let mut info = GetMonitorInDirInfo {
        monitor_root: monitor,
        has_found: false,
    };
    let enum_proc = match dir {
        Direction::Left => get_monitor_left_enum_proc,
        Direction::Up => get_monitor_up_enum_proc,
        Direction::Right => get_monitor_right_enum_proc,
        Direction::Down => get_monitor_down_enum_proc,
    };
    // todo: optimize by setting the rect of the monitor we are looking for
    let _ = EnumDisplayMonitors(
        HDC::default(),
        None,
        Some(enum_proc),
        LPARAM(&mut info as *mut GetMonitorInDirInfo as isize),
    );
    return match dir {
        Direction::Left => monitor.left.as_ref(),
        Direction::Up => monitor.up.as_ref(),
        Direction::Right => monitor.right.as_ref(),
        Direction::Down => monitor.down.as_ref(),
    }
}

#[derive(Default, Clone, Debug)]
struct MonitorInfo {
    handle: HMONITOR,
    rect: Option<RECT>,
    left: Option<Box<MonitorInfo>>,
    up: Option<Box<MonitorInfo>>,
    right: Option<Box<MonitorInfo>>,
    down: Option<Box<MonitorInfo>>,
}

mod window_info {
    use windows::Win32::{Foundation::{HWND, RECT}, UI::WindowsAndMessaging::GetWindowRect};

     #[derive(Default, Clone, Debug)]
    pub struct WindowInfo<'a> {
        /// The handle of the window
        handle: HWND,
        /// The rect of the window
        /// This is lazily generated when needed
        rect: Option<&'a RECT>,
    }

    impl WindowInfo<'_> {
        fn new(handle: HWND) -> Self {
            Self {
                handle,
                rect: None,
            }
        }
        
        pub fn get_handle(&self) -> HWND {
            self.handle
        }
        
        pub fn get_rect<'a>(&'a mut self) -> &'a RECT {
            if self.rect.is_none() {
                let mut rect = RECT::default();
                unsafe {
                    GetWindowRect(self.handle, &mut rect);
                }
                self.rect = Some(&rect);
            }
            self.rect.unwrap()
        }
    }
}
struct GetMonitorInDirInfo<'a> {
    monitor_root: &'a mut MonitorInfo,
    has_found: bool,
}

unsafe extern "system" fn get_monitor_left_enum_proc(
    param0: HMONITOR,
    _param1: HDC,
    param2: *mut RECT,
    param3: LPARAM,
) -> BOOL {
    let mi = param3.0 as *mut GetMonitorInDirInfo;
    let mi = mi.as_mut();
    match mi {
        None => {
            // This should be impossible. Exit early.
            BOOL::from(false)
        }
        Some(info) => {
            let mon = *param2;
            if mon.right == info.monitor_root.rect.unwrap().left {
                // We found the monitor we are looking for, return.
                let result = MonitorInfo {
                    handle: param0,
                    rect: Some(mon),
                    left: None,
                    up: None,
                    right: Some(Box::new(info.monitor_root.clone())),
                    down: None,
                };
                info.monitor_root.left = Some(Box::new(result));
                return BOOL::from(false);
            }

            // Continue enumerating
            BOOL::from(true)
        }
    }
}

unsafe extern "system" fn get_monitor_up_enum_proc(
    param0: HMONITOR,
    _param1: HDC,
    param2: *mut RECT,
    param3: LPARAM,
) -> BOOL {
    let mi = param3.0 as *mut GetMonitorInDirInfo;
    let mi = mi.as_mut();
    match mi {
        None => {
            // This should be impossible. Exit early.
            BOOL::from(false)
        }
        Some(info) => {
            let mon = *param2;
            if mon.bottom == info.monitor_root.rect.unwrap().top {
                // We found the monitor we are looking for, return.
                let result = MonitorInfo {
                    handle: param0,
                    rect: Some(mon),
                    left: None,
                    up: None,
                    right: None,
                    down: Some(Box::new(info.monitor_root.clone())),
                };
                info.monitor_root.up = Some(Box::new(result));
                return BOOL::from(false);
            }

            // Continue enumerating
            BOOL::from(true)
        }
    }
}

unsafe extern "system" fn get_monitor_right_enum_proc(
    param0: HMONITOR,
    _param1: HDC,
    param2: *mut RECT,
    param3: LPARAM,
) -> BOOL {
    let mi = param3.0 as *mut GetMonitorInDirInfo;
    let mi = mi.as_mut();
    match mi {
        None => {
            // This should be impossible. Exit early.
            BOOL::from(false)
        }
        Some(info) => {
            let mon = *param2;
            if mon.left == info.monitor_root.rect.unwrap().right {
                // If this is the first adjacent monitor, replace.
                let mut replace = !info.has_found;

                // Or if the new monitor is closer vertically, replace.
                if info.has_found {
                    let top = info.monitor_root.rect.unwrap().top;
                    let bottom = info.monitor_root.rect.unwrap().bottom;
                    let height = bottom - top;
                    let middle = top + height / 2;
                    
                    let old_top = info.monitor_root.right.as_ref().unwrap().rect.unwrap().top;
                    let old_bot = info.monitor_root.right.as_ref().unwrap().rect.unwrap().bottom;
                    let old_score = min((middle - old_top).abs(), (middle - old_bot).abs());
                    
                    let new_top = mon.top;
                    let new_bot = mon.bottom;
                    let new_score = min((middle - new_top).abs(), (middle - new_bot).abs());
                    
                    replace = new_score < old_score;
                }

                if replace {
                    let result = MonitorInfo {
                        handle: param0,
                        rect: Some(mon),
                        left: Some(Box::new(info.monitor_root.clone())),
                        up: None,
                        right: None,
                        down: None,
                    };
                    info.monitor_root.right = Some(Box::new(result));
                    info.has_found = true;
                }
            }

            // Continue enumerating
            BOOL::from(true)
        }
    }
}

unsafe extern "system" fn get_monitor_down_enum_proc(
    param0: HMONITOR,
    _param1: HDC,
    param2: *mut RECT,
    param3: LPARAM,
) -> BOOL {
    let mi = param3.0 as *mut GetMonitorInDirInfo;
    let mi = mi.as_mut();
    match mi {
        None => {
            // This should be impossible. Exit early.
            BOOL::from(false)
        }
        Some(info) => {
            let mon = *param2;
            if mon.top == info.monitor_root.rect.unwrap().bottom {
                // We found the monitor we are looking for, return.
                let result = MonitorInfo {
                    handle: param0,
                    rect: Some(mon),
                    left: None,
                    up: Some(Box::new(info.monitor_root.clone())),
                    right: None,
                    down: None,
                };
                info.monitor_root.down = Some(Box::new(result));
                return BOOL::from(false);
            }

            // Continue enumerating
            BOOL::from(true)
        }
    }
}

#[repr(i32)]
#[derive(Debug, Clone, Copy)]
enum Direction {
    Left,
    Up,
    Right,
    Down,
}

#[cfg(test)]
mod tests {}

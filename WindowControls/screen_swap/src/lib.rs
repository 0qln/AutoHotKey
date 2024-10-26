use window_controls::windows::Win32::{
    Foundation::{BOOL, HWND, LPARAM, RECT},
    Graphics::Gdi::{MonitorFromWindow, HMONITOR, MONITOR_FROM_FLAGS},
    UI::WindowsAndMessaging::{EnumWindows, GetForegroundWindow},
};
use window_controls::{
    misc::Direction,
    monitor::Monitor,
    window::{state, Window, WindowModel},
};

struct MoveWinInfo {
    old_monitor_handle: HMONITOR,
    old_monitor: RECT,
    new_monitor: RECT,
}

// Don't rename.
/// Moves all windows on the active monitor in the specified direction
#[no_mangle]
unsafe fn move_all_win(dir: Direction) {
    let win = WindowModel::new(GetForegroundWindow());
    let old_monitor = Monitor::from(&win);
    let new_monitor = old_monitor.get_next_in_dir(dir);

    // If there is no monitor to move to, abort
    if new_monitor.is_none() {
        return;
    }

    let new_monitor = new_monitor.as_deref().unwrap();

    let info = MoveWinInfo {
        old_monitor_handle: old_monitor.get_handle(),
        old_monitor: *old_monitor.get_rect(),
        new_monitor: *new_monitor.get_rect(),
    };

    let _ = EnumWindows(
        Some(move_win_enum_proc),
        LPARAM(&info as *const MoveWinInfo as isize),
    );

    unsafe extern "system" fn move_win_enum_proc(param0: HWND, param1: LPARAM) -> BOOL {
        let info = (param1.0 as *const MoveWinInfo).as_ref().unwrap();
        let monitor = MonitorFromWindow(param0, MONITOR_FROM_FLAGS(2));
        if monitor != info.old_monitor_handle {
            return BOOL::from(true);
        }

        let win = WindowModel::new(param0);
        if win.is_maximized() || win.is_minimized() {
            return BOOL::from(true);
        }

        if win.get_visibility() < 5 {
            return BOOL::from(true);
        }

        let win = Window::<state::Restored>::new(&win);
        let old_monitor = info.old_monitor;
        let new_monitor = info.new_monitor;
        let _ = win.move_screen(old_monitor, new_monitor);

        BOOL::from(true)
    }
}

// Don't rename.
/// Moves the active window in the specified direction
#[no_mangle]
unsafe fn move_active_win(dir: Direction) {
    let win = WindowModel::new(GetForegroundWindow());
    move_win(&win, dir);
}

unsafe fn move_win(win: &WindowModel, dir: Direction) {
    let old_monitor = Monitor::from(win);
    let new_monitor = old_monitor.get_next_in_dir(dir);

    // If there is no monitor to move to, abort
    if new_monitor.is_none() {
        return;
    }

    let new_monitor = new_monitor.as_deref().unwrap();

    if win.is_maximized() {
        let win = Window::<state::Maximized>::new(win);
        let _ = win.move_screen(*old_monitor.get_rect(), *new_monitor.get_rect());
    }

    if win.is_restored() {
        let win = Window::<state::Restored>::new(win);
        let _ = win.move_screen(*old_monitor.get_rect(), *new_monitor.get_rect());
    }
}

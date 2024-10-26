use windows::{
    Win32::UI::{
        WindowsAndMessaging::MoveWindow,
        WindowsAndMessaging::GetForegroundWindow
    },
};

#[no_mangle] 
pub extern fn move_win_test() {
    let hwnd = unsafe { GetForegroundWindow() }; 
    let result = unsafe { MoveWindow(hwnd, 0, 0, 100, 100, true) };
} 

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let hwnd = unsafe { GetForegroundWindow() }; 
        let result = unsafe { MoveWindow(hwnd, 0, 0, 100, 100, true) };
        result.unwrap();
    }
}

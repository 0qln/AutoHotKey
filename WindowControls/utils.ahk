#Requires AutoHotkey v2.0

IsWindowVisible(hwnd) { 
    if WinGetStyle(hwnd) & 0x20000000 {
        return 0
    }

    cornerRadius := 20
    WinGetPos &X, &Y, &W, &H, hwnd

    count := 
          (hwnd == WindowFromPoint(X + cornerRadius, Y + cornerRadius) ? 1 : 0) 
        + (hwnd == WindowFromPoint(X + cornerRadius, Y + H - cornerRadius) ? 1 : 0) 
        + (hwnd == WindowFromPoint(X + W - cornerRadius, Y + cornerRadius) ? 1 : 0) 
        + (hwnd == WindowFromPoint(X + W - cornerRadius, Y + H - cornerRadius) ? 1 : 0) 
        + (hwnd == WindowFromPoint(X + W // 2, Y + H // 2) ? 1 : 0)

    return count
}

GetChildWindow(hwnd) {
    GW_CHILD := 5
    return DllCall("GetWindow", "Ptr", hwnd, "UInt", GW_CHILD, "Ptr")
}

GetParentWindow(hwnd) {
    GW_OWNER := 4
    return DllCall("GetWindow", "Ptr", hwnd, "UInt", GW_OWNER, "Ptr")
}

IsChromeLegacyWindow(hwnd) {
    ; TODO: 
    ; Confirm that the "Chrome Legacy Window" is always the first child.
    ; If not, we will need to enumerate the child windows and find it. 
    ; https://www.autohotkey.com/board/topic/46786-enumchildwindows/
    childWindow := GetChildWindow(hwnd)
    return RegExMatch(WinGetClass(hwnd), "Chrome_WidgetWin_\d+") != 0 
        && childWindow != 0 
        && IsWindowVisible(hwnd) == 0 
        && WinGetTitle(childWindow) == "Chrome Legacy Window"
}

WindowFromPoint(X, Y) {
    point := (Y << 32) + X
    return DllCall("WindowFromPoint", "UInt64", point)
}

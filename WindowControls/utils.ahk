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

WindowFromPoint(X, Y) {
    point := (Y << 32) + X
    return DllCall("WindowFromPoint", "UInt64", point)
    ; return DllCall(
    ;     "GetAncestor",
    ;     "Ptr", DllCall("WindowFromPoint", "UInt64", point),
    ;     "UInt", 2
    ; )
}

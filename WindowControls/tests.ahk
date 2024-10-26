#Requires AutoHotkey v2.0
#Include utils.ahk

TestWindowSearch() {
    ids := WinGetList(, , ,)
    for hwnd in ids {
        if (DebugWindow(hwnd, false) = "No") {
            break
        } 
    }
}

DebugWindow(hwnd, child) {
    style := WinGetStyle(hwnd)
    exStyle := WinGetExStyle(hwnd)
    istoolbar := exStyle & 0x00000080 != 0
    title := WinGetTitle(hwnd)
    klass := WinGetClass(hwnd)
    isVisible := IsWindowVisible(hwnd)
    childWindow := GetChildWindow(hwnd)
    isChromeWindow := IsChromeLegacyWindow(hwnd)
    if isChromeWindow != 0 {
        DebugWindow(childWindow, true)
    }
    WinGetPos &x, &y, &w, &h, hwnd
    return MsgBox(
        (
            "CHILD: " child "
            Title: " title "
            Vibile: " isVisible "
            IsToolbar: " istoolbar "
            Style: " style "
            ExStyle: " exStyle "
            isChromeWindow: " isChromeWindow "
            X: " x "
            Y: " y "
            W: " w "
            H: " h "
            Id: " hwnd "

            Continue?"
        ), , 4)
}

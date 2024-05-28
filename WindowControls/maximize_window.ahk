#Requires AutoHotkey v2.0

;=========================================================;
; WINDOWS KEY + Alt + Down  --  Minimizies Active window
;=========================================================;
; instead of "Restore Down" for Win+Down

^!n::Maximize()

Maximize() {
    WinMaximize("A")
}

﻿#Requires AutoHotkey v2.0

;=========================================================;
; WINDOWS KEY + Alt + Down  --  Minimizies Active window
;=========================================================;
; instead of "Restore Down" for Win+Down

#!Down::Minimize()

Minimize() {
    WinMinimize("A")
    ; TODO: set active the last window
}
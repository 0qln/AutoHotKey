#Requires AutoHotkey v2.0

BoundX := SysGet(78)
BoundY := SysGet(79)

^!l::MoveWinH("R")
^!h::MoveWinH("L")

/*
LR: 
    "L" for left
    "R" for right
*/
MoveWinH(LR) {
    WinTitle := WinGetTitle("A")
    WinStyle := WinGetStyle(WinTitle)
    WinIsMax := WinStyle & 0x1000000

    ; Restore windowed state of the window if it is maximized.
    if (WinIsMax) {
        WinRestore WinTitle
    }

    ; Move the Window
    WinGetPos &X, &Y, &W, &H, WinTitle
    mul := (LR == "L") ? (-1) : (1)
    NewX := X + (A_ScreenWidth * mul)
    InBounds := (LR == "L") ? (NewX >= 0) : (NewX < BoundX) 
    if (InBounds) { 
        WinMove (NewX), (Y),,, WinTitle 
    }

    ; Remaximize the window
    if (WinIsMax) {
        WinMaximize WinTitle
    }
}


^!k::MoveUp()
MoveUp() {
    WinTitle := WinGetTitle("A")
    WinGetPos &X, &Y, &W, &H, WinTitle
    NewY := Y + A_ScreenHeight
    if (NewY < BoundY) {
        WinMove (X), (NewY),,, WinTitle
    }
}

^!j::MoveDown()
MoveDown() {
    WinTitle := WinGetTitle("A")
    WinGetPos &X, &Y, &W, &H, WinTitle
    NewY := Y - A_ScreenHeight
    if (NewY > 0) {
        WinMove (X), (NewY),,, WinTitle
    }
}

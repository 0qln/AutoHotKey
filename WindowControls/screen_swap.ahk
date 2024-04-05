#Requires AutoHotkey v2.0

BoundX := SysGet(78)
BoundY := SysGet(79)

^!l::MoveRight()
MoveRight() {
    WinTitle := WinGetTitle("A")
    WinGetPos &X, &Y, &W, &H, WinTitle
    NewX := X + A_ScreenWidth
    if (NewX < BoundX) {
        WinMove (NewX), (Y),,, WinTitle
    }
}

^!h::MoveLeft()
MoveLeft() {
    WinTitle := WinGetTitle("A")
    WinGetPos &X, &Y, &W, &H, WinTitle
    NewX := X - A_ScreenWidth
    if (NewX > 0) {
        WinMove (NewX), (Y),,, WinTitle
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

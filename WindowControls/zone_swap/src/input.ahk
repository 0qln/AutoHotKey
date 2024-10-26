#Requires AutoHotkey v2.0


!h::{
    MsgBox("hi")
    DllCall("..\target\debug\zoneswap.dll\move_win_test")
}

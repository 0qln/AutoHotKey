#Requires AutoHotkey v2.0

^!f::Fullscreen()

Fullscreen() {
    WinTitle := WinGetTitle("A")

    ; Remove the ugly, thick qt border 
    ; testing shows only a combination of these two styles works
    WinSetStyle -0x400000, WinTitle
    WinSetStyle -0x40000, WinTitle

    ; window is now glitching, a redraw will do the trick :)
    WinMinimize("A")
    WinMaximize WinTitle
}

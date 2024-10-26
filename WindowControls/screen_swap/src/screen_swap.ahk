#Requires AutoHotkey v2.0

; Prefetch libaries
Dll := DllCall("LoadLibrary", "Str", "screen_swap.dll", "Ptr")
MoveActiveWin := DllCall("GetProcAddress", "Ptr", Dll, "AStr", "move_active_win", "Ptr")
MoveAllWin := DllCall("GetProcAddress", "Ptr", Dll, "AStr", "move_all_win", "Ptr")

^!h::DllCall(MoveActiveWin, "Int", 0)
^!k::DllCall(MoveActiveWin, "Int", 1)
^!l::DllCall(MoveActiveWin, "Int", 2)
^!j::DllCall(MoveActiveWin, "Int", 3)

^!+h::DllCall(MoveAllWin, "Int", 0)
^!+k::DllCall(MoveAllWin, "Int", 1)
^!+l::DllCall(MoveAllWin, "Int", 2)
^!+j::DllCall(MoveAllWin, "Int", 3)
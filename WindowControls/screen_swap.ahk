#Requires AutoHotkey v2.0

^!h::MoveWin("L")
^!l::MoveWin("R")
^!k::MoveWin("U")
^!j::MoveWin("D")

; If you want to the window to take on a 
; more usable size when swapping to a monitor with 
; different orientation, set SmartSwap to True
SmartSwap := True

MoveWin(Direction) {
    ; Get the current window's state
    WinId := WinGetId("A")
    WinStyle := WinGetStyle(WinId)
    WinIsMax := WinStyle & 0x1000000

    ; Get the monitor that the window is on
    oldMonitor := GetMonitorFromHwnd(WinId)

    ; Get the new monitor that the window will be moved to
    newMonitor := 0
    switch Direction {
        case "L":
            newMonitor := GetMonitorLeft(oldMonitor)
        case "R":
            newMonitor := GetMonitorRight(oldMonitor)
        case "U":
            newMonitor := GetMonitorTop(oldMonitor)
        case "D":
            newMonitor := GetMonitorBottom(oldMonitor)
    }

    ; If there is no monitor that the window can be moved to, abort
    if (NewMonitor = 0) {
        return
    }

    ; If the window is maximized, restore it
    if (WinIsMax) {
        WinRestore WinId
    }

    ; Calculate new position and size, then move the window
    WinGetPos &oldAbsX, &oldAbsY, &oldW, &oldH, WinId
    MonitorGet(oldMonitor, &oldMonitorLeft, &oldMonitorTop, &oldMonitorRight, &oldMonitorBottom)
    oldMonW := oldMonitorRight - oldMonitorLeft
    oldMonH := oldMonitorBottom - oldMonitorTop
    oldAspectRatio := oldMonW / oldMonH
    oldRelX := oldAbsX - oldMonitorLeft
    oldRelY := oldAbsY - oldMonitorTop
    oldMonNormX := oldRelX / oldMonW
    oldMonNormY := oldRelY / oldMonH
    oldScaleX := oldW / oldMonW
    oldScaleY := oldH / oldMonH

    MonitorGet(newMonitor, &newMonitorLeft, &newMonitorTop, &newMonitorRight, &newMonitorBottom)
    newMonW := newMonitorRight - newMonitorLeft
    newMonH := newMonitorBottom - newMonitorTop
    newAspectRatio := newMonW / newMonH

    if (SmartSwap && 
        ; If the new monitor has a wastly different aspect ratio, 
        ; hinting at a different monitor orientation: 
        ((oldAspectRatio < 1 && newAspectRatio > 1) || 
         (oldAspectRatio > 1 && newAspectRatio < 1))) {
        ; scale the window to a fitting size 
        newRelX := oldMonNormY * newMonW
        newRelY := oldMonNormX * newMonH
        newAbsX := newRelX + newMonitorLeft
        newAbsY := newRelY + newMonitorTop
        newW := oldScaleY * newMonW
        newH := oldScaleX * newMonH
    }
    else {
        ; The default:
        ; scale the window such that it fits the new monitor size,
        ; and keeps it's aspect ratio
        newRelX := oldMonNormX * newMonW
        newRelY := oldMonNormY * newMonH
        newAbsX := newRelX + newMonitorLeft
        newAbsY := newRelY + newMonitorTop
        newW := oldScaleX * newMonW
        newH := oldScaleY * newMonH
    }

    WinMove newAbsX, newAbsY, newW, newH, WinId 
    
    ; If the window was maximized, maximize it
    if (WinIsMax) {
        WinMaximize WinId
    }
}
GetMonitorLeft(monitorHandle) {
    MonitorGet(monitorHandle, &oldMonitorLeft, &oldMonitorTop, &oldMonitorRight, &oldMonitorBottom)
    loop MonitorGetCount() {
        MonitorGet(A_Index, &monLeft, &monTop, &monRight, &monBottom)
        if (monRight = oldMonitorLeft) {
            return A_Index
        }
    }
    return 0
}

GetMonitorRight(monitorHandle) {
    MonitorGet(monitorHandle, &oldMonitorLeft, &oldMonitorTop, &oldMonitorRight, &oldMonitorBottom)
    loop MonitorGetCount() {
		MonitorGet(A_Index, &monLeft, &monTop, &monRight, &monBottom)
        if (monLeft = oldMonitorRight) {
            return A_Index
        }
    }
    return 0
}

GetMonitorTop(monitorHandle) {
    MonitorGet(monitorHandle, &oldMonitorLeft, &oldMonitorTop, &oldMonitorRight, &oldMonitorBottom)
    loop MonitorGetCount() {
        MonitorGet(A_Index, &monLeft, &monTop, &monRight, &monBottom)
        if (monBottom = oldMonitorTop) {
            return A_Index
        }
    }
    return 0
}

GetMonitorBottom(monitorHandle) {
    MonitorGet(monitorHandle, &oldMonitorLeft, &oldMonitorTop, &oldMonitorRight, &oldMonitorBottom)
    loop MonitorGetCount() {
        MonitorGet(A_Index, &monLeft, &monTop, &monRight, &monBottom)
        if (monTop = oldMonitorBottom) {
            return A_Index
        }
    }
    return 0
}


GetMonitorFromHwnd(winId) {
	if (MonitorGetCount() = 1) {
		return 1
	}

    MONITOR_DEFAULTTONEAREST := 2
	if !(monitorHandle := DllCall("User32.dll\MonitorFromWindow", "UInt", winId, "UInt", MONITOR_DEFAULTTONEAREST)) {
        return false
	}

    return GetMonitorFromHmonitor(monitorHandle)
}


GetMonitorFromHmonitor(monitorHandle) {
    monitorInfo := Buffer(40)
    NumPut("UInt", monitorInfo.Size, monitorInfo)
    DllCall("User32.dll\GetMonitorInfo", "UInt", monitorHandle, "Ptr", monitorInfo)
    monitorLeft   := NumGet(monitorInfo,  4, "Int")
    monitorTop    := NumGet(monitorInfo,  8, "Int")
    monitorRight  := NumGet(monitorInfo, 12, "Int")
    monitorBottom := NumGet(monitorInfo, 16, "Int")

    Loop MonitorGetCount() {
            MonitorGet(A_Index, &monLeft, &monTop, &monRight, &monBottom)
            if (monitorLeft = monLeft && monitorTop = monTop && 
        monitorRight = monRight && monitorBottom = monBottom) {
                    return A_Index
            }
    }

    return false
}



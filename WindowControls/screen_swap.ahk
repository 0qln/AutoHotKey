#Requires AutoHotkey v2.0
#Include utils.ahk

^!h::MoveAWin("L")
^!l::MoveAWin("R")
^!k::MoveAWin("U")
^!j::MoveAWin("D")

^!+h::MoveAllWin("L")
^!+l::MoveAllWin("R")
^!+k::MoveAllWin("U")
^!+j::MoveAllWin("D")

; If you want to the window to take on a 
; more usable size when swapping to a monitor with 
; different orientation, set SmartSwap to True
SmartSwap := True

; Move all windowed windows on the current monitor 
; in the specified direction
MoveAllWin(direction) {
    ; Find all windowes that should get moved
    activeWin := WinGetId("A")
    activeMon := GetMonitorFromHwnd(activeWin)
    wins := WinGetList(,,,)
    winsToMove := Array()
    for winId in wins {
        if (WinGetStyle(winId) & 0x1000000) {
            continue
        }
        if (IsWindowVisible(winId) < 5) {
            continue
        }
        if (GetMonitorFromHwnd(winId) != activeMon) {
            continue
        }
        winsToMove.Push(winId)
    }

    ; Move the windows after deciding which ones to move to reduce lag
    newMonitor := GetMonitorInDirection(activeMon, direction)
    for winId in winsToMove {
        MoveWinRestored(winId, activeMon, newMonitor)
    }
}

; Move the active window in the specified direction
MoveAWin(direction) {
    winId := WinGetId("A")
    MoveWin(direction, winId)
}

; Moves a restored window from the specified monitor to another monitor
MoveWinRestored(winId, oldMonitor, newMonitor) {
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
}

GetMonitorInDirection(monRelativeTo, direction) {
    switch direction {
        case "L": return GetMonitorLeft(monRelativeTo)
        case "R": return GetMonitorRight(monRelativeTo)
        case "U": return GetMonitorTop(monRelativeTo)
        case "D": return GetMonitorBottom(monRelativeTo)
    }
    return 0
}

; Move the specified window in the specified direction
MoveWin(direction, winId) {
    winStyle := winGetStyle(winId)
    winIsMax := winStyle & 0x1000000
    oldMonitor := GetMonitorFromHwnd(winId)
    newMonitor := GetMonitorInDirection(oldMonitor, direction)

    ; If there is no monitor that the window can be moved to, abort
    if (newMonitor = 0) { 
        return 
    }

    ; If the window is maximized, restore it
    if (winIsMax) { 
        WinRestore winId 
    }

    ; Calculate new position and size, then move the window
    MoveWinRestored(winId, oldMonitor, newMonitor)
    
    ; If the window was maximized, maximize it
    if (winIsMax) { 
        WinMaximize winId 
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



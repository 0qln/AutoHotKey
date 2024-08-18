#Requires AutoHotkey v2.0

BoundX := SysGet(78)
BoundY := SysGet(79)

^!l::MoveWin("R")
^!h::MoveWin("L")
^!k::MoveWin("U")
^!j::MoveWin("D")

MoveWin(Direction) {
    WinId := WinGetId("A")
    WinStyle := WinGetStyle(WinId)
    WinIsMax := WinStyle & 0x1000000

    if (WinIsMax) {
        WinRestore WinId
    }

    oldMonitor := GetMonitorFromHwnd(WinId)
    WinGetPos &oldAbsX, &oldAbsY, &oldW, &oldH, WinId
    MonitorGet(oldMonitor, &oldMonitorLeft, &oldMonitorTop, &oldMonitorRight, &oldMonitorBottom)
    oldRelX := oldAbsX - oldMonitorLeft
    oldRelY := oldAbsY - oldMonitorTop
    oldMonW := oldMonitorRight - oldMonitorLeft
    oldMonH := oldMonitorBottom - oldMonitorTop
    u := oldRelX / oldMonW
    v := oldRelY / oldMonH
    oldScaleX := oldW / oldMonW
    oldScaleY := oldH / oldMonH

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

    if !(newMonitor = 0) {
        MonitorGet(newMonitor, &newMonitorLeft, &newMonitorTop, &newMonitorRight, &newMonitorBottom)
        newMonW := newMonitorRight - newMonitorLeft
        newMonH := newMonitorBottom - newMonitorTop
        newRelX := u * oldMonW
        newRelY := v * oldMonH
        newAbsX := newRelX + newMonitorLeft
        newAbsY := newRelY + newMonitorTop
        newW := oldScaleX * newMonW
        newH := oldScaleY * newMonH
        WinMove newAbsX, newAbsY, newW, newH, WinId 
    }
    
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



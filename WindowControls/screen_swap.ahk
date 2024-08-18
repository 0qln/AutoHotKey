#Requires AutoHotkey v2.0


+!h::NavigateWin("L")
+!l::NavigateWin("R")
+!k::NavigateWin("U")
+!j::NavigateWin("D")

NavigateWin(Direction) {
    hwin := WinGetId("A")
    nearestWin := 0
    primaryDistToNearest := 999999
    secondaryDistToNearest := 999999
    for win in WinGetList(,,) {
        if win = hwin {
            continue
        }

        winStyle := WinGetStyle(win) 
        winWasVisible := winStyle & 0x10000000
        winIsHidden := winStyle & 0x20000000
        if !winWasVisible or winIsHidden {
            continue
        }

        switch Direction {
            case "L": predicate := IsCloserLeft
            case "R": predicate := IsCloserRight
            case "U": predicate := IsCloserUp
            case "D": predicate := IsCloserDown
        }

        WinGetPos &targetX, &targetY,,, hwin
        WinGetPos &winX, &winY,,, win
        if predicate(targetX, targetY, winX, winY, &primaryDistToNearest, &secondaryDistToNearest) {
            nearestWin := win
        }
    }

    if (nearestwin != 0) {
        WinActivate(nearestWin)
    }
}

IsCloserLeft(targetX, targetY, winX, winY, &primaryDist, &secondaryDist) {
    newPrimaryDist := targetX - winX
    newSecondaryDist := abs(winY - targetY)
    inBounds :=  winX < targetX

    if inBounds and (
            newPrimaryDist < primaryDist 
            or (newPrimaryDist = primaryDist and newSecondaryDist < secondaryDist)
        ) {
        primaryDist := newPrimaryDist
        secondaryDist := newSecondaryDist
        return true
    }

    return false
}

IsCloserRight(targetX, targetY, winX, winY, &primaryDist, &secondaryDist) {
    newPrimaryDist := winX - targetX
    newSecondaryDist := abs(winY - targetY)
    inBounds := winX > targetX

    if inBounds and (
            newPrimaryDist < primaryDist 
            or (newPrimaryDist = primaryDist and newSecondaryDist < secondaryDist)
        ) {
        primaryDist := newPrimaryDist
        secondaryDist := newSecondaryDist
        return true
    }

    return false
}

IsCloserUp(targetX, targetY, winX, winY, &primaryDist, &secondaryDist) {
    newPrimaryDist := targetY - winY
    newSecondaryDist := abs(winX - targetX)
    inBounds := winY < targetY

    if inBounds and (
            newPrimaryDist < primaryDist 
            or (newPrimaryDist = primaryDist and newSecondaryDist < secondaryDist)
        ) {
        primaryDist := newPrimaryDist
        secondaryDist := newSecondaryDist
        return true
    }

    return false
}

IsCloserDown(targetX, targetY, winX, winY, &primaryDist, &secondaryDist) {
    newPrimaryDist := winY - targetY
    newSecondaryDist := abs(winX - targetX)
    inBounds := winY > targetY

    if inBounds and (
            newPrimaryDist < primaryDist 
            or (newPrimaryDist = primaryDist and newSecondaryDist < secondaryDist)
        ) {
        primaryDist := newPrimaryDist
        secondaryDist := newSecondaryDist
        return true
    }

    return false
}


^!h::MoveWin("L")
^!l::MoveWin("R")
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



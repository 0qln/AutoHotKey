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

        if WinGetExStyle(win) & 0x00000080 {
            continue
        }

        if IsWindowVisible(win) < 4 {
            continue
        }

        switch Direction {
            case "L": predicate := IsCloserLeft
            case "R": predicate := IsCloserRight
            case "U": predicate := IsCloserUp
            case "D": predicate := IsCloserDown
        }

        WinGetPos &targetX, &targetY, &targetW, &targetH, hwin
        WinGetPos &winX, &winY, &winW, &winH, win
        if predicate(
            targetX + targetW / 2, targetY + targetH / 2, 
            winX + winW / 2, winY + winH / 2,
            &primaryDistToNearest, &secondaryDistToNearest
        ) {
            nearestWin := win
        }
    }

    if (nearestwin != 0) {
        WinActivate(nearestWin)
    }
}

IsWindowVisible(hwnd) { 
    if WinGetStyle(hwnd) & 0x20000000 {
        return 0
    }

    cornerRadius := 20
    WinGetPos &X, &Y, &W, &H, hwnd

    count := 
          (hwnd == WindowFromPoint(X + cornerRadius, Y + cornerRadius) ? 1 : 0) 
        + (hwnd == WindowFromPoint(X + cornerRadius, Y + H - cornerRadius) ? 1 : 0) 
        + (hwnd == WindowFromPoint(X + W - cornerRadius, Y + cornerRadius) ? 1 : 0) 
        + (hwnd == WindowFromPoint(X + W - cornerRadius, Y + H - cornerRadius) ? 1 : 0) 
        + (hwnd == WindowFromPoint(X + W // 2, Y + H // 2) ? 1 : 0)

    return count
}

WindowFromPoint(X, Y) {
    point := (Y << 32) + X
    return DllCall("WindowFromPoint", "UInt64", point)
    ; return DllCall(
    ;     "GetAncestor",
    ;     "Ptr", DllCall("WindowFromPoint", "UInt64", point),
    ;     "UInt", 2
    ; )
}

IsCloserLeft(targetX, targetY, winX, winY, &primaryDist, &secondaryDist) {
    newPrimaryDist := targetX - winX
    newSecondaryDist := abs(winY - targetY)

    ; Describes the 45 degree cone to the left of the target 
    inBounds :=  winX < targetX and (
        (winY >= targetY and winY <= f1(winX, targetX, targetY)) or
        (winY <= targetY and winY >= f2(winX, targetX, targetY))
    )

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

    ; Describes the 45 degree cone to the right of the target 
    inBounds := winX > targetX and (
        (winY >= targetY and winY <= f2(winX, targetX, targetY)) or
        (winY <= targetY and winY >= f1(winX, targetX, targetY))
    )

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

    ; Describes the 45 degree cone above the target 
    inBounds := winY < targetY and (
        winY <= f1(winX, targetX, targetY) and
        winY <= f2(winX, targetX, targetY)
    )

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

    ; Describes the 45 degree cone below the target 
    inBounds := winY > targetY and (
        winY >= f2(winX, targetX, targetY) and
        winY >= f1(winX, targetX, targetY)
    )

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

f1(x, px, py) { 
    return -(x - px) + py 
}

f2(x, px, py) { 
    return (x - px) + py 
}




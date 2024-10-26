#Requires AutoHotkey v2.0
#Include utils.ahk

+!h::NavigateWin("L")
+!l::NavigateWin("R")
+!k::NavigateWin("U")
+!j::NavigateWin("D")

NavigateWin(dir) {
    hwin := WinGetId("A")
    WinGetPos &targetX, &targetY, &targetW, &targetH, hwin
    nearestWin := 0
    primaryDistToNearest := 999999
    secondaryDistToNearest := 999999
    for win in WinGetList() {
        original_win := win
        if win = hwin {
            continue
        }

        if WinGetExStyle(win) & 0x00000080 {
            continue
        }

        if IsChromeLegacyWindow(win) {
            win := GetChildWindow(win)
        }

        if IsWindowVisible(win) < 4 {
            continue
        }

        switch dir {
            case "L": predicate := IsCloserLeft
            case "R": predicate := IsCloserRight
            case "U": predicate := IsCloserUp
            case "D": predicate := IsCloserDown
        }

        WinGetPos &winX, &winY, &winW, &winH, win
        if predicate(
            targetX + targetW / 2, targetY + targetH / 2, 
            winX + winW / 2, winY + winH / 2,
            &primaryDistToNearest, &secondaryDistToNearest
        ) {
            nearestWin := original_win
        }
    }

    if (nearestwin != 0) {
        WinActivate(nearestWin)
    }
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




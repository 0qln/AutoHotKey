#Requires AutoHotkey v2.0

TestWindowSearch() {
    ids := WinGetList(,,,)
    for this_id in ids
    {
        istoolbar := WinGetExStyle(this_id) & 0x00000080
        if istoolbar {
            continue
        }
        this_title := WinGetTitle(this_id)
        this_visible := IsWindowVisible(this_id)
        WinGetPos &x, &y, &w, &h, this_id
        Result := MsgBox(
        (
            "Visiting All Windows
            " A_Index " of " ids.Length "
            Title: " this_title "
            Vibile: " this_visible "
            X: " x "
            Y: " y "
            W: " w "
            H: " h "
            Id: " this_id "

            Continue?"
        ),, 4)
        if (Result = "No")
            break
    }
}

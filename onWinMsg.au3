Func WM_NOTIFY($hWnd, $Msg, $wParam, $lParam)
    Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR, $listview
    $listview = $g_listview
    If Not IsHWnd($listview) Then $listview = GUICtrlGetHandle($g_listview)

    $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
    $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
    $iCode = DllStructGetData($tNMHDR, "Code")

    Switch $hWndFrom
        Case $listview
            Switch $iCode
                Case $NM_CLICK
                    Local $tInfo = DllStructCreate($tagNMLISTVIEW, $lParam)
                    Local $iItem = DllStructGetData($tInfo, "Item")
                    If $iItem <> -1 Then
                        $selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
                        $retArr = _GUICtrlListView_GetItem($listview, $selectedLine, 0)
                        GUICtrlSetData($g_input, $retArr[3])
                        $DelLine = -1
                        ;~ print("!> Click on item " & $iItem)
                    EndIf
                Case $NM_DBLCLK
                    Local $tInfo = DllStructCreate($tagNMLISTVIEW, $lParam)
                    Local $iItem = DllStructGetData($tInfo, "Item")
                    If $iItem <> -1 Then
                        TeleportDBClick($listview)
                        ;~ print("!> DBClick on item " & $iItem)
                    Endif
			EndSwitch
    EndSwitch

    Return $GUI_RUNDEFMSG
EndFunc

Func TeleportDBClick($listview)
    $columnCount = _GUICtrlListView_GetColumnCount($listview)
    $selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
    $text = _GUICtrlListView_GetItem($listview, $selectedLine)[3]
    For $i = 1 to $columnCount - 1
        $text = $text & "|" & _GUICtrlListView_GetItem($listview, $selectedLine, $i)[3]
    Next

    print("$text : " & $text)

    If $text == 0 Then
        Return
    EndIf
    $array = StringSplit($text, '|')
    TeleportInterface($array[2], $array[3], $array[4])
EndFunc
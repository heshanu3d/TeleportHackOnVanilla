Func WM_NOTIFY($hWnd, $Msg, $wParam, $lParam)
    Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR, $listview
    $listview = $g_listview
    If Not IsHWnd($listview) Then $listview = GUICtrlGetHandle($g_listview)

    $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
    $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
    $iCode = DllStructGetData($tNMHDR, "Code")

    Switch $hWndFrom
        Case GUICtrlGetHandle($g_categoryGrid)
            Switch $iCode
                Case $NM_CLICK
                    Local $tActivate = DllStructCreate($tagNMITEMACTIVATE, $lParam)
                    Local $iRow = DllStructGetData($tActivate, "Index")
                    Local $iColumn = DllStructGetData($tActivate, "SubItem")
                    If $iRow >= 0 And $iColumn >= 0 And $iColumn < 3 Then
                        Local $category = _GUICtrlListView_GetItemText($g_categoryGrid, $iRow, $iColumn)
                        If $category = "所有" Or $g_teleListDict.Exists($category) Then $g_pendingCategory = $category
                    EndIf
                Case $NM_CUSTOMDRAW
                    Local $tDraw = DllStructCreate($tagNMLVCUSTOMDRAW, $lParam)
                    Local $stage = DllStructGetData($tDraw, "dwDrawStage")
                    If $stage = $CDDS_PREPAINT Then Return $CDRF_NOTIFYITEMDRAW
                    If $stage = $CDDS_ITEMPREPAINT Or $stage = BitOR($CDDS_ITEMPREPAINT, $CDDS_SUBITEM) Then
                        Local $row = DllStructGetData($tDraw, "dwItemSpec")
                        For $i = 0 To UBound($g_categoryGroupRows) - 1
                            If $row = $g_categoryGroupRows[$i] Then
                                DllStructSetData($tDraw, "clrTextBk", 0xE8E2D8)
                                DllStructSetData($tDraw, "clrText", 0x3B3025)
                                If $stage = $CDDS_ITEMPREPAINT Then Return BitOR($CDRF_NEWFONT, $CDRF_NOTIFYSUBITEMDRAW)
                                Return $CDRF_NEWFONT
                            EndIf
                        Next
                    EndIf
            EndSwitch
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
    Local $r = ""
    If $array[0] >= 5 Then $r = $array[5]
    TeleportInterface($array[2], $array[3], $array[4], $r)
EndFunc

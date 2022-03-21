Func Teleport($listview)
    $itemId = GUICtrlRead($listview)
    If $itemId == 0 Then
        Return
    EndIf
    $text = GUICtrlRead($itemId)
    If $text == 0 Then
        Return
    EndIf
    $array = StringSplit($text, '|')
    WritePosition($array[3], $array[2], $array[4])
EndFunc

Func AddPos($input, $listview)
    $currPosArr = ReadPosition()
    $text = GUICtrlRead($input)
    $text = $text &"|"& $currPosArr[0] &"|"& $currPosArr[1] &"|"& $currPosArr[2]
    ;~ print($text)
    GUICtrlCreateListViewItem($text, $listview)
EndFunc

Func EditPos($input, $listview)
    $currPosArr = ReadPosition()
    $text = GUICtrlRead($input)
    $selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
    _GUICtrlListView_SetItem($listview, $text, $selectedLine)
    _GUICtrlListView_SetItem($listview, $currPosArr[0], $selectedLine, 1)
    _GUICtrlListView_SetItem($listview, $currPosArr[1], $selectedLine, 2)
    _GUICtrlListView_SetItem($listview, $currPosArr[2], $selectedLine, 3)
EndFunc

Func DelPos($listview)
    ;~ print("$DelLine : " & $DelLine)
    Local $selectedLine
    If $DelLine <> -1 Then
        $selectedLine = $DelLine
        $DelLine = -1
    Else
        $selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
    EndIf
    _GUICtrlListView_DeleteItem($listview, $selectedLine)
    $lineCount = _GUICtrlListView_GetItemCount($listview)
    if $selectedLine > $lineCount - 1 Then
        _GUICtrlListView_SetItemSelected($listview, $selectedLine - 1)
    ElseIf $lineCount = 0 Then
        Return
    Else
        $DelLine = $selectedLine
    EndIf
EndFunc

Func Save($listview)
    $lineCount = _GUICtrlListView_GetItemCount($listview)
    $columnCount = _GUICtrlListView_GetColumnCount($listview)
    $fd = GetListFd($FO_OVERWRITE + $FO_CREATEPATH)
    If $fd = -1 Then
        print("An error occurred when opening the file.")
    EndIf
    For $i = 0 to $lineCount - 1
        FileWriteLine($fd, _GUICtrlListView_GetItem($listview, $i, 0)[3])
        For $c = 0 to $columnCount - 2
            FileWriteLine($fd, _GUICtrlListView_GetItem($listview, $i, $c + 1)[3])
        Next
    Next
    print("saved " & $lineCount & " teleports")
	FileClose($fd)
EndFunc

Func ReloadUI($listview)
    $g_listview = InitListview($listview)
EndFunc

Func GoHome()
    ;~ 闪金镇
    Local $x = -9458.8232
    Local $y = 43.626
    Local $z = 56.9500
    WritePosition($y, $x, $z)
EndFunc

Func FarmCheckbox($farmEYun)
	If BitAND(GUICtrlRead($farmEYun), $GUI_CHECKED) = $GUI_CHECKED Then
		$g_farmEYun = True
	Else
		$g_farmEYun = False
	EndIf
EndFunc

Func SyncTeleport($sync, $wowPidList)
	If BitAND(GUICtrlRead($sync), $GUI_CHECKED) = $GUI_CHECKED Then
		$g_syncTeleport = True
		_MemoryClose($g_selectPid)
		print("UBound($g_wowProcess) - 1:" & UBound($g_wowProcess) - 1)
		For $i = 1 to UBound($wowPidList) - 1
			_ArrayAdd($g_wowProcess, _MemoryOpen($wowPidList[$i]))
			$tmp = _MemoryOpen($wowPidList[$i])
			$g_wowProcess[$i-1][0] = $tmp[0]
			$g_wowProcess[$i-1][1] = $tmp[1]
		Next
		print("UBound($g_wowProcess) - 1:" & UBound($g_wowProcess) - 1)
	Else
		$g_syncTeleport = False
		For $i = 1 to UBound($wowPidList) - 1
			_MemoryClose($wowPidList[$i])
		Next
		$g_singleWowProcess = _MemoryOpen($g_selectPid)
	EndIf
EndFunc

Func SelectSingleWowPid($pidList)
	If $g_syncTeleport = False Then
		_MemoryClose($g_singleWowProcess)
		$g_selectPid = _GUICtrlListBox_GetText($pidList, _GUICtrlListBox_GetCaretIndex($pidList))
		$g_singleWowProcess = _MemoryOpen($g_selectPid)
		print("select pid: " & _GUICtrlListBox_GetText($pidList, _GUICtrlListBox_GetCaretIndex($pidList)))
	Else
		print("syncTeleport Checkbox is on , specify single wow pid will not work")
	EndIf
EndFunc


Func Login()
	; bot
	STSM()
	;STSM_DK()
	return

	Local $account = ["", "hs89425", "hs89427", "hs89426"]
	Local $password = ["", "m2mm2m", "m2mm2m", "m2mm2m"]
	print("Login")
	For $i = 1 to UBound($g_wowPidList)-1
		print("start find wow " & $i & " hwnd")
		$hwnd = _WinGetHandleByPidAndCls($g_wowPidList[$i], "GxWindowClassD3d")
		print("wow " & $i & " hwnd finded")
		ControlSend ( $hwnd, "", "", "{Enter}")
		Sleep(500)
		ControlSend ( $hwnd, "", "", $account[$i])
		Sleep(500)
		ControlSend ( $hwnd, "", "", "{Tab}")
		Sleep(500)
		ControlSend ( $hwnd, "", "", $password[$i])
		Sleep(500)
		ControlSend ( $hwnd, "", "", "{Enter}")
		Sleep(2000)
		ControlSend ( $hwnd, "", "", "{Enter}")
		Sleep(2000)
		ControlSend ( $hwnd, "", "", "{Enter}")
		print("wow " & $i & " accound and password input finish")
    Next

EndFunc

Func TeleportInterface($x, $y, $z)
	; x,y convert should be done here
	If $g_syncTeleport = True And $g_step = True Then
		print("cannot select sync-tp step-tp at same time. As operate differect client step-tp is not possible at moment")
		Return
	EndIf
	If $g_step = True Then
		TeleportStepByStep($x, $y, $z)
	Else
		WritePosition($y, $x, $z)
		Sleep(40)
		;Send("{Left}")
		ControlSend ( $g_hwnd, "", "", "{Left}")
		Sleep(30)
		ControlSend ( $g_hwnd, "", "", "{Right}")
		Sleep(30)
	EndIf
EndFunc

Func TeleportStepByStep($x, $y, $z)
	$currPosArr = ReadPosition()
	Local $dstArray[3] = [$x, $y, $z]   ; 闪金镇
	print("$dstArray[0] : " & $dstArray[0])
	print("$dstArray[1] : " & $dstArray[1])
	print("$dstArray[2] : " & $dstArray[2])
	print("TeleportStepByStep")
	$dis_2 = 0
	For $i = 0 To 2
		$delta = $dstArray[$i] - $currPosArr[$i]
		$dis_2 = $dis_2 + $delta * $delta
	Next
	$dis = Sqrt($dis_2)
	$dis = $dis/10
	;$dis = $dis/50
	$step = Floor($dis)+1

	Local $direction[3] = [$dstArray[0] - $currPosArr[0], $dstArray[1] - $currPosArr[1], $dstArray[2] - $currPosArr[2]]
	Local $normalizedDirection[3] = [$direction[0]/$step, $direction[1]/$step, $direction[2]/$step]

	print("$dis : " & $dis)
	print("$step : " & $step)
	print("$normalizedDirection[0] : " & $normalizedDirection[0])
	print("$normalizedDirection[1] : " & $normalizedDirection[1])
	print("$normalizedDirection[2] : " & $normalizedDirection[2])

	;print("$dst[0] : " & $dst[0])
	;print("$dst[1] : " & $dst[1])
	;print("$dst[2] : " & $dst[2])

	Local $dst[3] = [$currPosArr[0], $currPosArr[1], $currPosArr[2]]
	print("$g_hwnd: " & $g_hwnd)
	For $i = 1 To $step
	;For $i = 1 To 2
		$dst[0] = $dst[0] + $normalizedDirection[0]
		$dst[1] = $dst[1] + $normalizedDirection[1]
		$dst[2] = $dst[2] + $normalizedDirection[2]
		WritePosition($dst[1], $dst[0], $dst[2])
		Sleep(40)
		;Send("{Left}")
		ControlSend ( $g_hwnd, "", "", "{Left}")
		Sleep(30)
		ControlSend ( $g_hwnd, "", "", "{Right}")
		Sleep(30)

		; print("$i : " & $i)
		; print("$dst[0] : " & $dst[0])
		; print("$dst[1] : " & $dst[1])
		; print("$dst[2] : " & $dst[2])
	Next
	;WritePosition($dstArray[1], $dstArray[0], $dstArray[2])
EndFunc

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
    TeleportInterface($array[2], $array[3], $array[4])
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

Func ReloadUI($listview, ByRef $list, ByRef $playernameList)
    $g_listview = InitListview($listview)
	InitPidAndPlaynameList($list, $playernameList)
EndFunc

Func GoHome()
    ;~ 闪金镇
    Local $x = -9458.8232
    Local $y = 43.626
    Local $z = 56.9500
    TeleportInterface($x, $y, $z)
EndFunc

Func StepCheckbox($step)
	If BitAND(GUICtrlRead($step), $GUI_CHECKED) = $GUI_CHECKED Then
		$g_step = True
	Else
		$g_step = False
	EndIf
EndFunc

Func FarmCheckbox($farmEYun)
	If BitAND(GUICtrlRead($farmEYun), $GUI_CHECKED) = $GUI_CHECKED Then
		$g_farmEYun = True
	Else
		$g_farmEYun = False
	EndIf
EndFunc

Func SyncTeleport($sync)
	If BitAND(GUICtrlRead($sync), $GUI_CHECKED) = $GUI_CHECKED Then
		$g_syncTeleport = True
		_MemoryClose($g_selectPid)
		print("UBound($g_wowProcess) - 1:" & UBound($g_wowProcess) - 1)
		For $i = 1 to UBound($g_wowPidList) - 1
			_ArrayAdd($g_wowProcess, _MemoryOpen($g_wowPidList[$i]))
			$tmp = _MemoryOpen($g_wowPidList[$i])
			$g_wowProcess[$i-1][0] = $tmp[0]
			$g_wowProcess[$i-1][1] = $tmp[1]
		Next
		print("UBound($g_wowProcess) - 1:" & UBound($g_wowProcess) - 1)
	Else
		$g_syncTeleport = False
		For $i = 1 to UBound($g_wowPidList) - 1
			_MemoryClose($g_wowPidList[$i])
		Next
		$g_singleWowProcess = _MemoryOpen($g_selectPid)
	EndIf
EndFunc

Func SelectSingleWowPid($pidList)
	If $g_syncTeleport = False Then
		_MemoryClose($g_singleWowProcess)
		$g_selectPid = _GUICtrlListBox_GetText($pidList, _GUICtrlListBox_GetCaretIndex($pidList))
		$g_hwnd = _WinGetHandleByPidAndCls($g_selectPid, "GxWindowClassD3d")
		$g_singleWowProcess = _MemoryOpen($g_selectPid)
		print("select pid: " & _GUICtrlListBox_GetText($pidList, _GUICtrlListBox_GetCaretIndex($pidList)))
	Else
		print("syncTeleport Checkbox is on , specify single wow pid will not work")
	EndIf
EndFunc
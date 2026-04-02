

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
		If $version = "3.3.5" or $version = "1.12.1" Then
			WritePosition($y, $x, $z)
		ElseIf $version = "1.12.3" Then
			;~ WritePosition($x, $y, $z)
			WritePosition($y, $x, $z)
		EndIf
		Sleep(40)
		;Send("{Left}")
		If $g_fastStep = False Then
			ControlSend ( $g_hwnd, "", "", "{Left}")
			Sleep(30)
			ControlSend ( $g_hwnd, "", "", "{Right}")
			Sleep(30)
		EndIf
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

Func AppendPos($input, $listview, $cateText)
	$currPosArr = ReadPosition()
	$text = GUICtrlRead($input)
	$selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
	;~ print($text)
	;~ GUICtrlCreateListViewItem($text, $listview)
	_GUICtrlListView_InsertItem($listview, $text, $selectedLine + 1)
	For $i = 1 to _GUICtrlListView_GetColumnCount($listview) - 1
		_GUICtrlListView_SetItemText($listview, $selectedLine + 1, $currPosArr[$i-1], $i)
	Next
	InsertPos_telelist($cateText, $selectedLine + 1, $text, $currPosArr)
EndFunc

Func InsertPos($input, $listview, $cateText)
    $currPosArr = ReadPosition()
    $text = GUICtrlRead($input)
	$selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
    ;~ print($text)
    ;~ GUICtrlCreateListViewItem($text, $listview)
	_GUICtrlListView_InsertItem($listview, $text, $selectedLine)
	For $i = 1 to _GUICtrlListView_GetColumnCount($listview) - 1
		_GUICtrlListView_SetItemText($listview, $selectedLine, $currPosArr[$i-1], $i)
	Next
	InsertPos_telelist($cateText, $selectedLine, $text, $currPosArr)
EndFunc

Func AddPos($input, $listview, $cateText)
    $currPosArr = ReadPosition()
    $text = GUICtrlRead($input)
    $text = $text &"|"& $currPosArr[0] &"|"& $currPosArr[1] &"|"& $currPosArr[2]
    ;~ print($text)
    GUICtrlCreateListViewItem($text, $listview)
	;~ AddPos_telelist($cateText, $text, $currPosArr)
	AddPos_telelist($cateText, $text, $currPosArr)
EndFunc

Func EditPos($input, $listview, $cateText)
    $currPosArr = ReadPosition()
    $text = GUICtrlRead($input)
    $selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
    _GUICtrlListView_SetItem($listview, $text, $selectedLine)
    _GUICtrlListView_SetItem($listview, $currPosArr[0], $selectedLine, 1)
    _GUICtrlListView_SetItem($listview, $currPosArr[1], $selectedLine, 2)
    _GUICtrlListView_SetItem($listview, $currPosArr[2], $selectedLine, 3)
	;~ EditPos_telelist($cateText, $selectedLine, $text, $currPosArr)
	EditPos_telelist($cateText, $selectedLine, $text, $currPosArr)
EndFunc

Func DelPos($listview, $cateText)
    ;~ print("$DelLine : " & $DelLine)
    Local $selectedLine
    If $DelLine <> -1 Then
        $selectedLine = $DelLine
        $DelLine = -1
    Else
        $selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
    EndIf
    _GUICtrlListView_DeleteItem($listview, $selectedLine)
	DelPos_telelist($cateText, $selectedLine)
	;~ print("delete " & $selectedLine)
    $lineCount = _GUICtrlListView_GetItemCount($listview)
    if $selectedLine > $lineCount - 1 Then
        _GUICtrlListView_SetItemSelected($listview, $selectedLine - 1)
		;~ print("select " & $selectedLine - 1)
    ElseIf $lineCount = 0 Then
        Return
    Else
        $DelLine = $selectedLine
    EndIf
EndFunc

Func SaveOld($listview)
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

Func SaveFromList(ByRef $telelist, ByRef $pointCnt, $fd)
	Local $i = 0
	$columnCount = _GUICtrlListView_GetColumnCount($g_listview)
	While $i < UBound($telelist)
		Local $telePointText = $telelist[$i]
		For $c = 1 to $columnCount - 1
			$telePointText = $telePointText & $g_telelist_split_str & $telelist[$i+$c]
		Next

		FileWriteLine($fd, $telePointText)
		$pointCnt = $pointCnt + 1

		$i = $i + $columnCount
	WEnd
EndFunc

Func Save($listview, $comboBox)
	$cateText = GUICtrlRead($comboBox)
    $fd = GetListFd($FO_OVERWRITE + $FO_CREATEPATH)
    If $fd = -1 Then
        print("An error occurred when opening the file.")
    EndIf

	Local $pointCnt = 0

	If $cateText = "所有" Then
		$telelist = Save_telelist($catetext)
		SaveFromList($telelist, $pointCnt, $fd)
		;~ Local $i = 0
		;~ While $i < UBound($telelist)
		;~ 	Local $telePointText = $telelist[$i]
		;~ 	For $c = 1 to $columnCount - 1
		;~ 		$telePointText = $telePointText & $g_telelist_split_str & $telelist[$i+$c]
		;~ 	Next
	
		;~ 	FileWriteLine($fd, $telePointText)
		;~ 	$pointCnt = $pointCnt + 1
	
		;~ 	$i = $i + $columnCount
		;~ WEnd
	Else
		$list = _GUICtrlComboBox_GetListArray($comboBox)
		;~ $list[0] is value of UBound($list)-1
		For $i = 2 to $list[0]
			;~ print("save " & $i & " " & $list[$i])
			$telelist = Save_telelist($list[$i])
			SaveFromList($telelist, $pointCnt, $fd)
		Next
	EndIf


    print("saved " & $pointCnt & " teleports")
	FileClose($fd)
EndFunc

Func ReloadUI($listview, $comboBox, ByRef $list, ByRef $playernameList)
    Local $tReload = TimerInit()

    Local $t1 = TimerInit()
    Local $category = InitTeleportList()
    Local $tTeleport = TimerDiff($t1)

    Local $t2 = TimerInit()
    InitComboBox($category, $comboBox)
    Local $tCombo = TimerDiff($t2)

    Local $t3 = TimerInit()
    $g_listview = InitListview($listview)
    Local $tListview = TimerDiff($t3)

    Local $t4 = TimerInit()
    InitPidAndPlaynameList($list, $playernameList)
    Local $tPid = TimerDiff($t4)

    Local $tTotal = TimerDiff($tReload)
    print("[PERF] ====== ReloadUI ======")
    print("[PERF] InitTeleportList: " & Round($tTeleport, 1) & "ms")
    print("[PERF] InitComboBox:     " & Round($tCombo, 1) & "ms")
    print("[PERF] InitListview:     " & Round($tListview, 1) & "ms")
    print("[PERF] InitPidList:      " & Round($tPid, 1) & "ms")
    print("[PERF] ReloadUI Total:   " & Round($tTotal, 1) & "ms")
    print("[PERF] =========================")
EndFunc

Func Home()

    Local $x = -9458.8232
    Local $y = 43.626
    Local $z = 56.9500
    ;~ TeleportInterface($x, $y, $z)
	If $version = "3.3.5" Then
		$map = ReadMap()
		print('mapid: ' & $map)
		If $map = 0 then
			;~ 0 主城-暴风城-贸易区#-8843.535#625.114#94.281
			Local $x = -8843.535
			Local $y = 625.114
			Local $z = 94.281
			;~ WritePositionSingle($x, $y, $z, $g_singleWowProcess)
		ElseIf $map = 1 then
			;~ 1 主城-达纳苏斯-传送大师#9868.812#2493.633#1315.876
			Local $x = 9868.812
			Local $y = 2493.633
			Local $z = 1315.876
			;~ WritePositionSingle($x, $y, $z, $g_singleWowProcess)
		ElseIf $map = 530 then
			;~ 530 主城-沙塔斯-传送大师#-1887.801#5357.083#-12.429
			Local $x = -1887.801
			Local $y = 5357.083
			Local $z = -12.429
			;~ WritePositionSingle($x, $y, $z, $g_singleWowProcess)
		ElseIf $map = 571 then
			;~ 571 主城-达拉然-传送大师#5809.278#504.377#657.532
			Local $x = 5809.278
			Local $y = 504.377
			Local $z = 657.532
			;~ WritePositionSingle($x, $y, $z, $g_singleWowProcess)
		Else
			return
		EndIf
		WritePositionSingle($y, $x, $z, $g_singleWowProcess)
	EndIf
EndFunc

Func StepCheckbox($step)
	If BitAND(GUICtrlRead($step), $GUI_CHECKED) = $GUI_CHECKED Then
		$g_step = True
	Else
		$g_step = False
	EndIf
EndFunc

Func FastStepCheckbox($step)
	If BitAND(GUICtrlRead($step), $GUI_CHECKED) = $GUI_CHECKED Then
		$g_fastStep = True
	Else
		$g_fastStep = False
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

Func SwitchSpeed($speed_swi)
	If BitAND(GUICtrlRead($speed_swi), $GUI_CHECKED) = $GUI_CHECKED Then
		$speed = GUICtrlRead($g_speed)
		GlobalSpeedSet($speed)
	Else
		GlobalSpeedSet(7.0)
	EndIf
EndFunc

Func SwitchListview($category)
	If $g_category_selected <> $category Then
		$g_category_selected = $category
		SwitchListviewWithCategory($category)
	EndIf
EndFunc
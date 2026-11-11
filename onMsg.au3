

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

Func CanTeleportToMap($map)
	If StringLen(String($map)) = 0 Then Return True
	If Not StringIsInt(String($map)) Or Number($map) < 0 Then
		print("Invalid destination map ID; teleport cancelled")
		Return False
	EndIf
	If $g_syncTeleport Then
		Local $processCount = UBound($g_wowPidList) - 1
		If $processCount <= 0 Or $processCount > UBound($g_wowProcess) Then Return False
		For $i = 0 To $processCount - 1
			Local $process[2] = [$g_wowProcess[$i][0], $g_wowProcess[$i][1]]
			Local $currentMap = ReadMapForProcess($process)
			If $currentMap < 0 Or Number($map) <> $currentMap Then
				print("Cannot teleport to map " & $map & "; process " & $g_wowPidList[$i + 1] & " is on map " & $currentMap)
				Return False
			EndIf
		Next
	Else
		Local $currentMap = ReadMapForProcess($g_singleWowProcess)
		If $currentMap < 0 Then
			print("Cannot verify destination map; teleport cancelled")
			Return False
		EndIf
		If Number($map) <> $currentMap Then
			print("Cross-map teleport is not supported: " & $currentMap & " -> " & $map)
			Return False
		EndIf
	EndIf
	Return True
EndFunc

Func TeleportInterface($x, $y, $z, $r = "", $label = "", $map = "")
	If Not CanTeleportToMap($map) Then Return False
	; x,y convert should be done here
	If $g_syncTeleport = True And $g_step = True Then
		print("cannot select sync-tp step-tp at same time. As operate differect client step-tp is not possible at moment")
		Return
	EndIf
	If $g_step = True Then
		If Not TeleportStepByStep($x, $y, $z, $r) Then Return False
	Else
		If $version = "3.3.5" or $version = "1.12.1" Then
			If Not WritePosition($y, $x, $z, $r) Then Return False
		ElseIf $version = "1.12.3" Then
			;~ WritePosition($x, $y, $z)
			If Not WritePosition($y, $x, $z, $r) Then Return False
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
	RecordRecentTeleport($x, $y, $z, $r, $label, $map)
	Return True
EndFunc

Func TeleportStepByStep($x, $y, $z, $r = "")
	$currPosArr = ReadPosition()
	If Not IsArray($currPosArr) Then Return False
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
		If $i = $step Then
			If Not WritePosition($dst[1], $dst[0], $dst[2], $r) Then Return False
		Else
			If Not WritePosition($dst[1], $dst[0], $dst[2]) Then Return False
		EndIf
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
	Return True
	;WritePosition($dstArray[1], $dstArray[0], $dstArray[2])
EndFunc

Func Teleport($listview)
    Return TeleportListRow($listview, _GUICtrlListView_GetNextItem($listview))
EndFunc

Func CategoryOfDescription($description)
    Local $dash = StringInStr($description, "-")
    If $dash > 0 Then Return StringLeft($description, $dash - 1)
    Return $description
EndFunc

; Translate a displayed row to the authoritative unfiltered favourites array.
Func GlobalPositionForVisibleRow($row)
    If $row < 0 Or $row >= UBound($g_visibleSourceIndices) Then Return -1
    Local $source = $g_visibleSourceIndices[$row]
    If $g_category_selected = "所有" Then Return $source
    Local $categoryRow = 0
    For $i = 0 To Floor(UBound($g_teleList_whole) / 6) - 1
        If CategoryOfDescription($g_teleList_whole[$i * 6]) <> $g_category_selected Then ContinueLoop
        If $categoryRow = $source Then Return $i
        $categoryRow += 1
    Next
    Return -1
EndFunc

Func RebuildCategoryData()
    Local $categories = ObjCreate("Scripting.Dictionary")
    For $i = 0 To UBound($g_teleList_whole) - 6 Step 6
        Local $name = CategoryOfDescription($g_teleList_whole[$i])
        If Not $categories.Exists($name) Then $categories.Add($name, ObjCreate("System.Collections.ArrayList"))
        Local $items = $categories.Item($name)
        For $j = 0 To 5
            $items.Add($g_teleList_whole[$i + $j])
        Next
    Next
    $g_teleListDict.RemoveAll()
    Local $names = $categories.Keys
    For $i = 0 To $categories.Count - 1
        Local $items = $categories.Item($names[$i])
        $g_teleListDict.Add($names[$i], $items.ToArray())
    Next
    If $g_category_selected <> "所有" And Not $g_teleListDict.Exists($g_category_selected) Then
        If $g_searchEdit <> 0 Then
            SelectSearchCategory("所有")
        Else
            $g_category_selected = "所有"
            $g_currentSearch = SearchForCategory("所有")
        EndIf
    EndIf
    If $g_categoryLabel <> 0 Then GUICtrlSetData($g_categoryLabel, "当前：" & $g_category_selected)
    RefreshCategoryGrid($names)
    If $g_categorySettingsGroup <> 0 Then RefreshCategorySettings(_GUICtrlListBox_GetCurSel($g_categorySettingsGroup))
    SwitchListviewWithCategory($g_category_selected)
EndFunc

Func UpdateFavourite($action, $visibleRow, $description = "", $position = 0)
    Local $count = Floor(UBound($g_teleList_whole) / 6)
    Local $row = GlobalPositionForVisibleRow($visibleRow)
    If $action <> "add" And $row < 0 Then Return False
    If $action <> "delete" Then
        If Not IsArray($position) Or UBound($position) < 5 Or StringStripWS($description, 3) = "" Then Return False
        If StringInStr($description, "#") Or StringRegExp($description, "[\r\n]") Then Return False
    EndIf
    Switch $action
        Case "add", "insert", "append"
            If $action = "add" Then $row = $count
            If $action = "append" Then $row += 1
            Local $oldSize = UBound($g_teleList_whole), $offset = $row * 6
            ReDim $g_teleList_whole[$oldSize + 6]
            For $i = $oldSize - 1 To $offset Step -1
                $g_teleList_whole[$i + 6] = $g_teleList_whole[$i]
            Next
            $g_teleList_whole[$offset] = $description
            For $i = 0 To 4
                $g_teleList_whole[$offset + $i + 1] = $position[$i]
            Next
        Case "edit"
            $g_teleList_whole[$row * 6] = $description
            For $i = 0 To 4
                $g_teleList_whole[$row * 6 + $i + 1] = $position[$i]
            Next
        Case "delete"
            _ArrayDelete($g_teleList_whole, ($row * 6) & "-" & ($row * 6 + 5))
        Case Else
            Return False
    EndSwitch
    RebuildCategoryData()
    If $g_autoSave And Not Save($g_listview) Then print("Automatic save failed; changes remain in memory")
    Return True
EndFunc

Func AppendPos($input, $listview, $cateText)
    Local $position = ReadPosition()
    If IsArray($position) Then UpdateFavourite("append", _GUICtrlListView_GetNextItem($listview), GUICtrlRead($input), $position)
EndFunc

Func InsertPos($input, $listview, $cateText)
    Local $position = ReadPosition()
    If IsArray($position) Then UpdateFavourite("insert", _GUICtrlListView_GetNextItem($listview), GUICtrlRead($input), $position)
EndFunc

Func AddPos($input, $listview, $cateText)
    Local $position = ReadPosition()
    If IsArray($position) Then UpdateFavourite("add", -1, GUICtrlRead($input), $position)
EndFunc

Func EditPos($input, $listview, $cateText)
    Local $position = ReadPosition()
    If IsArray($position) Then UpdateFavourite("edit", _GUICtrlListView_GetNextItem($listview), GUICtrlRead($input), $position)
EndFunc

Func DelPos($listview, $cateText)
    UpdateFavourite("delete", _GUICtrlListView_GetNextItem($listview))
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

Func Save($listview)
    Local $tmp = $teleport_file & ".tmp." & @AutoItPID
    Local $fd = FileOpen($tmp, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8_NOBOM)
    If $fd = -1 Then
        print("Failed to open temporary favourites file")
        Return False
    EndIf
    Local $ok = True
    For $i = 0 To UBound($g_teleList_whole) - 6 Step 6
        Local $line = $g_teleList_whole[$i]
        For $c = 1 To 5
            $line &= $g_telelist_split_str & $g_teleList_whole[$i + $c]
        Next
        If Not FileWriteLine($fd, $line) Then
            $ok = False
            ExitLoop
        EndIf
    Next
    FileClose($fd)
    If Not $ok Or Not FileMove($tmp, $teleport_file, $FC_OVERWRITE) Then
        print("Failed to save favourites; previous file remains unchanged")
        Return False
    EndIf
    print("saved " & Floor(UBound($g_teleList_whole) / 6) & " teleports")
    Return True
EndFunc

Func ReloadUI($listview, ByRef $list, ByRef $playernameList)
    Local $tReload = TimerInit()
    Local $topIndex = _GUICtrlListView_GetTopIndex($listview)
    Local $rowRect = _GUICtrlListView_GetItemRect($listview, 0)

    Local $t1 = TimerInit()
    Local $category = InitTeleportList()
    Local $tTeleport = TimerDiff($t1)

    Local $t2 = TimerInit()
    If $g_category_selected <> "所有" And Not $g_teleListDict.Exists($g_category_selected) Then
        If $g_searchEdit <> 0 Then
            SelectSearchCategory("所有")
        Else
            $g_category_selected = "所有"
        EndIf
    EndIf
    If $g_categoryLabel <> 0 Then GUICtrlSetData($g_categoryLabel, "当前：" & $g_category_selected)
    RefreshCategoryGrid($category)
    If $g_categorySettingsGroup <> 0 Then RefreshCategorySettings(_GUICtrlListBox_GetCurSel($g_categorySettingsGroup))
    Local $tCategoryGrid = TimerDiff($t2)

    Local $t3 = TimerInit()
    $g_listview = InitListview($listview)
    If $topIndex > 0 And IsArray($rowRect) And _GUICtrlListView_GetItemCount($listview) > 0 Then
        Local $rowHeight = $rowRect[3] - $rowRect[1]
        If $rowHeight > 0 Then _GUICtrlListView_Scroll($listview, 0, $topIndex * $rowHeight)
    EndIf
    Local $tListview = TimerDiff($t3)

    Local $t4 = TimerInit()
    InitPidAndPlaynameList($list, $playernameList)
    Local $tPid = TimerDiff($t4)

    Local $tTotal = TimerDiff($tReload)
    print("[PERF] ====== ReloadUI ======")
    print("[PERF] InitTeleportList: " & Round($tTeleport, 1) & "ms")
    print("[PERF] CategoryGrid:     " & Round($tCategoryGrid, 1) & "ms")
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
		RecordRecentTeleport($x, $y, $z, "", "home")
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
		Local $selectedIndex = _GUICtrlListBox_GetCurSel($pidList)
		If $selectedIndex < 0 Then Return
		Local $pid = Number(_GUICtrlListBox_GetText($pidList, $selectedIndex))
		If $pid <= 0 Then Return
		_MemoryClose($g_singleWowProcess)
		$g_selectPid = $pid
		$g_hwnd = _WinGetHandleByPidAndCls($g_selectPid, "GxWindowClassD3d")
		$g_singleWowProcess = _MemoryOpen($g_selectPid)
		print("select pid: " & $g_selectPid)
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

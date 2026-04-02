
Func InitPidAndPlaynameList(ByRef $pidList, ByRef $playernameList)
	If $pidList <> 0 Then
		$WowProcessList = ProcessList($exe)
		Local $wowPidList = []
		For $i = 1 to $WowProcessList[0][0]
			print("WoW pid:" & $WowProcessList[$i][1])
			_ArrayAdd($wowPidList, $WowProcessList[$i][1])
		Next
		$g_wowPidList = $wowPidList
		_GUICtrlListBox_Destroy($pidList)
	EndIf
	If $playernameList <> 0 Then
		_GUICtrlListBox_Destroy($playernameList)
	EndIf
	$pidList = GUICtrlCreateList("", 250, 520, 60, 60, $LBS_DISABLENOSCROLL)
	$playernameList = GUICtrlCreateList("", 310, 520, 60, 60, $LBS_DISABLENOSCROLL)

	GUICtrlSetLimit($pidList, 200)
	GUICtrlSetLimit($playernameList, 200)
	$playerNames = Sync(GetPlayerName)
	If UBound($playerNames) <> UBound($g_wowPidList) Then
		print("UBound($playerNames) <> UBound($g_wowPidList)")
		Return
	EndIf
	For $i = 1 to UBound($g_wowPidList) - 1
		GUICtrlSetData($pidList, $g_wowPidList[$i])
		If $playerNames[$i] <> "" Then
			GUICtrlSetData($playernameList, $playerNames[$i])
		EndIf
		;print($g_wowPidList[$i])
		;print($playerNames[$i])
	Next
EndFunc

Func InitTeleportList()
    Local $tTotal = TimerInit()

    InitGlobalTeleportList()

    $teleList_whole = FileReadToArray($teleport_file)
    $g_lineCount = @extended
    Local $bFileError = @error
    Local $tFileRead = TimerDiff($tTotal)
    print("$g_lineCount : " & $g_lineCount)
    $columnCount = 4

    If $bFileError Then
        MsgBox($MB_SYSTEMMODAL, "", "There was an error reading the file. @error: " & $bFileError)
        Local $category[0]
        Return $category
    EndIf

    ; 使用 ArrayList 替代 _ArrayAdd，避免每次 ReDim 导致 O(n²) 开销
    ; ArrayList.Add() 内部自动扩容，均摊 O(1)；最后 .ToArray() 一次性转回标准数组
    Local $allList = ObjCreate("System.Collections.ArrayList")
    ; Dictionary: 分类名 -> ArrayList（该分类的传送点）
    Local $catDict = ObjCreate("Scripting.Dictionary")
    ; 保持分类插入顺序（用于填充 ComboBox）
    Local $categoryOrder = ObjCreate("System.Collections.ArrayList")

    Local $tParse = TimerInit()
    Local $i = 0
    While $i < $g_lineCount
        Local $text = $teleList_whole[$i]
        Local $split = StringSplit($text, $g_telelist_split_str)

        If UBound($split) - 1 = $columnCount Then
            ; # 格式：一行包含 desc#x#y#z
            ; 提取分类名（取描述字段中"-"前面的部分）
            Local $cateText = $split[1]
            Local $dashSplit = StringSplit($cateText, "-")
            If $dashSplit[0] > 0 Then $cateText = $dashSplit[1]

            ; 加入 "所有" 列表
            For $j = 1 To $split[0]
                $allList.Add($split[$j])
            Next

            ; 加入对应分类列表
            If Not $catDict.Exists($cateText) Then
                $catDict.Add($cateText, ObjCreate("System.Collections.ArrayList"))
                $categoryOrder.Add($cateText)
            EndIf
            Local $catList = $catDict.Item($cateText)
            For $j = 1 To $split[0]
                $catList.Add($split[$j])
            Next

            $i = $i + 1
        Else
            ; 多行格式：每条记录占 columnCount 行
            If $i + $columnCount - 1 >= $g_lineCount Then ExitLoop

            Local $cateText = $text
            Local $dashSplit = StringSplit($cateText, "-")
            If $dashSplit[0] > 0 Then $cateText = $dashSplit[1]

            ; 加入 "所有" 列表（每个字段单独存储，保持 stride=4 的一致性）
            $allList.Add($text)
            For $c = 1 To $columnCount - 1
                $allList.Add($teleList_whole[$i + $c])
            Next

            ; 加入对应分类列表
            If Not $catDict.Exists($cateText) Then
                $catDict.Add($cateText, ObjCreate("System.Collections.ArrayList"))
                $categoryOrder.Add($cateText)
            EndIf
            Local $catList = $catDict.Item($cateText)
            $catList.Add($text)
            For $c = 1 To $columnCount - 1
                $catList.Add($teleList_whole[$i + $c])
            Next

            $i = $i + $columnCount
        EndIf
    WEnd
    Local $tParseMs = TimerDiff($tParse)

    ; ArrayList -> 标准数组，存入全局变量
    $g_teleList_whole = $allList.ToArray()

    Local $keys = $catDict.Keys
    For $k = 0 To UBound($keys) - 1
        $g_teleListDict.Add($keys[$k], $catDict.Item($keys[$k]).ToArray())
    Next

    Local $tTotalMs = TimerDiff($tTotal)
    print("[PERF] InitTeleportList FileRead: " & Round($tFileRead, 1) & "ms")
    print("[PERF] InitTeleportList Parse: " & Round($tParseMs, 1) & "ms")
    print("[PERF] InitTeleportList Total: " & Round($tTotalMs, 1) & "ms")

    return $categoryOrder.ToArray()
EndFunc

Func InitListview($listview = 0)
    If $listview = 0 Then
        print("launch ui")
        ;~ refactor
        $listview = GUICtrlCreateListView("        描述        |      x      |      y      |      z      ", 10, 20, 380, 490)
        GUICtrlSendMsg($listview, $LVM_SETCOLUMNWIDTH, 0, 250)
        $g_listview = $listview
    Else
        ;~ refactor
        ;~ GUICtrlDelete($listview)
        ;~ GUICtrlSendMsg($listview, $LVM_SCROLL, 0, 0)
        ;~ _GUICtrlListView_Scroll($listview, 0, -10000)
        ;~ _GUICtrlListView_DeleteAllItems($listview)
        ;~ InitListviewWithList 已经处理了 DeleteAllItems，此处无需重复操作
        print("reload")
    Endif

    return SwitchListviewWithCategory($g_category_selected)
EndFunc

Func InitComboBox(Byref $category, $comboBox = 0)
    If $comboBox = 0 Then
        $comboBox = GUICtrlCreateCombo("所有", 10, 00, 140, 20)
        ;~ _GUICtrlComboBox_SetItemHeight($comboBox, 25) ; 控件显示区高度
        _GUICtrlComboBox_SetItemHeight($comboBox, 25, 1) ; 下拉列表每项高度
    Else
        ;~ print("InitComboBox combobox delete start  with " & _GUICtrlComboBox_GetCount($comboBox))
        For $i = _GUICtrlComboBox_GetCount($comboBox) - 1 to 0 Step - 1
            _GUICtrlComboBox_DeleteString($comboBox, $i)
            ;~ print("InitComboBox combobox delete " & $i)
        Next
        GUICtrlSetData($comboBox, "所有")
    EndIf

    Local $i
    For $i = 0 to UBound($category) - 1
        GUICtrlSetData($comboBox, $category[$i])
    Next

    ;~ _GUICtrlComboBox_SetCurSel($comboBox, 0)
    _GUICtrlComboBox_SelectString($comboBox, $g_category_selected)

    return $comboBox
EndFunc

Func GetListFd($op = $FO_READ)
    $fd = FileOpen($teleport_file, $op)
    If $fd = -1 Then
        print("An error occurred when reading the file.")
    EndIf
    Return $fd
EndFunc

Func LaunchUI()
	If UBound($g_wowPidList) = 1 Then
		Return
	EndIf

    $ui = GUICreate($winTitle, 400, 880, 100, 200, -1, $WS_EX_ACCEPTFILES)
    GUISetBkColor(0x00E0FFFF) ; will change background color
    GUISetState(@SW_SHOW)
    
    ;~ read teleport points from file
    Local $category = InitTeleportList()

    $comboBox = InitComboBox($category)

    $listview = InitListview()
    $g_listview = $listview
	$g_input = GUICtrlCreateInput("",      10,  520, 210, 20)
	Local $pidList = 0
	Local $playernameList = 0
	InitPidAndPlaynameList($pidList, $playernameList)
	$sync = GUICtrlCreateCheckbox("sync-tp", 	10,  550, 60, 20)
	$step = GUICtrlCreateCheckbox("step-tp", 	90,  550, 60, 20)
	$farmEYun = GUICtrlCreateCheckbox("厄运",   170, 550, 60, 20)
    $addPos = GUICtrlCreateButton("addPos",     10,  580, 70, 20)
    $editPos = GUICtrlCreateButton("editPos",   100, 580, 70, 20)
    $delPos = GUICtrlCreateButton("delPos",     190, 580, 70, 20)

    $teleport = GUICtrlCreateButton("Teleport", 280, 580, 100, 50)

    $insertPos =GUICtrlCreateButton("insertPos",10,  610, 70, 20)
    $save = GUICtrlCreateButton("save",         100, 610, 70, 20)
    $reload = GUICtrlCreateButton("reload",     190, 610, 70, 20)

    $appendPos = GUICtrlCreateButton("appendPos",           10,  640, 70, 20)

    $g_speed = GUICtrlCreateInput("",           100, 640, 35, 20)
    $speed_swi = GUICtrlCreateCheckbox("speed", 135, 640, 60, 20)

    $login = GUICtrlCreateButton("login",       190, 640, 70, 20)
    $fastStep = GUICtrlCreateCheckbox("fastStep", 280, 640, 680, 20)

    $home = GUICtrlCreateButton("home",           10,  670, 70, 20)

    $g_log = GUICtrlCreateEdit("",                10,  700, 380, 175, BitOR($ES_AUTOVSCROLL, $WS_VSCROLL))

    ;~ richEdit loaded too slow
    ;~ $g_log = _GUICtrlRichEdit_Create($ui, "", 10, 610, 380, 320, BitOR($ES_MULTILINE, $WS_VSCROLL, $ES_AUTOVSCROLL))

    GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
    Do
        $msg = GUIGetMsg()
        Select
            Case $msg = $login
                Login()
            Case $msg = $insertPos
                InsertPos($g_input, $listview, GUICtrlRead($comboBox))
            Case $msg = $appendPos
                AppendPos($g_input, $listview, GUICtrlRead($comboBox))
            Case $msg = $addPos
                AddPos($g_input, $listview, GUICtrlRead($comboBox))
            Case $msg = $editPos
                EditPos($g_input, $listview, GUICtrlRead($comboBox))
            Case $msg = $delPos
                DelPos($listview, GUICtrlRead($comboBox))
            Case $msg = $save
                Save($listview, $comboBox)
                ReloadUI($listview, $comboBox, $pidList, $playernameList)
            Case $msg = $reload
                ReloadUI($listview, $comboBox, $pidList, $playernameList)
            Case $msg = $teleport
                Teleport($listview)
			Case $msg = $sync
				SyncTeleport($sync)
			Case $msg = $step
				StepCheckbox($step)
            Case $msg = $fastStep
				FastStepCheckbox($fastStep)
			Case $msg = $farmEYun
				FarmCheckbox($farmEYun)
			Case $msg = $pidList
				SelectSingleWowPid($pidList)
            Case $msg = $speed_swi
                SwitchSpeed($speed_swi)
            Case $msg = $comboBox
                SwitchListview(GUICtrlRead($comboBox))
            Case $msg = $home
                Home()
        EndSelect
    Until $msg = $GUI_EVENT_CLOSE
EndFunc

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
    InitGlobalTeleportList()
    $teleList_whole = FileReadToArray($teleport_file)
    $g_lineCount = @extended
    print("$g_lineCount : " & $g_lineCount)
    $columnCount = 4
    Local $category[0]

    Local $set[0]
    If @error Then
        MsgBox($MB_SYSTEMMODAL, "", "There was an error reading the file. @error: " & @error)
    Else
        Local $i = 0
        While $i < $g_lineCount
        ;~ While $i + $columnCount-1 < $g_lineCount
            Local $text = $teleList_whole[$i]
            Local $split = StringSplit($text, $g_telelist_split_str)
            ;~ print($i & " UBound($split) is " & UBound($split) & "------" & $split[0] & ", " & $split[1])
            ;~ StringSplit 返回值的第一个元素是数组的个数(即 : 分割的数量+1)
            If UBound($split) - 1 = $columnCount Then
                ;~ print("UBound($split) is " & $columnCount)

                Local $telePointText[0]
                For $j = 1 To $split[0]
                    _ArrayAdd($telePointText, $split[$j])
                    ;~ print($j & " Add " & $split[$j])
                Next

                ;~ Local $telePointText = StringReplace($text, $g_telelist_split_str, "|")

                Local $textsplit = StringSplit($split[1], "-")
    
                If $textsplit[0] > 0 Then
                    $text = $textsplit[1] ; 获取"-"前面的部分
                EndIf

                $category = GenTeleListByCategory($category, $text, $telePointText)
                $category = GenTeleListByCategory($category, "所有", $telePointText)
                ;~ _ArrayAdd($g_teleList_whole, $telePointText)
                ;~ print("UBound($g_teleList_whole) is " & UBound($g_teleList_whole))
                $i = $i + 1
            Else
                If $i + $columnCount-1 >= $g_lineCount Then
                    ExitLoop
                EndIf

                Local $telePointText = $text
                For $c = 1 to $columnCount - 1
                    $telePointText = $telePointText & "|" & $teleList_whole[$i+$c]
                Next
                ;~ print($telePointText)

                Local $textsplit = StringSplit($text, "-")

                If $textsplit[0] > 0 Then
                    $text = $textsplit[1] ; 获取"-"前面的部分
                EndIf

                $category = GenTeleListByCategory($category, $text, $telePointText)
                $category = GenTeleListByCategory($category, "所有", $telePointText)
                ;~ print("UBound($g_teleList_whole) is " & UBound($g_teleList_whole))
                $i = $i + $columnCount
            EndIf
        WEnd
    EndIf

    ;~ For $i = 0 to UBound($category) - 1
    ;~     print("category " & $category[$i])
    ;~ Next

    return $category
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
        _GUICtrlListView_Scroll($listview, 0, -10000)
        _GUICtrlListView_DeleteAllItems($listview)
        print("reload")
    Endif

    return SwitchListviewWithCategory($g_category_selected)
EndFunc

Func InitComboBox(Byref $category, $comboBox = 0)
    If $comboBox = 0 Then
        $comboBox = GUICtrlCreateCombo("所有", 10, 00, 180, 20)
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

    $res = GUICtrlCreateButton("res",           10,  640, 70, 20) ;~ for combobox

    $g_speed = GUICtrlCreateInput("",           100, 640, 35, 20)
    $speed_swi = GUICtrlCreateCheckbox("speed", 135, 640, 60, 20)

    $login = GUICtrlCreateButton("login",       190, 640, 70, 20)

    $g_log = GUICtrlCreateEdit("",                10,  670, 380, 200, BitOR($ES_AUTOVSCROLL, $WS_VSCROLL))

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
            Case $msg = $addPos
                AddPos($g_input, $listview, GUICtrlRead($comboBox))
            Case $msg = $editPos
                EditPos($g_input, $listview, GUICtrlRead($comboBox))
            Case $msg = $delPos
                DelPos($listview, GUICtrlRead($comboBox))
            Case $msg = $save
                Save($listview, $comboBox)
            Case $msg = $reload
                ReloadUI($listview, $comboBox, $pidList, $playernameList)
            Case $msg = $teleport
                Teleport($listview)
			Case $msg = $sync
				SyncTeleport($sync)
			Case $msg = $step
				StepCheckbox($step)
			Case $msg = $farmEYun
				FarmCheckbox($farmEYun)
			Case $msg = $pidList
				SelectSingleWowPid($pidList)
            Case $msg = $speed_swi
                SwitchSpeed($speed_swi)
            Case $msg = $comboBox
                SwitchListview(GUICtrlRead($comboBox))
        EndSelect
    Until $msg = $GUI_EVENT_CLOSE
EndFunc
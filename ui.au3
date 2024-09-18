
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

Func InitListview($listview = 0)
    If $listview = 0 Then
        print("launch ui")
    Else
        GUICtrlDelete($listview)
        print("reload")
    Endif

    $listview = GUICtrlCreateListView("        描述        |      x      |      y      |      z      ", 10, 10, 380, 500)
    $g_listview = $listview
    $columnCount = _GUICtrlListView_GetColumnCount($listview)


    Local $tpInfoArray = FileReadToArray($teleport_file)
    Local $lineCount = @extended
    print("$lineCount : " & $lineCount)
    If @error Then
        MsgBox($MB_SYSTEMMODAL, "", "There was an error reading the file. @error: " & @error)
    Else
        Local $i = 0
        While $i + $columnCount-1 < $lineCount
            $text = $tpInfoArray[$i]
            For $c = 1 to $columnCount - 1
                $text = $text & "|" & $tpInfoArray[$i+$c]
            Next
            $i = $i + $columnCount
            GUICtrlCreateListViewItem($text, $listview)
        WEnd
    EndIf

    return $listview
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

    Local $button, $msg

    $ui = GUICreate($winTitle, 400, 880, 100, 200, -1, $WS_EX_ACCEPTFILES)
    GUISetBkColor(0x00E0FFFF) ; will change background color
    GUISetState(@SW_SHOW)

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

    $login = GUICtrlCreateButton("login",       10,  610, 70, 20)
    $save = GUICtrlCreateButton("save",         100, 610, 70, 20)
    $reload = GUICtrlCreateButton("reload",     190, 610, 70, 20)

    $res = GUICtrlCreateButton("res",           10,  640, 70, 20) ;~ for combobox

    $g_speed = GUICtrlCreateInput("",           100, 640, 35, 20)
    $speed_swi = GUICtrlCreateCheckbox("speed", 135, 640, 60, 20)

    $log = GUICtrlCreateEdit("",                10,  670, 380, 200, BitOR($ES_AUTOVSCROLL, $WS_VSCROLL))

    ;~ richEdit loaded too slow
    ;~ $log = _GUICtrlRichEdit_Create($ui, "", 10, 610, 380, 320, BitOR($ES_MULTILINE, $WS_VSCROLL, $ES_AUTOVSCROLL))

    GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
    Do
        $msg = GUIGetMsg()
        Select
            Case $msg = $login
                Login()
            Case $msg = $addPos
                AddPos($g_input, $listview)
            Case $msg = $editPos
                EditPos($g_input, $listview)
            Case $msg = $delPos
                DelPos($listview)
            Case $msg = $save
                Save($listview)
            Case $msg = $reload
                ReloadUI($listview, $pidList, $playernameList)
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
        EndSelect
    Until $msg = $GUI_EVENT_CLOSE
EndFunc
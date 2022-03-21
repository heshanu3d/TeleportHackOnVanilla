Func InitPidList($wowPidList)
	$pidList = GUICtrlCreateList("", 250, 520, 120, 60)
	GUICtrlSetLimit($pidList, 200)
	For $i = 1 to UBound($wowPidList) - 1
		GUICtrlSetData($pidList, $wowPidList[$i])
		print($wowPidList[$i])
	Next
	return $pidList
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

Func LaunchUI($wowPidList)
	If UBound($wowPidList) = 1 Then
		Return
	EndIf
    Local $button, $msg

	HotKeyReg()

    $ui = GUICreate($winTitle, 400, 850, 100, 200, -1, $WS_EX_ACCEPTFILES)
    GUISetBkColor(0x00E0FFFF) ; will change background color
    GUISetState(@SW_SHOW)

    $listview = InitListview()
    $g_listview = $listview
	$input = GUICtrlCreateInput("",      10,  520, 210, 20)
	$list = InitPidList($wowPidList)
	$sync = GUICtrlCreateCheckbox("sync-teleport", 10, 550, 150, 20)
	$farmEYun = GUICtrlCreateCheckbox("厄运",    170, 550, 50, 20)
    $addPos = GUICtrlCreateButton("addPos",     10,  580, 70, 20)
    $editPos = GUICtrlCreateButton("editPos",   100, 580, 70, 20)
    $delPos = GUICtrlCreateButton("delPos",     190, 580, 70, 20)

    $teleport = GUICtrlCreateButton("Teleport", 280, 580, 100, 50)

    $goHome = GUICtrlCreateButton("goHome",     10,  610, 70, 20)
    $save = GUICtrlCreateButton("save",         100, 610, 70, 20)
    $reload = GUICtrlCreateButton("reload",     190, 610, 70, 20)

    $log = GUICtrlCreateEdit("",                10, 640, 380, 200, BitOR($ES_AUTOVSCROLL, $WS_VSCROLL))

    ;~ richEdit loaded too slow
    ;~ $log = _GUICtrlRichEdit_Create($ui, "", 10, 610, 380, 320, BitOR($ES_MULTILINE, $WS_VSCROLL, $ES_AUTOVSCROLL))

    GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
    Do
        $msg = GUIGetMsg()
        Select
            Case $msg = $goHome
                GoHome()
            Case $msg = $addPos
                AddPos($input, $listview)
            Case $msg = $editPos
                EditPos($input, $listview)
            Case $msg = $delPos
                DelPos($listview)
            Case $msg = $save
                Save($listview)
            Case $msg = $reload
                ReloadUI($listview)
            Case $msg = $teleport
                Teleport($listview)
			Case $msg = $sync
				SyncTeleport($sync, $wowPidList)
			Case $msg = $farmEYun
				FarmCheckbox($farmEYun)
			Case $msg = $list
				SelectSingleWowPid($list)
        EndSelect
    Until $msg = $GUI_EVENT_CLOSE
EndFunc
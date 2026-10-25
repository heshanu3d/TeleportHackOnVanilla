
Func InitPidAndPlaynameList(ByRef $pidList, ByRef $playernameList)
	If $pidList <> 0 Then
		$WowProcessList = ProcessList($exe)
		Local $wowPidList = []
		For $i = 1 to $WowProcessList[0][0]
			print("WoW pid:" & $WowProcessList[$i][1])
			_ArrayAdd($wowPidList, $WowProcessList[$i][1])
		Next
		$g_wowPidList = $wowPidList
		_GUICtrlListBox_ResetContent($pidList)
	EndIf
	If $playernameList <> 0 Then
		_GUICtrlListBox_ResetContent($playernameList)
	EndIf
	If $pidList = 0 Then $pidList = GUICtrlCreateList("", 250, 620, 60, 50, $LBS_DISABLENOSCROLL)
	If $playernameList = 0 Then $playernameList = GUICtrlCreateList("", 315, 620, 60, 50, $LBS_DISABLENOSCROLL)

	GUICtrlSetLimit($pidList, 200)
	GUICtrlSetLimit($playernameList, 200)
	$playerNames = Sync(GetPlayerName)
	If UBound($playerNames) <> UBound($g_wowPidList) Then
		print("UBound($playerNames) <> UBound($g_wowPidList)")
	EndIf
	For $i = 1 to UBound($g_wowPidList) - 1
		GUICtrlSetData($pidList, $g_wowPidList[$i])
		If $i < UBound($playerNames) Then
			If $playerNames[$i] <> "" Then GUICtrlSetData($playernameList, $playerNames[$i])
		EndIf
		;print($g_wowPidList[$i])
		;print($playerNames[$i])
	Next
	SelectOnlyWowPid($pidList, $playernameList)
EndFunc

Func SelectOnlyWowPid($pidList, $playernameList)
	If _GUICtrlListBox_GetCount($pidList) <> 1 Then Return
	If _GUICtrlListBox_SetCurSel($pidList, 0) < 0 Then Return
	If _GUICtrlListBox_GetCount($playernameList) = 1 Then _GUICtrlListBox_SetCurSel($playernameList, 0)
	If $g_syncTeleport Then
		$g_selectPid = Number(_GUICtrlListBox_GetText($pidList, 0))
		$g_hwnd = _WinGetHandleByPidAndCls($g_selectPid, "GxWindowClassD3d")
	Else
		SelectSingleWowPid($pidList)
	EndIf
EndFunc

Func ShouldReloadForSingleWowProcess(ByRef $wowProcesses, $selectedPid)
    If Not IsArray($wowProcesses) Then Return False
    If $wowProcesses[0][0] <> 1 Then Return False
    Return Number($wowProcesses[1][1]) <> Number($selectedPid)
EndFunc

Func CheckWowPidForReload($listview, ByRef $pidList, ByRef $playernameList)
    Local $wowProcesses = ProcessList($exe)
    If Not ShouldReloadForSingleWowProcess($wowProcesses, $g_selectPid) Then Return False
    print("WoW PID changed: " & $g_selectPid & " -> " & $wowProcesses[1][1] & "; reloading")
    ReloadUI($listview, $pidList, $playernameList)
    Return True
EndFunc

Func ParseWowPidPollSeconds($value, $fallback = 30)
    Local $text = StringStripWS(String($value), 3)
    If Not StringIsInt($text) Then Return $fallback
    Local $seconds = Int($text)
    If $seconds < 1 Or $seconds > 3600 Then Return $fallback
    Return $seconds
EndFunc

Func LoadWowPidPollInterval()
    Local $seconds = ParseWowPidPollSeconds(IniRead($g_wowPidPollSettingsPath, "Timer", "pid_poll_seconds", "30"))
    $g_wowPidPollIntervalMs = $seconds * 1000
    Return $seconds
EndFunc

Func ApplyWowPidPollInterval($input)
    Local $seconds = ParseWowPidPollSeconds(GUICtrlRead($input), 0)
    If $seconds = 0 Then
        GUICtrlSetData($input, Int($g_wowPidPollIntervalMs / 1000))
        Return False
    EndIf
    GUICtrlSetData($input, $seconds)
    $g_wowPidPollIntervalMs = $seconds * 1000
    If Not IniWrite($g_wowPidPollSettingsPath, "Timer", "pid_poll_seconds", $seconds) Then print("Failed to save WoW PID poll interval")
    Return True
EndFunc

Func InitTeleportList()
    Local $tTotal = TimerInit()

    InitGlobalTeleportList()

    $teleList_whole = FileReadToArray($teleport_file)
    $g_lineCount = @extended
    Local $bFileError = @error
    Local $tFileRead = TimerDiff($tTotal)
    print("$g_lineCount : " & $g_lineCount)
    $columnCount = 5

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

        Local $fieldCount = $split[0]
        If $fieldCount = $columnCount Or $fieldCount = $columnCount - 1 Then
            ; # 格式：一行包含 desc#x#y#z[#r]
            ; 5 字段为新格式(含朝向 r)，4 字段为旧格式(无朝向，补空 r 以保持 stride 一致)
            Local $bPadR = ($fieldCount < $columnCount)
            ; 提取分类名（取描述字段中"-"前面的部分）
            Local $cateText = $split[1]
            Local $dashSplit = StringSplit($cateText, "-")
            If $dashSplit[0] > 0 Then $cateText = $dashSplit[1]

            ; 加入 "所有" 列表
            For $j = 1 To $fieldCount
                $allList.Add($split[$j])
            Next
            If $bPadR Then $allList.Add("")

            ; 加入对应分类列表
            If Not $catDict.Exists($cateText) Then
                $catDict.Add($cateText, ObjCreate("System.Collections.ArrayList"))
                $categoryOrder.Add($cateText)
            EndIf
            Local $catList = $catDict.Item($cateText)
            For $j = 1 To $fieldCount
                $catList.Add($split[$j])
            Next
            If $bPadR Then $catList.Add("")

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
        $listview = GUICtrlCreateListView("        描述        |      x      |      y      |      z      |      r      ", 10, 35, 380, 400)
        GUICtrlSendMsg($listview, $LVM_SETCOLUMNWIDTH, 0, 175)
        GUICtrlSendMsg($listview, $LVM_SETCOLUMNWIDTH, 1, 58)
        GUICtrlSendMsg($listview, $LVM_SETCOLUMNWIDTH, 2, 58)
        GUICtrlSendMsg($listview, $LVM_SETCOLUMNWIDTH, 3, 52)
        GUICtrlSendMsg($listview, $LVM_SETCOLUMNWIDTH, 4, 37)
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

Func CategoryGridGroup($name)
    Switch $name
        Case "艾尔文森林", "西部荒野", "赤脊山", "湿地", "暮色森林", "希尔斯布莱德", "阿拉希", "奥特兰克", "丹莫罗", "洛克莫丹", "荒芜之地", "荆棘谷", "灼热峡谷", "悲伤沼泽", "辛特兰", "诅咒之地", "燃烧平原", "西瘟疫", "东瘟疫"
            Return 1
        Case "泰达希尔", "灰谷", "闪光平原", "杜隆塔尔", "贫瘠之地", "尘泥沼泽", "凄凉之地", "菲拉斯", "塔纳利斯", "月光林地", "棘齿城", "安戈洛", "达纳苏斯", "冬泉谷", "希利苏斯"
            Return 2
        Case "地狱火半岛", "赞加沼泽", "纳格兰", "泰罗卡森林", "刀锋山", "虚空风暴", "影月谷"
            Return 3
        Case "死亡骑士", "秘血岛", "秘蓝岛", "嚎风峡湾", "北风苔原", "龙骨荒野", "晶歌森林", "祖达克", "索拉查盆地", "灰熊丘陵", "风暴峭壁", "冰冠冰川"
            Return 4
    EndSwitch
    Return 0
EndFunc

Func RefreshCategoryGrid(ByRef $category)
    If $g_categoryGrid = 0 Then Return
    Local $groups[5] = ["杂项", "东部王国", "卡利姆多", "燃烧的远征", "巫妖王之怒"]
    _GUICtrlListView_BeginUpdate($g_categoryGrid)
    _GUICtrlListView_DeleteAllItems($g_categoryGrid)
    For $group = 0 To 4
        If $group > 0 Then _GUICtrlListView_AddItem($g_categoryGrid, "")
        $g_categoryGroupRows[$group] = _GUICtrlListView_AddItem($g_categoryGrid, "【" & $groups[$group] & "】")
        Local $column = 0
        Local $row = -1
        If $group = 0 Then
            $row = _GUICtrlListView_AddItem($g_categoryGrid, "所有")
            $column = 1
        EndIf
        For $i = 0 To UBound($category) - 1
            If CategoryGridGroup($category[$i]) <> $group Then ContinueLoop
            If $column = 0 Then
                $row = _GUICtrlListView_AddItem($g_categoryGrid, $category[$i])
            Else
                _GUICtrlListView_AddSubItem($g_categoryGrid, $row, $category[$i], $column)
            EndIf
            $column = Mod($column + 1, 3)
        Next
    Next
    _GUICtrlListView_EndUpdate($g_categoryGrid)
EndFunc

Func RefreshRecentTeleportList()
    If $g_recentListview = 0 Then Return
    _GUICtrlListView_BeginUpdate($g_recentListview)
    _GUICtrlListView_DeleteAllItems($g_recentListview)
    For $i = 0 To $g_recentTeleportCount - 1
        Local $row = _GUICtrlListView_AddItem($g_recentListview, $g_recentTeleports[$i][0])
        For $column = 1 To 3
            _GUICtrlListView_AddSubItem($g_recentListview, $row, $g_recentTeleports[$i][$column], $column)
        Next
    Next
    _GUICtrlListView_EndUpdate($g_recentListview)
EndFunc

Func RecordRecentTeleport($x, $y, $z, $r = "", $label = "")
    If $label = "" Then $label = "坐标点"
    Local $existing = -1
    For $i = 0 To $g_recentTeleportCount - 1
        If String($g_recentTeleports[$i][1]) = String($x) And String($g_recentTeleports[$i][2]) = String($y) And String($g_recentTeleports[$i][3]) = String($z) Then
            $existing = $i
            ExitLoop
        EndIf
    Next
    If $existing = -1 Then
        If $g_recentTeleportCount < $g_recentTeleportLimit Then $g_recentTeleportCount += 1
        $existing = $g_recentTeleportCount - 1
    EndIf
    For $i = $existing To 1 Step -1
        For $column = 0 To 4
            $g_recentTeleports[$i][$column] = $g_recentTeleports[$i - 1][$column]
        Next
    Next
    $g_recentTeleports[0][0] = $label
    $g_recentTeleports[0][1] = $x
    $g_recentTeleports[0][2] = $y
    $g_recentTeleports[0][3] = $z
    $g_recentTeleports[0][4] = $r
    RefreshRecentTeleportList()
EndFunc

Func ApplyPendingRecentTeleport()
    Local $row = $g_pendingRecentTeleport
    $g_pendingRecentTeleport = -1
    If $row < 0 Or $row >= $g_recentTeleportCount Then Return
    TeleportInterface($g_recentTeleports[$row][1], $g_recentTeleports[$row][2], $g_recentTeleports[$row][3], $g_recentTeleports[$row][4], $g_recentTeleports[$row][0])
EndFunc

Func ApplyPendingCategory()
    If $g_pendingCategory = "" Then Return
    Local $selectedCategory = $g_pendingCategory
    $g_pendingCategory = ""
    If $selectedCategory <> "所有" And Not $g_teleListDict.Exists($selectedCategory) Then Return
    SwitchListview($selectedCategory)
    If $g_categoryLabel <> 0 Then GUICtrlSetData($g_categoryLabel, "当前：" & $selectedCategory)
    _GUICtrlTab_ActivateTab($g_categoryTab, 0)
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

    $ui = GUICreate($winTitle, 400, 925, 100, 80, -1, $WS_EX_ACCEPTFILES)
    GUISetBkColor(0x00E0FFFF) ; will change background color
    Local $pollSeconds = LoadWowPidPollInterval()
    $g_categoryTab = GUICtrlCreateTab(0, 0, 400, 920)
    GUICtrlCreateTabItem("坐标点")
    $g_log = GUICtrlCreateEdit("", 10, 735, 380, 175, BitOR($ES_AUTOVSCROLL, $WS_VSCROLL))

    Local $category = InitTeleportList()
    $listview = InitListview()
    $g_listview = $listview

    GUICtrlCreateLabel("最近使用的坐标", 10, 443, 180, 20)
    $g_categoryLabel = GUICtrlCreateLabel("当前：" & $g_category_selected, 190, 443, 200, 20, $SS_RIGHT)
    $g_recentListview = GUICtrlCreateListView("最近使用|x|y|z", 10, 463, 380, 147)
    _GUICtrlListView_SetColumnWidth($g_recentListview, 0, 160)
    _GUICtrlListView_SetColumnWidth($g_recentListview, 1, 72)
    _GUICtrlListView_SetColumnWidth($g_recentListview, 2, 72)
    _GUICtrlListView_SetColumnWidth($g_recentListview, 3, 60)
    _GUICtrlListView_SetExtendedListViewStyle($g_recentListview, $LVS_EX_FULLROWSELECT)
    RefreshRecentTeleportList()

	$g_input = GUICtrlCreateInput("", 10, 620, 225, 22)
	Local $pidList = 0
	Local $playernameList = 0
	InitPidAndPlaynameList($pidList, $playernameList)
    $addPos = GUICtrlCreateButton("addPos", 10, 650, 70, 22)
    $editPos = GUICtrlCreateButton("editPos", 88, 650, 70, 22)
    $delPos = GUICtrlCreateButton("delPos", 166, 650, 70, 22)
    $insertPos = GUICtrlCreateButton("insertPos", 10, 680, 85, 22)
    $appendPos = GUICtrlCreateButton("appendPos", 100, 680, 85, 22)
    $save = GUICtrlCreateButton("save", 190, 680, 85, 22)
    $reload = GUICtrlCreateButton("reload", 280, 680, 100, 22)
    $onTop = GUICtrlCreateCheckbox("OnTop", 10, 710, 75, 20)

    GUICtrlCreateTabItem("分类导航")
    $g_categoryGrid = GUICtrlCreateListView("分类|分类|分类", 10, 40, 380, 865)
    For $column = 0 To 2
        _GUICtrlListView_SetColumnWidth($g_categoryGrid, $column, 116)
    Next
    GUICtrlSetFont($g_categoryGrid, 10, 700, 0, "Microsoft YaHei UI")
    _GUICtrlListView_SetExtendedListViewStyle($g_categoryGrid, BitOR($LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_FULLROWSELECT))
    RefreshCategoryGrid($category)

    GUICtrlCreateTabItem("设置")
    GUICtrlCreateLabel("传送设置", 16, 44, 120, 20)
    $sync = GUICtrlCreateCheckbox("sync-tp", 16, 72, 82, 22)
    $step = GUICtrlCreateCheckbox("step-tp", 112, 72, 82, 22)
    $farmEYun = GUICtrlCreateCheckbox("厄运", 208, 72, 75, 22)
    $fastStep = GUICtrlCreateCheckbox("fastStep", 290, 72, 90, 22)
    $g_speed = GUICtrlCreateInput("", 16, 106, 60, 22)
    $speed_swi = GUICtrlCreateCheckbox("speed", 88, 106, 80, 22)
    GUICtrlCreateLabel("其他操作", 16, 152, 120, 20)
    $home = GUICtrlCreateButton("home", 16, 180, 88, 26)
    $login = GUICtrlCreateButton("login", 112, 180, 88, 26)
    GUICtrlCreateLabel("WoW PID 查询间隔", 16, 238, 180, 20)
    Local $pidPollInput = GUICtrlCreateInput($pollSeconds, 16, 266, 64, 22, $ES_NUMBER)
    GUICtrlSetLimit($pidPollInput, 4)
    GUICtrlCreateLabel("秒", 88, 269, 28, 20)
    Local $applyPollInterval = GUICtrlCreateButton("应用", 124, 264, 70, 26)

    GUICtrlCreateTabItem("关于")
    GUICtrlCreateLabel("TeleportHack On Vanilla and WLK", 16, 42, 365, 24)
    GUICtrlCreateLabel("作者：shan.he", 16, 72, 365, 22)
    GUICtrlCreateLabel("版本更新日志", 16, 110, 365, 22)
    Local $releaseNotes = GUICtrlCreateEdit(GetReleaseNotes(), 16, 138, 368, 755, BitOR($ES_READONLY, $ES_MULTILINE, $WS_VSCROLL, $ES_AUTOVSCROLL))
    GUICtrlSetFont($releaseNotes, 9, 400, 0, "Microsoft YaHei UI")
    GUICtrlCreateTabItem("")
    GUISetState(@SW_SHOW)

    GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
    Local $pidPollTimer = TimerInit()
    Do
        $msg = GUIGetMsg()
        ApplyPendingCategory()
        ApplyPendingRecentTeleport()
        If TimerDiff($pidPollTimer) >= $g_wowPidPollIntervalMs Then
            $pidPollTimer = TimerInit()
            CheckWowPidForReload($listview, $pidList, $playernameList)
        EndIf
        Select
            Case $msg = $login
                Login()
            Case $msg = $insertPos
                InsertPos($g_input, $listview, $g_category_selected)
            Case $msg = $appendPos
                AppendPos($g_input, $listview, $g_category_selected)
            Case $msg = $addPos
                AddPos($g_input, $listview, $g_category_selected)
            Case $msg = $editPos
                EditPos($g_input, $listview, $g_category_selected)
            Case $msg = $delPos
                DelPos($listview, $g_category_selected)
            Case $msg = $save
                Save($listview)
                ReloadUI($listview, $pidList, $playernameList)
            Case $msg = $reload
                ReloadUI($listview, $pidList, $playernameList)
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
            Case $msg = $applyPollInterval
                If ApplyWowPidPollInterval($pidPollInput) Then $pidPollTimer = TimerInit()
            Case $msg = $home
                Home()
            Case $msg = $onTop
                WinSetOnTop($ui, "", BitAND(GUICtrlRead($onTop), $GUI_CHECKED) <> 0)
        EndSelect
    Until $msg = $GUI_EVENT_CLOSE
EndFunc

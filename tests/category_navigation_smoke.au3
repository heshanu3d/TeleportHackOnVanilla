#NoTrayIcon
#include <ScreenCapture.au3>

Global $version = "1.12.3"
Global $exe = "WoW.exe"
Global $winTitle = "Category navigation smoke test"
Global $CurrPosX = 0, $CurrPosY = 0, $CurrPosZ = 0
Global $StaticPlayer = 0, $PbPointer1 = 0, $PbPointer2 = 0
Global $PosX = 0, $PosY = 0, $PosZ = 0, $PosR = 0, $MapID = 0
Global $AntiJump = 0, $JumpGravity = 0, $PlayerName = 0, $SpeedGlobal = 0
Global $autoloot_2 = 0, $patch_loot = 0, $patch_loot2 = 0, $patch_lootslot = 0, $luaUnlock = 0
#include "..\include.au3"

Global $smokeReport = @TempDir & "\teleport_category_navigation_smoke.txt"
Global $visitedCategoryColumns[3]
FileDelete($smokeReport)
Local $ui = GUICreate($winTitle, 400, 925, 100, 80)
$g_categoryTab = GUICtrlCreateTab(0, 0, 400, 920)
GUICtrlCreateTabItem("坐标点")
$g_log = GUICtrlCreateEdit("", 10, 735, 380, 175)
Local $categories = InitTeleportList()
$g_listview = InitListview()
GUICtrlCreateLabel("最近使用的坐标", 10, 443, 180, 20)
$g_categoryLabel = GUICtrlCreateLabel("当前：所有", 190, 443, 200, 20, $SS_RIGHT)
$g_recentListview = GUICtrlCreateListView("最近使用|x|y|z", 10, 463, 380, 147)
_GUICtrlListView_SetColumnWidth($g_recentListview, 0, 160)
_GUICtrlListView_SetColumnWidth($g_recentListview, 1, 72)
_GUICtrlListView_SetColumnWidth($g_recentListview, 2, 72)
_GUICtrlListView_SetColumnWidth($g_recentListview, 3, 60)
_GUICtrlListView_SetExtendedListViewStyle($g_recentListview, $LVS_EX_FULLROWSELECT)
$g_input = GUICtrlCreateInput("", 10, 620, 225, 22)
GUICtrlCreateList("", 250, 620, 60, 50, $LBS_DISABLENOSCROLL)
GUICtrlCreateList("", 315, 620, 60, 50, $LBS_DISABLENOSCROLL)
GUICtrlCreateButton("addPos", 10, 650, 70, 22)
GUICtrlCreateButton("editPos", 88, 650, 70, 22)
GUICtrlCreateButton("delPos", 166, 650, 70, 22)
GUICtrlCreateButton("insertPos", 10, 680, 85, 22)
GUICtrlCreateButton("appendPos", 100, 680, 85, 22)
GUICtrlCreateButton("save", 190, 680, 85, 22)
GUICtrlCreateButton("reload", 280, 680, 100, 22)
GUICtrlCreateCheckbox("OnTop", 10, 710, 75, 20)

GUICtrlCreateTabItem("分类导航")
$g_categoryGrid = GUICtrlCreateListView("分类|分类|分类", 10, 40, 380, 865)
For $column = 0 To 2
    _GUICtrlListView_SetColumnWidth($g_categoryGrid, $column, 116)
Next
GUICtrlSetFont($g_categoryGrid, 10, 700, 0, "Microsoft YaHei UI")
_GUICtrlListView_SetExtendedListViewStyle($g_categoryGrid, BitOR($LVS_EX_GRIDLINES, $LVS_EX_FULLROWSELECT))
RefreshCategoryGrid($categories)
GUICtrlCreateTabItem("设置")
GUICtrlCreateLabel("传送设置", 16, 44, 120, 20)
GUICtrlCreateCheckbox("sync-tp", 16, 72, 82, 22)
GUICtrlCreateCheckbox("step-tp", 112, 72, 82, 22)
GUICtrlCreateCheckbox("厄运", 208, 72, 75, 22)
GUICtrlCreateCheckbox("fastStep", 290, 72, 90, 22)
GUICtrlCreateInput("", 16, 106, 60, 22)
GUICtrlCreateCheckbox("speed", 88, 106, 80, 22)
GUICtrlCreateLabel("其他操作", 16, 152, 120, 20)
GUICtrlCreateButton("home", 16, 180, 88, 26)
GUICtrlCreateButton("login", 112, 180, 88, 26)
GUICtrlCreateLabel("WoW PID 查询间隔", 16, 238, 180, 20)
Local $pollInput = GUICtrlCreateInput("30", 16, 266, 64, 22, $ES_NUMBER)
GUICtrlSetLimit($pollInput, 4)
GUICtrlCreateLabel("秒", 88, 269, 28, 20)
GUICtrlCreateButton("应用", 124, 264, 70, 26)
GUICtrlCreateTabItem("关于")
GUICtrlCreateLabel("TeleportHack On Vanilla and WLK", 16, 42, 365, 24)
Local $authorLabel = GUICtrlCreateLabel("作者：shan.he", 16, 72, 365, 22)
GUICtrlCreateLabel("版本更新日志", 16, 110, 365, 22)
Local $notesEdit = GUICtrlCreateEdit(GetReleaseNotes(), 16, 138, 368, 755, BitOR($ES_READONLY, $ES_MULTILINE, $WS_VSCROLL, $ES_AUTOVSCROLL))
GUICtrlSetFont($notesEdit, 9, 400, 0, "Microsoft YaHei UI")
GUICtrlCreateTabItem("")
GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
GUISetState(@SW_SHOW)

If GUICtrlRead($authorLabel) <> "作者：shan.he" Then Fail("about author missing")
Local $tagNames[11] = ["v0.1", "v0.2", "v0.3", "v0.4", "v0.4.1", "v0.4.2", "v0.4.3", "v0.4.4", "v0.5", "v0.5.1", "0.5.2"]
For $i = 0 To UBound($tagNames) - 1
    If StringInStr(GUICtrlRead($notesEdit), $tagNames[$i] & @CRLF) = 0 Then Fail("about release notes missing: " & $tagNames[$i])
Next

For $i = 0 To 4
    If _GUICtrlListView_GetItemText($g_categoryGrid, $g_categoryGroupRows[$i], 0) = "" Then Fail("missing group header: " & $i)
    If $i > 0 And $g_categoryGroupRows[$i] <= $g_categoryGroupRows[$i - 1] + 1 Then Fail("missing group boundary: " & $i)
Next

For $i = 1 To 21
    RecordRecentTeleport($i, $i + 1, $i + 2, "", "point " & $i)
Next
If $g_recentTeleportCount <> 20 Or _GUICtrlListView_GetItemCount($g_recentListview) <> 20 Then Fail("recent list did not cap at twenty")
If _GUICtrlListView_GetItemText($g_recentListview, 0) <> "point 21" Or _GUICtrlListView_GetItemText($g_recentListview, 19) <> "point 2" Then Fail("recent list ordering")
RecordRecentTeleport(3, 4, 5, "", "again")
If $g_recentTeleportCount <> 20 Or _GUICtrlListView_GetItemText($g_recentListview, 0) <> "again" Then Fail("recent point did not move to top")
For $i = 1 To 19
    If _GUICtrlListView_GetItemText($g_recentListview, $i) = "point 3" Then Fail("recent list contains duplicate")
Next
CheckRecentDoubleClick($ui, 1, 1)
If EnvGet("TELEPORT_MAIN_SCREENSHOT") <> "" Then
    WinSetOnTop($ui, "", 1)
    WinActivate($ui)
    Sleep(150)
    _ScreenCapture_CaptureWnd(EnvGet("TELEPORT_MAIN_SCREENSHOT"), $ui)
    WinSetOnTop($ui, "", 0)
EndIf
If EnvGet("TELEPORT_SETTINGS_SCREENSHOT") <> "" Then
    _GUICtrlTab_ActivateTab($g_categoryTab, 2)
    Sleep(100)
    _ScreenCapture_CaptureWnd(EnvGet("TELEPORT_SETTINGS_SCREENSHOT"), $ui)
EndIf
If EnvGet("TELEPORT_ABOUT_SCREENSHOT") <> "" Then
    _GUICtrlTab_ActivateTab($g_categoryTab, 3)
    Sleep(100)
    _ScreenCapture_CaptureWnd(EnvGet("TELEPORT_ABOUT_SCREENSHOT"), $ui)
EndIf
If EnvGet("TELEPORT_NAV_SCREENSHOT") <> "" Then
    _GUICtrlTab_ActivateTab($g_categoryTab, 1)
    Sleep(100)
    _ScreenCapture_CaptureWnd(EnvGet("TELEPORT_NAV_SCREENSHOT"), $ui)
EndIf

CheckClick($ui, "主城")
CheckClick($ui, "副本任务")
CheckClick($ui, "副本60")
CheckClick($ui, "地狱火半岛")
CheckClick($ui, "死亡骑士")
CheckClick($ui, "嚎风峡湾")
CheckClick($ui, "北风苔原")
For $column = 0 To 2
    If $visitedCategoryColumns[$column] = 0 Then Fail("category column not tested: " & $column)
Next
Local $pidList = 0, $playernameList = 0
$g_selectPid = @AutoItPID
SwitchListview("所有")
If _GUICtrlListView_GetItemCount($g_listview) < 40 Then Fail("not enough rows to test reload scroll")
Local $rowRect = _GUICtrlListView_GetItemRect($g_listview, 0)
_GUICtrlListView_Scroll($g_listview, 0, 30 * ($rowRect[3] - $rowRect[1]))
Local $topBeforeReload = _GUICtrlListView_GetTopIndex($g_listview)
If $topBeforeReload < 1 Then Fail("could not scroll list before reload")
ReloadUI($g_listview, $pidList, $playernameList)
If _GUICtrlListView_GetTopIndex($g_listview) <> $topBeforeReload Then Fail("reload did not preserve the first visible row")
If $g_recentTeleportCount <> 20 Or _GUICtrlListView_GetItemCount($g_recentListview) <> 20 Then Fail("reload cleared recent list")
If _GUICtrlListView_GetItemText($g_recentListview, 0) <> "again" Or _GUICtrlListView_GetItemText($g_recentListview, 1) <> "point 21" Then Fail("reload changed recent order")
CheckRecentDoubleClick($ui, 1, 1)
If $g_wowPidPollIntervalMs <> 30000 Then Fail("PID polling interval changed")
Local $pollProcesses[3][2]
$pollProcesses[1][1] = @AutoItPID
$pollProcesses[2][1] = @AutoItPID + 1
$pollProcesses[0][0] = 0
If ShouldReloadForSingleWowProcess($pollProcesses, 0) Then Fail("zero WoW processes triggered reload")
$pollProcesses[0][0] = 2
If ShouldReloadForSingleWowProcess($pollProcesses, 0) Then Fail("multiple WoW processes triggered reload")
$pollProcesses[0][0] = 1
If ShouldReloadForSingleWowProcess($pollProcesses, @AutoItPID) Then Fail("unchanged WoW PID triggered reload")
If Not ShouldReloadForSingleWowProcess($pollProcesses, @AutoItPID + 1) Then Fail("changed sole WoW PID did not trigger reload")
Local $originalSettingsPath = $g_wowPidPollSettingsPath
$g_wowPidPollSettingsPath = @TempDir & "\teleport_poll_smoke_" & @AutoItPID & ".ini"
FileDelete($g_wowPidPollSettingsPath)
If LoadWowPidPollInterval() <> 30 Then Fail("PID poll default interval")
GUICtrlSetData($pollInput, "12")
If Not ApplyWowPidPollInterval($pollInput) Or $g_wowPidPollIntervalMs <> 12000 Then Fail("PID poll interval was not applied")
If IniRead($g_wowPidPollSettingsPath, "Timer", "pid_poll_seconds", "") <> "12" Then Fail("PID poll interval was not persisted")
$g_wowPidPollIntervalMs = 30000
If LoadWowPidPollInterval() <> 12 Then Fail("PID poll interval was not restored")
GUICtrlSetData($pollInput, "0")
If ApplyWowPidPollInterval($pollInput) Or GUICtrlRead($pollInput) <> "12" Then Fail("PID poll accepted zero seconds")
GUICtrlSetData($pollInput, "3601")
If ApplyWowPidPollInterval($pollInput) Or GUICtrlRead($pollInput) <> "12" Then Fail("PID poll accepted out-of-range seconds")
FileDelete($g_wowPidPollSettingsPath)
$g_wowPidPollSettingsPath = $originalSettingsPath
$g_wowPidPollIntervalMs = 30000
Local $singlePid = GUICtrlCreateList("", 10, 35, 80, 50)
Local $singleName = GUICtrlCreateList("", 95, 35, 80, 50)
GUICtrlSetData($singlePid, @AutoItPID)
GUICtrlSetData($singleName, "self")
$g_selectPid = 0
SelectOnlyWowPid($singlePid, $singleName)
If _GUICtrlListBox_GetCurSel($singlePid) <> 0 Or _GUICtrlListBox_GetCurSel($singleName) <> 0 Then Fail("single PID was not selected")
If $g_selectPid <> @AutoItPID Or Not IsArray($g_singleWowProcess) Then Fail("single PID did not update process handle")
Local $multiPid = GUICtrlCreateList("", 10, 90, 80, 50)
Local $multiName = GUICtrlCreateList("", 95, 90, 80, 50)
GUICtrlSetData($multiPid, @AutoItPID & "|" & (@AutoItPID + 1))
SelectOnlyWowPid($multiPid, $multiName)
If $g_selectPid <> @AutoItPID Then Fail("multiple PIDs changed selection")
$g_syncTeleport = True
$g_selectPid = 0
SelectOnlyWowPid($singlePid, $singleName)
If $g_selectPid <> @AutoItPID Then Fail("sync mode did not remember sole PID")
$g_syncTeleport = False
Local $originalMapIdAddress = $MapID
Local $originalWowPidList = $g_wowPidList
Local $testMapValue = DllStructCreate("dword")
DllStructSetData($testMapValue, 1, 0)
$MapID = DllStructGetPtr($testMapValue)
If Not CanTeleportToMap(0) Or CanTeleportToMap(230) Then Fail("single process map validation failed")
Local $testPids[3] = [0, @AutoItPID, @AutoItPID]
$g_wowPidList = $testPids
$g_wowProcess[0][0] = $g_singleWowProcess[0]
$g_wowProcess[0][1] = $g_singleWowProcess[1]
$g_wowProcess[1][0] = $g_singleWowProcess[0]
$g_wowProcess[1][1] = $g_singleWowProcess[1]
$g_syncTeleport = True
If Not CanTeleportToMap(0) Or CanTeleportToMap(230) Then Fail("sync map validation failed")
$g_wowProcess[1][1] = 0
If CanTeleportToMap(0) Then Fail("sync map validation accepted unreadable process")
$g_syncTeleport = False
$g_wowPidList = $originalWowPidList
$MapID = 0
$version = "1.12.1"
If Not CanTeleportToMap(230) Then Fail("1.12.1 map fallback blocked existing teleport")
$version = "1.12.3"
$MapID = $originalMapIdAddress
_MemoryClose($g_singleWowProcess)
Local $originalFile = $teleport_file
$teleport_file = @TempDir & "\teleport_category_navigation_save.fav"
Save($g_listview)
Local $saved = FileReadToArray($teleport_file)
If @error Or UBound($saved) <> UBound($g_teleList_whole) / 6 Then Fail("category save lost points")
FileDelete($teleport_file)
$teleport_file = $originalFile

Local $fixtureFile = @TempDir & "\teleport_fav_fixture_" & @AutoItPID & ".fav"
Local $fixture = FileOpen($fixtureFile, $FO_OVERWRITE + $FO_UTF8_NOBOM)
FileWrite($fixture, "old4#1#2#3" & @CRLF & "old5#4#5#6#1.5" & @CRLF & _
    "zero#7#8#9#0#0" & @CRLF & "dungeon#10#11#12#2.5#230" & @CRLF & _
    "missingr#13#14#15##0" & @CRLF & "legacy4" & @CRLF & "16" & @CRLF & "17" & @CRLF & "18" & @CRLF & _
    "legacy5" & @CRLF & "19" & @CRLF & "20" & @CRLF & "21" & @CRLF & "1.25" & @CRLF)
FileClose($fixture)
$teleport_file = $fixtureFile
InitTeleportList()
If UBound($g_teleList_whole) <> 42 Then Fail("mixed fav formats lost rows")
If String($g_teleList_whole[4]) <> "" Or String($g_teleList_whole[5]) <> "" Then Fail("old four field record gained metadata")
If String($g_teleList_whole[16]) <> "0" Or String($g_teleList_whole[17]) <> "0" Then Fail("zero facing or map was lost")
If String($g_teleList_whole[23]) <> "230" Or String($g_teleList_whole[29]) <> "0" Then Fail("map metadata was not parsed")
If String($g_teleList_whole[40]) <> "1.25" Or String($g_teleList_whole[41]) <> "" Then Fail("legacy five-line record was not parsed")
Local $fixtureLines = FileReadToArray($fixtureFile)
Local $hotkeyPoint = FindPostionFromFavFile("zero", $fixtureLines, UBound($fixtureLines), True)
If UBound($hotkeyPoint) <> 5 Or String($hotkeyPoint[3]) <> "0" Or String($hotkeyPoint[4]) <> "0" Then Fail("hotkey metadata lost zero")
Local $legacyPoint = FindPostionFromFavFile("legacy5", $fixtureLines, UBound($fixtureLines), True)
If UBound($legacyPoint) <> 5 Or String($legacyPoint[3]) <> "1.25" Then Fail("hotkey legacy lookup failed")
Save($g_listview)
InitTeleportList()
If UBound($g_teleList_whole) <> 42 Or String($g_teleList_whole[17]) <> "0" Or String($g_teleList_whole[23]) <> "230" Then Fail("save reload lost map metadata")
If TeleportInterface(1, 2, 3, 0, "blocked", 0) <> False Then Fail("unverified map was not blocked")
FileDelete($fixtureFile)
$teleport_file = $originalFile
GUIDelete($ui)
FileWrite($smokeReport, "passed")
ConsoleWrite("category navigation smoke: passed" & @CRLF)
Exit 0

Func CheckClick($ui, $category)
    _GUICtrlTab_ActivateTab($g_categoryTab, 1)
    Local $row = -1
    Local $column = -1
    For $i = 0 To _GUICtrlListView_GetItemCount($g_categoryGrid) - 1
        For $candidate = 0 To 2
            If _GUICtrlListView_GetItemText($g_categoryGrid, $i, $candidate) = $category Then
                $row = $i
                $column = $candidate
                ExitLoop 2
            EndIf
        Next
    Next
    If $row < 0 Then
        Local $detail = "missing grid item: " & $category & ", rows=" & _GUICtrlListView_GetItemCount($g_categoryGrid)
        Local $sampleCount = _GUICtrlListView_GetItemCount($g_categoryGrid)
        If $sampleCount > 6 Then $sampleCount = 6
        For $i = 0 To $sampleCount - 1
            $detail &= " [" & $i & ":" & _GUICtrlListView_GetItemText($g_categoryGrid, $i, 0) & "|" & _GUICtrlListView_GetItemText($g_categoryGrid, $i, 1) & "|" & _GUICtrlListView_GetItemText($g_categoryGrid, $i, 2) & "]"
        Next
        Fail($detail)
    EndIf

    Local $rect = _GUICtrlListView_GetSubItemRect($g_categoryGrid, $row, $column)
    Local $x = $rect[0] + 30
    Local $y = Int(($rect[1] + $rect[3]) / 2)
    If Not ControlClick($ui, "", GUICtrlGetHandle($g_categoryGrid), "left", 1, $x, $y) Then Fail("click failed: " & $category)

    Local $timer = TimerInit()
    While TimerDiff($timer) < 3000
        GUIGetMsg()
        ApplyPendingCategory()
        If $g_category_selected = $category And GUICtrlRead($g_categoryLabel) = "当前：" & $category And _GUICtrlTab_GetCurSel($g_categoryTab) = 0 Then
            $visitedCategoryColumns[$column] += 1
            Return
        EndIf
        Sleep(10)
    WEnd
    Fail("navigation failed: " & $category & ", selected=" & $g_category_selected & ", tab=" & _GUICtrlTab_GetCurSel($g_categoryTab))
EndFunc

Func CheckRecentDoubleClick($ui, $row, $column)
    _GUICtrlTab_ActivateTab($g_categoryTab, 0)
    Local $rect = _GUICtrlListView_GetSubItemRect($g_recentListview, $row, $column)
    Local $x = $rect[0] + 25
    Local $y = Int(($rect[1] + $rect[3]) / 2)
    If Not ControlClick($ui, "", GUICtrlGetHandle($g_recentListview), "left", 2, $x, $y) Then Fail("recent double-click failed")
    Local $timer = TimerInit()
    While TimerDiff($timer) < 3000
        GUIGetMsg()
        If $g_pendingRecentTeleport = $row Then
            If $g_recentTeleports[$row][0] <> "point 21" Or $g_recentTeleports[$row][1] <> 21 Then Fail("recent selection lost coordinates")
            $g_pendingRecentTeleport = -1
            Return
        EndIf
        Sleep(10)
    WEnd
    Fail("recent double-click was not routed")
EndFunc

Func Fail($message)
    FileWrite($smokeReport, $message)
    ConsoleWriteError($message & @CRLF)
    Exit 1
EndFunc

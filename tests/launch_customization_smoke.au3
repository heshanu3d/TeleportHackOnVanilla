#NoTrayIcon
Global $version = "1.12.1", $exe = "WoW.exe", $winTitle = "Launch customization smoke"
Global $CurrPosX = 0, $CurrPosY = 0, $CurrPosZ = 0
Global $StaticPlayer = 0, $PbPointer1 = 0, $PbPointer2 = 0
Global $PosX = 0, $PosY = 0, $PosZ = 0, $PosR = 0, $MapID = 0
Global $AntiJump = 0, $JumpGravity = 0, $PlayerName = 0, $SpeedGlobal = 0
Global $autoloot_2 = 0, $patch_loot = 0, $patch_loot2 = 0, $patch_lootslot = 0, $luaUnlock = 0
#include "..\include.au3"
Global $report = @TempDir & "\teleport_launch_customization_smoke.txt"
FileDelete($report)
$g_preferencesPath = @TempDir & "\teleport_launch_preferences_" & @AutoItPID & ".ini"
$g_wowPidPollSettingsPath = @TempDir & "\teleport_launch_timer_" & @AutoItPID & ".ini"
$teleport_file = @TempDir & "\teleport_launch_fav_" & @AutoItPID & ".fav"
Local $fd = FileOpen($teleport_file, $FO_OVERWRITE + $FO_UTF8_NOBOM)
FileWrite($fd, "主城-甲#1#2#3#0#0" & @CRLF & "主城-乙#4#5#6#0#0" & @CRLF)
FileClose($fd)
Global $playerFixture = DllStructCreate("char[12]")
DllStructSetData($playerFixture, 1, "self")
$PlayerName = DllStructGetPtr($playerFixture)
Local $testPids[2] = [0, @AutoItPID]
$g_wowPidList = $testPids
$g_selectPid = @AutoItPID
$g_singleWowProcess = _MemoryOpen(@AutoItPID)
Global $stepNo = 0, $startTime = TimerInit()
AdlibRegister("LaunchTick", 100)
LaunchUI()
AdlibUnRegister("LaunchTick")
If $stepNo <> 4 Then Fail("main window did not complete the smoke scenario")
If DecodePreference(IniRead($g_preferencesPath, "Search", "Global", "")) <> "乙" Then Fail("search was not persisted on close")
_MemoryClose($g_singleWowProcess)
FileDelete($g_preferencesPath)
FileDelete($teleport_file)
FileWrite($report, "passed")
Exit 0

Func LaunchTick()
    If TimerDiff($startTime) > 15000 Then Fail("timed out waiting for main window")
    Switch $stepNo
        Case 0
            If $g_searchEdit = 0 Or $g_categorySettingsList = 0 Or $g_appearanceApply = 0 Then Return
            If Not IsHWnd($g_mainWindow) Then Return
            GUICtrlSetData($g_searchEdit, "乙")
            $stepNo = 1
        Case 1
            If $g_currentSearch <> "乙" Then Return
            If _GUICtrlListView_GetItemCount($g_listview) <> 1 Then Fail("live search did not filter main list")
            If _GUICtrlListView_GetItemText($g_listview, 0, 0) <> "主城-乙" Then Fail("live search selected wrong row")
            _WinAPI_PostMessage(GUICtrlGetHandle($g_searchEdit), $WM_KEYDOWN, 0x0D, 0)
            _WinAPI_PostMessage(GUICtrlGetHandle($g_searchEdit), $WM_KEYUP, 0x0D, 0)
            $stepNo = 2
        Case 2
            If $g_searchHistory.Count = 0 Then Return
            If $g_searchHistory.Item(0) <> "乙" Then Fail("Enter did not record search history")
            _GUICtrlTab_ActivateTab($g_categoryTab, 2)
            If _GUICtrlTab_GetCurSel($g_categoryTab) <> 2 Then Fail("category settings tab unavailable")
            $stepNo = 3
        Case 3
            $stepNo = 4
            WinClose($g_mainWindow)
    EndSwitch
EndFunc

Func Fail($message)
    FileWrite($report, $message)
    ConsoleWriteError($message & @CRLF)
    Exit 1
EndFunc

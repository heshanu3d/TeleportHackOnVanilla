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
FileDelete($smokeReport)
Local $ui = GUICreate($winTitle, 400, 925, 100, 80)
$g_categoryTab = GUICtrlCreateTab(0, 0, 400, 920)
GUICtrlCreateTabItem("坐标点")
$g_log = GUICtrlCreateEdit("", 10, 735, 380, 175)
Local $categories = InitTeleportList()
$g_categoryComboBox = InitComboBox($categories)
$g_listview = InitListview()
$g_input = GUICtrlCreateInput("", 10, 555, 210, 20)

GUICtrlCreateTabItem("分类导航")
$g_categoryGrid = GUICtrlCreateListView("分类|分类|分类", 10, 40, 380, 865)
For $column = 0 To 2
    _GUICtrlListView_SetColumnWidth($g_categoryGrid, $column, 116)
Next
GUICtrlSetFont($g_categoryGrid, 10, 700, 0, "Microsoft YaHei UI")
_GUICtrlListView_SetExtendedListViewStyle($g_categoryGrid, BitOR($LVS_EX_GRIDLINES, $LVS_EX_FULLROWSELECT))
RefreshCategoryGrid($categories)
GUICtrlCreateTabItem("")
GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
GUISetState(@SW_SHOW)
If EnvGet("TELEPORT_NAV_SCREENSHOT") <> "" Then
    _GUICtrlTab_ActivateTab($g_categoryTab, 1)
    Sleep(100)
    _ScreenCapture_CaptureWnd(EnvGet("TELEPORT_NAV_SCREENSHOT"), $ui)
EndIf

For $i = 0 To 4
    If _GUICtrlListView_GetItemText($g_categoryGrid, $g_categoryGroupRows[$i], 0) = "" Then Fail("missing group header: " & $i)
    If $i > 0 And $g_categoryGroupRows[$i] <= $g_categoryGroupRows[$i - 1] + 1 Then Fail("missing group boundary: " & $i)
Next

CheckClick($ui, "主城", 1)
CheckClick($ui, "副本任务", 2)
CheckClick($ui, "副本60", 0)
CheckClick($ui, "地狱火半岛", 0)
CheckClick($ui, "死亡骑士", 0)
CheckClick($ui, "嚎风峡湾", 1)
CheckClick($ui, "北风苔原", 2)
GUIDelete($ui)
FileWrite($smokeReport, "passed")
ConsoleWrite("category navigation smoke: passed" & @CRLF)
Exit 0

Func CheckClick($ui, $category, $column)
    _GUICtrlTab_ActivateTab($g_categoryTab, 1)
    Local $row = -1
    For $i = 0 To _GUICtrlListView_GetItemCount($g_categoryGrid) - 1
        If _GUICtrlListView_GetItemText($g_categoryGrid, $i, $column) = $category Then
            $row = $i
            ExitLoop
        EndIf
    Next
    If $row < 0 Then Fail("missing grid item: " & $category)

    Local $rect = _GUICtrlListView_GetSubItemRect($g_categoryGrid, $row, $column)
    Local $x = $rect[0] + 30
    Local $y = Int(($rect[1] + $rect[3]) / 2)
    If Not ControlClick($ui, "", GUICtrlGetHandle($g_categoryGrid), "left", 1, $x, $y) Then Fail("click failed: " & $category)

    Local $timer = TimerInit()
    While TimerDiff($timer) < 3000
        GUIGetMsg()
        ApplyPendingCategory()
        If $g_category_selected = $category And GUICtrlRead($g_categoryComboBox) = $category And _GUICtrlTab_GetCurSel($g_categoryTab) = 0 Then Return
        Sleep(10)
    WEnd
    Fail("navigation failed: " & $category & ", selected=" & $g_category_selected & ", combo=" & GUICtrlRead($g_categoryComboBox) & ", tab=" & _GUICtrlTab_GetCurSel($g_categoryTab))
EndFunc

Func Fail($message)
    FileWrite($smokeReport, $message)
    ConsoleWriteError($message & @CRLF)
    Exit 1
EndFunc

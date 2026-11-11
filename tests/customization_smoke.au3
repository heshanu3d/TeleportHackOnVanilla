#NoTrayIcon
#include <ScreenCapture.au3>
Global $version = "1.12.1", $exe = "WoW.exe", $winTitle = "Customization smoke test"
Global $CurrPosX = 0, $CurrPosY = 0, $CurrPosZ = 0
Global $StaticPlayer = 0, $PbPointer1 = 0, $PbPointer2 = 0
Global $PosX = 0, $PosY = 0, $PosZ = 0, $PosR = 0, $MapID = 0
Global $AntiJump = 0, $JumpGravity = 0, $PlayerName = 0, $SpeedGlobal = 0
Global $autoloot_2 = 0, $patch_loot = 0, $patch_loot2 = 0, $patch_lootslot = 0, $luaUnlock = 0
#include "..\include.au3"

Global $report = @TempDir & "\teleport_customization_smoke.txt"
FileDelete($report)
$g_preferencesPath = @TempDir & "\teleport_preferences_test_" & @AutoItPID & ".ini"
$teleport_file = @TempDir & "\teleport_favourites_test_" & @AutoItPID & ".fav"
LoadPreferences()
Local $ui = GUICreate($winTitle, 400, 925)
$g_mainWindow = $ui
$g_categoryTab = GUICtrlCreateTab(0, 0, 400, 920)
GUICtrlCreateTabItem("坐标点")
CreateThemedTabBackground(0)
$g_log = GUICtrlCreateEdit("", 10, 700, 380, 150)
$g_searchEdit = GUICtrlCreateInput("", 10, 35, 160, 22)
$g_searchCombo = GUICtrlCreateCombo("", 180, 35, 160, 22, $CBS_DROPDOWNLIST)
$g_listview = GUICtrlCreateListView("描述|x|y|z|r|map", 10, 63, 380, 400)
$g_recentLabel = GUICtrlCreateLabel("最近", 10, 460, 150, 20)
$g_categoryLabel = GUICtrlCreateLabel("当前", 190, 460, 180, 20)
$g_recentListview = GUICtrlCreateListView("最近|x|y|z", 10, 480, 380, 125)
$g_input = GUICtrlCreateInput("", 10, 610, 225, 22)
$g_pidControl = GUICtrlCreateList("", 250, 610, 60, 50)
$g_playerNameControl = GUICtrlCreateList("", 315, 610, 60, 50)
For $i = 0 To 6
    $g_mainButtons[$i] = GUICtrlCreateButton("button", 10, 670, 60, 22)
Next
$g_onTopControl = GUICtrlCreateCheckbox("OnTop", 10, 700, 75, 20)
GUICtrlCreateTabItem("分类导航")
CreateThemedTabBackground(1)
$g_categoryGrid = GUICtrlCreateListView("分类|分类|分类", 10, 40, 380, 800)
GUICtrlCreateTabItem("分类设置")
CreateThemedTabBackground(2)
CreateCategorySettings()
GUICtrlCreateTabItem("设置")
CreateThemedTabBackground(3)
CreateExtendedSettings()
GUICtrlCreateTabItem("")
GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
GUISetState(@SW_SHOW)

Local $fixture[24] = ["艾尔文森林-甲", "1", "2", "3", "0", "0", _
    "西部荒野-乙", "4", "5", "6", "0", "0", _
    "艾尔文森林-丙", "7", "8", "9", "0", "0", _
    "主城-丁", "10", "11", "12", "0", "0"]
$g_teleList_whole = $fixture
RebuildCategoryData()
If GroupIndexOfCategory("艾尔文森林") <> 1 Then Fail("default category group")
If GroupIndexOfCategory("主城") <> 0 Then Fail("default misc group")
Local $temporaryGroup = AddCategoryGroup("临时分组")
If $temporaryGroup <> 5 Or AddCategoryGroup("临时分组") <> -1 Then Fail("group creation or duplicate validation failed")
Local $temporary = $g_categoryGroups.Item($temporaryGroup), $temporaryItems = $temporary.Item("items")
$temporaryItems.Add("暂时缺失的小类")
If Not RenameCategoryGroup($temporaryGroup, "新分组") Or GroupByName("新分组") <> 5 Then Fail("group rename failed")
If Not MoveCategoryGroup(5, 4) Or GroupByName("新分组") <> 4 Then Fail("group reorder failed")
If Not DeleteCategoryGroup(4) Or GroupIndexOfCategory("暂时缺失的小类") <> 0 Then Fail("group deletion lost absent category")
Local $placeholder[0]
$g_teleListDict.Add("湿地", $placeholder)
Local $oneSelected = ObjCreate("System.Collections.ArrayList")
$oneSelected.Add("湿地")
If Not ReorderSelectedCategories(1, $oneSelected, -1) Then Fail("reorder across missing category failed")
Local $east = $g_categoryGroups.Item(1), $eastItems = $east.Item("items")
If $eastItems.Item(1) <> "湿地" Or $eastItems.Item(2) <> "赤脊山" Then Fail("missing category moved during reorder")
If Not ReorderSelectedCategories(1, $oneSelected, 1) Then Fail("reverse reorder failed")
$g_teleListDict.Remove("湿地")
RefreshCategorySettings(1)
If _GUICtrlListBox_GetCount($g_categorySettingsList) <> 2 Then Fail("visible categories include missing entries")
_GUICtrlListBox_SetSel($g_categorySettingsList, 0, True)
_GUICtrlListBox_SetSel($g_categorySettingsList, 1, True)
Local $selected = SelectedSettingsCategories()
If $selected.Count <> 2 Then Fail("multiple selected categories not captured")
_GUICtrlComboBox_SetCurSel($g_categoryTarget, 0)
If Not HandleCategorySettings($g_categoryMove) Then Fail("batch move action not handled")
If GroupIndexOfCategory("艾尔文森林") <> 0 Or GroupIndexOfCategory("西部荒野") <> 0 Then Fail("batch move lost categories")
If GroupIndexOfCategory("赤脊山") <> 1 Then Fail("missing category assignment lost")
If Not ReorderSelectedCategories(0, $selected, -1) Then Fail("batch reorder failed")
$g_independentSearch = True
SetSearchForCategory("艾尔文森林", "丙")
SetSearchForCategory("主城", "丁")
RememberSearch("搜索 中文")
$g_autoSave = True
$g_rightClickTeleport = True
$g_theme = "dark"
$g_opacity = 85
$g_showColumns[2] = False
If Not SavePreferences() Then Fail("save preferences failed")
ResetCategoryGroups()
$g_searchHistory.Clear()
$g_categorySearches.RemoveAll()
LoadPreferences()
If GroupIndexOfCategory("艾尔文森林") <> 0 Or GroupIndexOfCategory("赤脊山") <> 1 Or GroupIndexOfCategory("暂时缺失的小类") <> 0 Then Fail("saved group membership changed")
If Not $g_independentSearch Or SearchForCategory("艾尔文森林") <> "丙" Or SearchForCategory("主城") <> "丁" Then Fail("independent search did not persist")
If $g_searchHistory.Count <> 1 Or $g_searchHistory.Item(0) <> "搜索 中文" Then Fail("search history did not persist")
RefreshSearchHistoryControls()
GUICtrlSetData($g_historyInput, "第二条")
HandleSearchHistory($g_historyAdd)
If $g_searchHistory.Count <> 2 Or $g_searchHistory.Item(0) <> "第二条" Then Fail("history add failed")
_GUICtrlListBox_SetCurSel($g_searchHistoryList, 0)
GUICtrlSetData($g_historyInput, "修改后")
HandleSearchHistory($g_historyEdit)
If $g_searchHistory.Item(0) <> "修改后" Then Fail("history edit failed")
_GUICtrlListBox_SetCurSel($g_searchHistoryList, 0)
HandleSearchHistory($g_historyDelete)
If $g_searchHistory.Count <> 1 Or $g_searchHistory.Item(0) <> "搜索 中文" Then Fail("history delete failed")
If Not $g_autoSave Or Not $g_rightClickTeleport Or $g_theme <> "dark" Or $g_opacity <> 85 Or $g_showColumns[2] Then Fail("appearance options did not persist")
SelectSearchCategory("主城")
SwitchListviewWithCategory($g_category_selected)
If $g_currentSearch <> "丁" Or _GUICtrlListView_GetItemText($g_listview, 0, 0) <> "主城-丁" Then Fail("independent category search was not restored")
SelectSearchCategory("艾尔文森林")
If $g_currentSearch <> "丙" Then Fail("previous category search was not restored")
$g_category_selected = "艾尔文森林"
$g_currentSearch = "丙"
SwitchListviewWithCategory($g_category_selected)
If _GUICtrlListView_GetItemCount($g_listview) <> 1 Then Fail("search did not filter rows")
If GlobalPositionForVisibleRow(0) <> 2 Then Fail("filtered row mapped to wrong source")
_GUICtrlTab_ActivateTab($g_categoryTab, 0)
$g_rightClickTeleport = False
CheckRightClick($ui, False)
$g_rightClickTeleport = True
CheckRightClick($ui, True)
Local $newPosition[5] = ["71", "81", "91", "0", "0"]
If Not UpdateFavourite("edit", 0, "艾尔文森林-丙", $newPosition) Then Fail("filtered edit failed")
If $g_teleList_whole[1] <> "1" Or $g_teleList_whole[13] <> "71" Then Fail("filtered edit changed wrong point")
Local $saved = FileReadToArray($teleport_file)
If @error Or UBound($saved) <> 4 Or Not StringInStr($saved[2], "#71#81#91#") Then Fail("automatic save lost points")
Local $roundtripCategories = InitTeleportList()
If $g_teleList_whole[0] <> "艾尔文森林-甲" Or $g_teleList_whole[12] <> "艾尔文森林-丙" Then Fail("favourites UTF-8 did not round-trip")
$g_category_selected = "艾尔文森林"
$g_currentSearch = "丙"
SwitchListviewWithCategory($g_category_selected)
$g_autoSave = False
Local $savedBeforeManualChanges = FileRead($teleport_file)
If Not UpdateFavourite("insert", 0, "艾尔文森林-新", $newPosition) Then Fail("filtered insert failed")
If $g_teleList_whole[12] <> "艾尔文森林-新" Or $g_teleList_whole[18] <> "艾尔文森林-丙" Then Fail("filtered insert wrong position")
If Not UpdateFavourite("append", 0, "艾尔文森林-后", $newPosition) Then Fail("filtered append failed")
If $g_teleList_whole[24] <> "艾尔文森林-后" Then Fail("filtered append wrong position")
If Not UpdateFavourite("delete", 0) Then Fail("filtered delete failed")
If $g_teleList_whole[18] <> "艾尔文森林-后" Or $g_teleList_whole[0] <> "艾尔文森林-甲" Then Fail("filtered delete changed wrong point")
If Not UpdateFavourite("add", -1, "主城-新增", $newPosition) Then Fail("append to end failed")
If $g_teleList_whole[UBound($g_teleList_whole) - 6] <> "主城-新增" Then Fail("new point not appended")
If FileRead($teleport_file) <> $savedBeforeManualChanges Then Fail("manual mode unexpectedly saved changes")
$g_windowHeight = 1100
$g_listHeight = 380
$g_buttonWidth = 90
$g_buttonHeight = 24
$g_buttonSpacing = 6
$g_theme = "light"
ApplyAppearance()
If _GUICtrlListView_GetBkColor($g_listview) <> 0xFFFFFF Then Fail("light theme not applied")
$g_theme = "dark"
ApplyAppearance()
If _GUICtrlListView_GetBkColor($g_listview) <> 0x303030 Then Fail("dark theme not applied")
If _GUICtrlListView_GetColumnWidth($g_listview, 3) <> 0 Then Fail("hidden coordinate column remains visible")
Local $alpha = DllCall("user32.dll", "bool", "GetLayeredWindowAttributes", "hwnd", $ui, "dword*", 0, "byte*", 0, "dword*", 0)
If @error Or Not $alpha[0] Or $alpha[3] <> Round(255 * 0.85) Then Fail("window opacity not applied")
If EnvGet("TELEPORT_CUSTOMIZATION_SCREENSHOTS") <> "" Then
    WinSetTrans($ui, "", 255)
    _GUICtrlTab_ActivateTab($g_categoryTab, 2)
    Sleep(100)
    _ScreenCapture_CaptureWnd(EnvGet("TELEPORT_CUSTOMIZATION_SCREENSHOTS") & "\category.png", $ui)
    _GUICtrlTab_ActivateTab($g_categoryTab, 3)
    Sleep(100)
    _ScreenCapture_CaptureWnd(EnvGet("TELEPORT_CUSTOMIZATION_SCREENSHOTS") & "\settings.png", $ui)
    _GUICtrlTab_ActivateTab($g_categoryTab, 0)
    Sleep(100)
    _ScreenCapture_CaptureWnd(EnvGet("TELEPORT_CUSTOMIZATION_SCREENSHOTS") & "\main.png", $ui)
EndIf
Local $empty[0]
$g_teleList_whole = $empty
$g_category_selected = "所有"
$g_currentSearch = ""
RebuildCategoryData()
If Not UpdateFavourite("add", -1, "主城-唯一", $newPosition) Then Fail("adding to empty favourites failed")
If UBound($g_teleList_whole) <> 6 Then Fail("empty favourites append lost values")
If Not UpdateFavourite("delete", 0) Or UBound($g_teleList_whole) <> 0 Then Fail("deleting final favourite failed")
FileDelete($g_preferencesPath)
FileDelete($teleport_file)
GUIDelete($ui)
FileWrite($report, "passed")
Exit 0

Func CheckRightClick($ui, $enabled)
    $g_pendingRightClick = -1
    Local $rect = _GUICtrlListView_GetItemRect($g_listview, 0)
    If Not ControlClick($ui, "", GUICtrlGetHandle($g_listview), "right", 1, 20, Int(($rect[1] + $rect[3]) / 2)) Then Fail("right click failed")
    Local $timer = TimerInit()
    While TimerDiff($timer) < 200
        GUIGetMsg()
        Sleep(10)
    WEnd
    If $enabled And $g_pendingRightClick <> 0 Then Fail("enabled right click did not target the clicked row")
    If Not $enabled And $g_pendingRightClick <> -1 Then Fail("disabled right click queued a teleport")
    $g_pendingRightClick = -1
EndFunc

Func Fail($message)
    FileWrite($report, $message)
    ConsoleWriteError($message & @CRLF)
    Exit 1
EndFunc

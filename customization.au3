#include-once

; These settings are independent of teleport_ui.ini and of the favourites file.
Global $g_preferencesPath = @ScriptDir & "\teleport_preferences.ini"
Global $g_categoryGroups = ObjCreate("System.Collections.ArrayList")
Global $g_searchHistory = ObjCreate("System.Collections.ArrayList")
Global $g_categorySearches = ObjCreate("Scripting.Dictionary")
Global $g_independentSearch = False, $g_globalSearch = ""
Global $g_autoSave = False, $g_rightClickTeleport = False
Global $g_theme = "light", $g_opacity = 100, $g_windowHeight = 925, $g_listHeight = 400
Global $g_buttonWidth = 85, $g_buttonHeight = 22, $g_buttonSpacing = 5
Global $g_showColumns[5] = [True, True, True, True, True]
Global $g_preferencesLoaded = False, $g_settingsDirty = False, $g_settingsTimer = 0
Global $g_searchEdit = 0, $g_searchCombo = 0, $g_searchHistoryList = 0
Global $g_searchEnter = 0
Global $g_categorySettingsGroup = 0, $g_categorySettingsList = 0, $g_categoryTarget = 0
Global $g_pendingRightClick = -1

Func EncodePreference($text)
    Return String(StringToBinary(String($text), 4))
EndFunc

Func DecodePreference($text)
    If Not StringRegExp($text, "^0x(?:[0-9A-Fa-f]{2})*$") Then Return ""
    Return BinaryToString(Binary($text), 4)
EndFunc

Func NewCategoryGroup($name)
    Local $group = ObjCreate("Scripting.Dictionary")
    $group.Add("name", $name)
    $group.Add("items", ObjCreate("System.Collections.ArrayList"))
    Return $group
EndFunc

Func ResetCategoryGroups()
    $g_categoryGroups.Clear()
    Local $names[5] = ["杂项", "东部王国", "卡利姆多", "燃烧的远征", "巫妖王之怒"]
    For $i = 0 To 4
        Local $group = NewCategoryGroup($names[$i])
        If $i > 0 Then
            Local $order = CategoryGridOrder($i)
            Local $items = $group.Item("items")
            For $j = 0 To UBound($order) - 1
                $items.Add($order[$j])
            Next
        EndIf
        $g_categoryGroups.Add($group)
    Next
EndFunc

Func GroupIndexOfCategory($name)
    For $i = 0 To $g_categoryGroups.Count - 1
        Local $group = $g_categoryGroups.Item($i), $items = $group.Item("items")
        If $items.Contains($name) Then Return $i
    Next
    Return -1
EndFunc

Func EnsureCategoryAssignments(ByRef $categories)
    If $g_categoryGroups.Count = 0 Then ResetCategoryGroups()
    For $i = 0 To UBound($categories) - 1
        Local $name = $categories[$i]
        If $name = "" Or $name = "所有" Or GroupIndexOfCategory($name) >= 0 Then ContinueLoop
        ; New categories go to their known default group, or the first group.
        Local $default = CategoryGridGroup($name), $target = 0
        Local $defaultNames[5] = ["杂项", "东部王国", "卡利姆多", "燃烧的远征", "巫妖王之怒"]
        For $j = 0 To $g_categoryGroups.Count - 1
            Local $candidate = $g_categoryGroups.Item($j)
            If $candidate.Item("name") = $defaultNames[$default] Then
                $target = $j
                ExitLoop
            EndIf
        Next
        Local $group = $g_categoryGroups.Item($target), $items = $group.Item("items")
        $items.Add($name)
        $g_settingsDirty = True
    Next
EndFunc

Func PreferenceInt($section, $key, $fallback, $min, $max)
    Local $value = IniRead($g_preferencesPath, $section, $key, String($fallback))
    If Not StringIsInt($value) Then Return $fallback
    Return _Min($max, _Max($min, Number($value)))
EndFunc

Func LoadPreferences()
    $g_categoryGroups.Clear()
    Local $groupCount = PreferenceInt("Groups", "Count", 0, 0, 100)
    For $i = 0 To $groupCount - 1
        Local $groupName = DecodePreference(IniRead($g_preferencesPath, "Groups", "Name" & $i, ""))
        If $groupName = "" Then ContinueLoop
        Local $group = NewCategoryGroup($groupName), $items = $group.Item("items")
        Local $count = PreferenceInt("Groups", "Count" & $i, 0, 0, 10000)
        For $j = 0 To $count - 1
            Local $item = DecodePreference(IniRead($g_preferencesPath, "Groups", "Item" & $i & "_" & $j, ""))
            If $item <> "" And $item <> "所有" And GroupIndexOfCategory($item) < 0 And Not $items.Contains($item) Then $items.Add($item)
        Next
        $g_categoryGroups.Add($group)
    Next
    If $g_categoryGroups.Count = 0 Then ResetCategoryGroups()
    $g_searchHistory.Clear()
    Local $historyCount = PreferenceInt("History", "Count", 0, 0, 10000)
    For $i = 0 To $historyCount - 1
        Local $entry = DecodePreference(IniRead($g_preferencesPath, "History", "Item" & $i, ""))
        If $entry <> "" And Not $g_searchHistory.Contains($entry) Then $g_searchHistory.Add($entry)
    Next
    $g_categorySearches.RemoveAll()
    Local $searchCount = PreferenceInt("Search", "Count", 0, 0, 10000)
    For $i = 0 To $searchCount - 1
        Local $key = DecodePreference(IniRead($g_preferencesPath, "Search", "Key" & $i, ""))
        Local $value = DecodePreference(IniRead($g_preferencesPath, "Search", "Value" & $i, ""))
        If $key <> "" And Not $g_categorySearches.Exists($key) Then $g_categorySearches.Add($key, $value)
    Next
    $g_globalSearch = DecodePreference(IniRead($g_preferencesPath, "Search", "Global", "0x"))
    $g_independentSearch = PreferenceInt("Options", "IndependentSearch", 0, 0, 1) = 1
    $g_autoSave = PreferenceInt("Options", "AutoSave", 0, 0, 1) = 1
    $g_rightClickTeleport = PreferenceInt("Options", "RightClickTeleport", 0, 0, 1) = 1
    $g_theme = IniRead($g_preferencesPath, "Appearance", "Theme", "light")
    If $g_theme <> "dark" Then $g_theme = "light"
    $g_opacity = PreferenceInt("Appearance", "Opacity", 100, 30, 100)
    $g_windowHeight = PreferenceInt("Appearance", "WindowHeight", 925, 700, 1600)
    $g_listHeight = PreferenceInt("Appearance", "ListHeight", 400, 120, 900)
    $g_buttonWidth = PreferenceInt("Appearance", "ButtonWidth", 85, 55, 180)
    $g_buttonHeight = PreferenceInt("Appearance", "ButtonHeight", 22, 20, 60)
    $g_buttonSpacing = PreferenceInt("Appearance", "ButtonSpacing", 5, 0, 20)
    For $i = 0 To 4
        $g_showColumns[$i] = PreferenceInt("Columns", "Show" & $i, 1, 0, 1) = 1
    Next
    $g_preferencesLoaded = True
    $g_settingsDirty = False
EndFunc

Func SavePreferences()
    If Not $g_preferencesLoaded Then Return True
    Local $tmp = $g_preferencesPath & ".tmp." & @AutoItPID
    Local $fd = FileOpen($tmp, $FO_OVERWRITE + $FO_UTF16_LE + $FO_CREATEPATH)
    If $fd = -1 Then
        print("Failed to open preferences for writing")
        Return False
    EndIf
    Local $body = "[Groups]" & @CRLF & "Count=" & $g_categoryGroups.Count & @CRLF
    For $i = 0 To $g_categoryGroups.Count - 1
        Local $group = $g_categoryGroups.Item($i), $items = $group.Item("items")
        $body &= "Name" & $i & "=" & EncodePreference($group.Item("name")) & @CRLF
        $body &= "Count" & $i & "=" & $items.Count & @CRLF
        For $j = 0 To $items.Count - 1
            $body &= "Item" & $i & "_" & $j & "=" & EncodePreference($items.Item($j)) & @CRLF
        Next
    Next
    $body &= "[History]" & @CRLF & "Count=" & $g_searchHistory.Count & @CRLF
    For $i = 0 To $g_searchHistory.Count - 1
        $body &= "Item" & $i & "=" & EncodePreference($g_searchHistory.Item($i)) & @CRLF
    Next
    $body &= "[Search]" & @CRLF & "Global=" & EncodePreference($g_globalSearch) & @CRLF & "Count=" & $g_categorySearches.Count & @CRLF
    Local $keys = $g_categorySearches.Keys
    For $i = 0 To $g_categorySearches.Count - 1
        $body &= "Key" & $i & "=" & EncodePreference($keys[$i]) & @CRLF & "Value" & $i & "=" & EncodePreference($g_categorySearches.Item($keys[$i])) & @CRLF
    Next
    $body &= "[Options]" & @CRLF & "IndependentSearch=" & Int($g_independentSearch) & @CRLF & "AutoSave=" & Int($g_autoSave) & @CRLF & "RightClickTeleport=" & Int($g_rightClickTeleport) & @CRLF
    $body &= "[Appearance]" & @CRLF & "Theme=" & $g_theme & @CRLF & "Opacity=" & $g_opacity & @CRLF & "WindowHeight=" & $g_windowHeight & @CRLF & "ListHeight=" & $g_listHeight & @CRLF & "ButtonWidth=" & $g_buttonWidth & @CRLF & "ButtonHeight=" & $g_buttonHeight & @CRLF & "ButtonSpacing=" & $g_buttonSpacing & @CRLF
    $body &= "[Columns]" & @CRLF
    For $i = 0 To 4
        $body &= "Show" & $i & "=" & Int($g_showColumns[$i]) & @CRLF
    Next
    Local $ok = FileWrite($fd, $body)
    FileClose($fd)
    If Not $ok Or Not FileMove($tmp, $g_preferencesPath, $FC_OVERWRITE) Then
        print("Failed to save preferences: " & $g_preferencesPath)
        Return False
    EndIf
    $g_settingsDirty = False
    Return True
EndFunc

Func SearchForCategory($category)
    If Not $g_independentSearch Then Return $g_globalSearch
    If $g_categorySearches.Exists($category) Then Return $g_categorySearches.Item($category)
    Return ""
EndFunc

Func SetSearchForCategory($category, $text)
    If $g_independentSearch Then
        If $g_categorySearches.Exists($category) Then
            If $text = "" Then
                $g_categorySearches.Remove($category)
            Else
                $g_categorySearches.Item($category) = $text
            EndIf
        ElseIf $text <> "" Then
            $g_categorySearches.Add($category, $text)
        EndIf
    Else
        $g_globalSearch = $text
    EndIf
    $g_currentSearch = $text
    $g_settingsDirty = True
    $g_settingsTimer = TimerInit()
EndFunc

Func ListIndexOf($list, $value)
    For $i = 0 To $list.Count - 1
        If $list.Item($i) = $value Then Return $i
    Next
    Return -1
EndFunc

Func RememberSearch($text)
    If StringStripWS($text, 3) = "" Or StringRegExp($text, "[\x00-\x1f\x7f]") Then Return False
    Local $index = ListIndexOf($g_searchHistory, $text)
    If $index >= 0 Then $g_searchHistory.RemoveAt($index)
    $g_searchHistory.Insert(0, $text)
    $g_settingsDirty = True
    Return True
EndFunc

Global $g_groupAdd = 0, $g_groupRename = 0, $g_groupDelete = 0, $g_groupUp = 0, $g_groupDown = 0
Global $g_categoryMove = 0, $g_categoryUp = 0, $g_categoryDown = 0
Global $g_historyInput = 0, $g_historyAdd = 0, $g_historyEdit = 0, $g_historyDelete = 0

Func ValidGroupName($name)
    If StringStripWS($name, 3) = "" Or StringRegExp($name, "[|\r\n]") Then Return False
    For $i = 0 To $g_categoryGroups.Count - 1
        Local $group = $g_categoryGroups.Item($i)
        If $group.Item("name") = $name Then Return False
    Next
    Return True
EndFunc

Func GroupByName($name)
    For $i = 0 To $g_categoryGroups.Count - 1
        Local $group = $g_categoryGroups.Item($i)
        If $group.Item("name") = $name Then Return $i
    Next
    Return -1
EndFunc

Func AddCategoryGroup($name)
    If Not ValidGroupName($name) Then Return -1
    $g_categoryGroups.Add(NewCategoryGroup($name))
    Return $g_categoryGroups.Count - 1
EndFunc

Func RenameCategoryGroup($index, $name)
    If $index < 0 Or $index >= $g_categoryGroups.Count Or Not ValidGroupName($name) Then Return False
    Local $group = $g_categoryGroups.Item($index)
    $group.Item("name") = $name
    Return True
EndFunc

Func DeleteCategoryGroup($index)
    If $g_categoryGroups.Count <= 1 Or $index < 0 Or $index >= $g_categoryGroups.Count Then Return False
    Local $group = $g_categoryGroups.Item($index), $items = $group.Item("items")
    $g_categoryGroups.RemoveAt($index)
    Local $first = $g_categoryGroups.Item(0), $destination = $first.Item("items")
    For $i = 0 To $items.Count - 1
        $destination.Add($items.Item($i))
    Next
    Return True
EndFunc

Func MoveCategoryGroup($index, $other)
    If $index < 0 Or $other < 0 Or $index >= $g_categoryGroups.Count Or $other >= $g_categoryGroups.Count Or $index = $other Then Return False
    Local $group = $g_categoryGroups.Item($index)
    $g_categoryGroups.RemoveAt($index)
    $g_categoryGroups.Insert($other, $group)
    Return True
EndFunc

Func SelectedSettingsCategories()
    Local $result = ObjCreate("System.Collections.ArrayList")
    If $g_categorySettingsList = 0 Then Return $result
    Local $selected = _GUICtrlListBox_GetSelItems($g_categorySettingsList)
    If Not IsArray($selected) Then Return $result
    For $i = 1 To $selected[0]
        $result.Add(_GUICtrlListBox_GetText($g_categorySettingsList, $selected[$i]))
    Next
    Return $result
EndFunc

Func RefreshCategorySettings($groupIndex = 0, $selected = 0)
    If $g_categorySettingsGroup = 0 Then Return
    If $groupIndex < 0 Or $groupIndex >= $g_categoryGroups.Count Then $groupIndex = 0
    _GUICtrlListBox_ResetContent($g_categorySettingsGroup)
    GUICtrlSetData($g_categoryTarget, "|")
    For $i = 0 To $g_categoryGroups.Count - 1
        Local $group = $g_categoryGroups.Item($i)
        _GUICtrlListBox_AddString($g_categorySettingsGroup, $group.Item("name"))
        GUICtrlSetData($g_categoryTarget, $group.Item("name"))
    Next
    _GUICtrlListBox_SetCurSel($g_categorySettingsGroup, $groupIndex)
    Local $group = $g_categoryGroups.Item($groupIndex), $items = $group.Item("items")
    _GUICtrlListBox_ResetContent($g_categorySettingsList)
    For $i = 0 To $items.Count - 1
        Local $name = $items.Item($i)
        If Not $g_teleListDict.Exists($name) Then ContinueLoop
        Local $idx = _GUICtrlListBox_AddString($g_categorySettingsList, $name)
        If IsObj($selected) And $selected.Contains($name) Then _GUICtrlListBox_SetSel($g_categorySettingsList, $idx, True)
    Next
EndFunc

Func MoveSelectedCategories($sourceIndex, $targetIndex, $selected)
    If $sourceIndex < 0 Or $targetIndex < 0 Or $sourceIndex = $targetIndex Or $selected.Count = 0 Then Return False
    If $sourceIndex >= $g_categoryGroups.Count Or $targetIndex >= $g_categoryGroups.Count Then Return False
    Local $source = $g_categoryGroups.Item($sourceIndex), $target = $g_categoryGroups.Item($targetIndex)
    Local $from = $source.Item("items"), $to = $target.Item("items"), $moving = ObjCreate("System.Collections.ArrayList")
    For $i = 0 To $from.Count - 1
        If $selected.Contains($from.Item($i)) Then $moving.Add($from.Item($i))
    Next
    If $moving.Count <> $selected.Count Then Return False
    For $i = 0 To $moving.Count - 1
        $from.Remove($moving.Item($i))
        $to.Add($moving.Item($i))
    Next
    Return True
EndFunc

Func ReorderSelectedCategories($groupIndex, $selected, $direction)
    If $groupIndex < 0 Or $groupIndex >= $g_categoryGroups.Count Or $selected.Count = 0 Then Return False
    Local $group = $g_categoryGroups.Item($groupIndex), $items = $group.Item("items"), $changed = False
    If $direction = -1 Then
        For $i = 1 To $items.Count - 1
            If Not $selected.Contains($items.Item($i)) Then ContinueLoop
            Local $neighbor = $i - 1
            While $neighbor >= 0 And Not $g_teleListDict.Exists($items.Item($neighbor))
                $neighbor -= 1
            WEnd
            If $neighbor < 0 Or $selected.Contains($items.Item($neighbor)) Then ContinueLoop
            Local $tmp = $items.Item($neighbor)
            $items.Item($neighbor) = $items.Item($i)
            $items.Item($i) = $tmp
            $changed = True
        Next
    ElseIf $direction = 1 Then
        For $i = $items.Count - 2 To 0 Step -1
            If Not $selected.Contains($items.Item($i)) Then ContinueLoop
            Local $neighbor = $i + 1
            While $neighbor < $items.Count And Not $g_teleListDict.Exists($items.Item($neighbor))
                $neighbor += 1
            WEnd
            If $neighbor >= $items.Count Or $selected.Contains($items.Item($neighbor)) Then ContinueLoop
            Local $tmp = $items.Item($neighbor)
            $items.Item($neighbor) = $items.Item($i)
            $items.Item($i) = $tmp
            $changed = True
        Next
    EndIf
    Return $changed
EndFunc

Func CreateCategorySettings()
    GUICtrlCreateLabel("大类", 12, 45, 100, 20)
    $g_categorySettingsGroup = GUICtrlCreateList("", 12, 68, 170, 160, $LBS_NOTIFY + $WS_VSCROLL)
    $g_groupAdd = GUICtrlCreateButton("新增大类", 195, 68, 85, 25)
    $g_groupRename = GUICtrlCreateButton("重命名", 288, 68, 85, 25)
    $g_groupDelete = GUICtrlCreateButton("删除大类", 195, 102, 85, 25)
    $g_groupUp = GUICtrlCreateButton("大类上移", 195, 136, 85, 25)
    $g_groupDown = GUICtrlCreateButton("大类下移", 288, 136, 85, 25)
    GUICtrlCreateLabel("小类（Ctrl / Shift 多选）", 12, 246, 245, 20)
    $g_categorySettingsList = GUICtrlCreateList("", 12, 270, 170, 350, BitOR($LBS_NOTIFY, $LBS_EXTENDEDSEL, $WS_VSCROLL))
    GUICtrlCreateLabel("移动到", 195, 272, 100, 20)
    $g_categoryTarget = GUICtrlCreateCombo("", 195, 295, 175, 25, $CBS_DROPDOWNLIST)
    $g_categoryMove = GUICtrlCreateButton("批量移动", 195, 330, 85, 25)
    $g_categoryUp = GUICtrlCreateButton("小类上移", 195, 370, 85, 25)
    $g_categoryDown = GUICtrlCreateButton("小类下移", 288, 370, 85, 25)
    RefreshCategorySettings()
EndFunc

Func HandleCategorySettings($message)
    If $message = $g_categorySettingsGroup Then
        RefreshCategorySettings(_GUICtrlListBox_GetCurSel($g_categorySettingsGroup))
        Return True
    EndIf
    If $message <> $g_groupAdd And $message <> $g_groupRename And $message <> $g_groupDelete And $message <> $g_groupUp And $message <> $g_groupDown And $message <> $g_categoryMove And $message <> $g_categoryUp And $message <> $g_categoryDown Then Return False
    Local $index = _GUICtrlListBox_GetCurSel($g_categorySettingsGroup), $changed = False
    If $index < 0 Then Return True
    Local $group = $g_categoryGroups.Item($index), $selected = SelectedSettingsCategories()
    Switch $message
        Case $g_groupAdd, $g_groupRename
            Local $default = ""
            If $message = $g_groupRename Then $default = $group.Item("name")
            Local $name = InputBox("分类设置", "请输入大类名称", $default)
            If @error Then Return True
            $name = StringStripWS($name, 3)
            If $name = $default And $message = $g_groupRename Then Return True
            If Not ValidGroupName($name) Then
                MsgBox(48, "分类设置", "名称不能为空、重复或包含竖线。")
                Return True
            EndIf
            If $message = $g_groupAdd Then
                $index = AddCategoryGroup($name)
                $changed = $index >= 0
            Else
                $changed = RenameCategoryGroup($index, $name)
            EndIf
        Case $g_groupDelete
            If $g_categoryGroups.Count <= 1 Then Return True
            If MsgBox(36, "分类设置", "删除大类并将其小类移至第一个剩余大类？") <> 6 Then Return True
            $changed = DeleteCategoryGroup($index)
            $index = 0
        Case $g_groupUp, $g_groupDown
            Local $other = $index - 1
            If $message = $g_groupDown Then $other = $index + 1
            If $other >= 0 And $other < $g_categoryGroups.Count Then
                $changed = MoveCategoryGroup($index, $other)
                $index = $other
            EndIf
        Case $g_categoryMove
            $changed = MoveSelectedCategories($index, GroupByName(GUICtrlRead($g_categoryTarget)), $selected)
        Case $g_categoryUp
            $changed = ReorderSelectedCategories($index, $selected, -1)
        Case $g_categoryDown
            $changed = ReorderSelectedCategories($index, $selected, 1)
    EndSwitch
    If $changed Then
        $g_settingsDirty = True
        SavePreferences()
        Local $categories = GetAllCategoryNames()
        RefreshCategoryGrid($categories)
        RefreshCategorySettings($index, $selected)
    EndIf
    Return True
EndFunc

Global $g_searchFocused = False, $g_searchEdited = False
Global $g_independentCheck = 0, $g_autoSaveCheck = 0, $g_rightClickCheck = 0
Global $g_themeCombo = 0, $g_opacityInput = 0, $g_windowHeightInput = 0, $g_listHeightInput = 0
Global $g_buttonWidthInput = 0, $g_buttonHeightInput = 0, $g_buttonSpacingInput = 0, $g_appearanceApply = 0
Global $g_columnChecks[5]

Func RefreshSearchHistoryControls()
    If $g_searchCombo <> 0 Then
        _GUICtrlComboBox_ResetContent($g_searchCombo)
        For $i = 0 To $g_searchHistory.Count - 1
            _GUICtrlComboBox_AddString($g_searchCombo, $g_searchHistory.Item($i))
        Next
    EndIf
    If $g_searchHistoryList <> 0 Then
        _GUICtrlListBox_ResetContent($g_searchHistoryList)
        For $i = 0 To $g_searchHistory.Count - 1
            _GUICtrlListBox_AddString($g_searchHistoryList, $g_searchHistory.Item($i))
        Next
    EndIf
EndFunc

Func FinishSearchEdit()
    If Not $g_searchEdited Then Return
    $g_searchEdited = False
    RememberSearch($g_currentSearch)
    RefreshSearchHistoryControls()
    SavePreferences()
EndFunc

Func SelectSearchCategory($category)
    FinishSearchEdit()
    $g_category_selected = $category
    $g_currentSearch = SearchForCategory($category)
    If $g_searchEdit <> 0 Then GUICtrlSetData($g_searchEdit, $g_currentSearch)
EndFunc

Func PollSearchInput()
    If $g_searchEdit = 0 Then Return
    Local $text = GUICtrlRead($g_searchEdit)
    If $text <> $g_currentSearch Then
        SetSearchForCategory($g_category_selected, $text)
        $g_searchEdited = True
        SwitchListviewWithCategory($g_category_selected)
    EndIf
    Local $focused = _WinAPI_GetFocus() = GUICtrlGetHandle($g_searchEdit)
    If $g_searchFocused And Not $focused Then FinishSearchEdit()
    $g_searchFocused = $focused
    If $g_settingsDirty And $g_settingsTimer <> 0 And TimerDiff($g_settingsTimer) >= 700 Then
        SavePreferences()
        $g_settingsTimer = 0
    EndIf
EndFunc

Func HandleSearchHistory($message)
    If $message = $g_searchCombo And $g_searchCombo <> 0 Then
        Local $selected = GUICtrlRead($g_searchCombo)
        If $selected <> "" Then
            FinishSearchEdit()
            SetSearchForCategory($g_category_selected, $selected)
            GUICtrlSetData($g_searchEdit, $selected)
            RememberSearch($selected)
            RefreshSearchHistoryControls()
            SwitchListviewWithCategory($g_category_selected)
            SavePreferences()
        EndIf
        Return True
    EndIf
    If $message = $g_searchHistoryList And $g_searchHistoryList <> 0 Then
        Local $idx = _GUICtrlListBox_GetCurSel($g_searchHistoryList)
        If $idx >= 0 Then GUICtrlSetData($g_historyInput, $g_searchHistory.Item($idx))
        Return True
    EndIf
    If $message <> $g_historyAdd And $message <> $g_historyEdit And $message <> $g_historyDelete Then Return False
    Local $idx = _GUICtrlListBox_GetCurSel($g_searchHistoryList), $text = GUICtrlRead($g_historyInput)
    Switch $message
        Case $g_historyAdd
            If Not RememberSearch($text) Then Return True
        Case $g_historyEdit
            If $idx < 0 Or StringStripWS($text, 3) = "" Or StringRegExp($text, "[\x00-\x1f\x7f]") Then Return True
            Local $existing = ListIndexOf($g_searchHistory, $text)
            If $existing >= 0 And $existing <> $idx Then Return True
            $g_searchHistory.Item($idx) = $text
        Case $g_historyDelete
            If $idx < 0 Then Return True
            $g_searchHistory.RemoveAt($idx)
    EndSwitch
    RefreshSearchHistoryControls()
    SavePreferences()
    Return True
EndFunc

Func CheckboxValue($control)
    Return BitAND(GUICtrlRead($control), $GUI_CHECKED) = $GUI_CHECKED
EndFunc

Func SetCheckboxValue($control, $value)
    If $value Then
        GUICtrlSetState($control, $GUI_CHECKED)
    Else
        GUICtrlSetState($control, $GUI_UNCHECKED)
    EndIf
EndFunc

Func CreateExtendedSettings()
    GUICtrlCreateLabel("搜索历史管理", 12, 305, 180, 20)
    $g_historyInput = GUICtrlCreateInput("", 12, 328, 176, 22)
    $g_historyAdd = GUICtrlCreateButton("新增", 195, 326, 55, 25)
    $g_historyEdit = GUICtrlCreateButton("编辑", 255, 326, 55, 25)
    $g_historyDelete = GUICtrlCreateButton("删除", 315, 326, 55, 25)
    $g_searchHistoryList = GUICtrlCreateList("", 12, 355, 360, 80, $LBS_NOTIFY + $WS_VSCROLL)
    $g_independentCheck = GUICtrlCreateCheckbox("独立搜索", 12, 445, 95, 22)
    $g_autoSaveCheck = GUICtrlCreateCheckbox("及时保存", 118, 445, 95, 22)
    $g_rightClickCheck = GUICtrlCreateCheckbox("右键传送", 224, 445, 95, 22)
    SetCheckboxValue($g_independentCheck, $g_independentSearch)
    SetCheckboxValue($g_autoSaveCheck, $g_autoSave)
    SetCheckboxValue($g_rightClickCheck, $g_rightClickTeleport)
    GUICtrlCreateLabel("主题", 12, 485, 50, 20)
    $g_themeCombo = GUICtrlCreateCombo("", 55, 480, 100, 25, $CBS_DROPDOWNLIST)
    GUICtrlSetData($g_themeCombo, "亮色|暗黑", "亮色")
    If $g_theme = "dark" Then GUICtrlSetData($g_themeCombo, "暗黑")
    GUICtrlCreateLabel("不透明度%", 175, 485, 85, 20)
    $g_opacityInput = GUICtrlCreateInput($g_opacity, 265, 480, 60, 22, $ES_NUMBER)
    GUICtrlCreateLabel("窗口高度", 12, 520, 80, 20)
    $g_windowHeightInput = GUICtrlCreateInput($g_windowHeight, 92, 515, 65, 22, $ES_NUMBER)
    GUICtrlCreateLabel("列表高度", 175, 520, 80, 20)
    $g_listHeightInput = GUICtrlCreateInput($g_listHeight, 265, 515, 60, 22, $ES_NUMBER)
    GUICtrlCreateLabel("按钮宽 / 高 / 间隔", 12, 555, 130, 20)
    $g_buttonWidthInput = GUICtrlCreateInput($g_buttonWidth, 145, 550, 50, 22, $ES_NUMBER)
    $g_buttonHeightInput = GUICtrlCreateInput($g_buttonHeight, 202, 550, 50, 22, $ES_NUMBER)
    $g_buttonSpacingInput = GUICtrlCreateInput($g_buttonSpacing, 259, 550, 50, 22, $ES_NUMBER)
    GUICtrlCreateLabel("显示坐标列", 12, 590, 90, 20)
    Local $names[5] = ["x", "y", "z", "r", "map"]
    For $i = 0 To 4
        $g_columnChecks[$i] = GUICtrlCreateCheckbox($names[$i], 105 + $i * 50, 585, 48, 22)
        SetCheckboxValue($g_columnChecks[$i], $g_showColumns[$i])
    Next
    $g_appearanceApply = GUICtrlCreateButton("应用界面设置", 12, 620, 120, 27)
    RefreshSearchHistoryControls()
EndFunc

Func HandleExtendedSettings($message)
    Switch $message
        Case $g_independentCheck
            FinishSearchEdit()
            $g_independentSearch = CheckboxValue($g_independentCheck)
            $g_currentSearch = SearchForCategory($g_category_selected)
            GUICtrlSetData($g_searchEdit, $g_currentSearch)
            SwitchListviewWithCategory($g_category_selected)
            SavePreferences()
            Return True
        Case $g_autoSaveCheck
            $g_autoSave = CheckboxValue($g_autoSaveCheck)
            SavePreferences()
            Return True
        Case $g_rightClickCheck
            $g_rightClickTeleport = CheckboxValue($g_rightClickCheck)
            SavePreferences()
            Return True
        Case $g_appearanceApply
            $g_theme = "light"
            If GUICtrlRead($g_themeCombo) = "暗黑" Then $g_theme = "dark"
            $g_opacity = _Min(100, _Max(30, Number(GUICtrlRead($g_opacityInput))))
            $g_windowHeight = _Min(1600, _Max(700, Number(GUICtrlRead($g_windowHeightInput))))
            $g_listHeight = _Min(900, _Max(120, Number(GUICtrlRead($g_listHeightInput))))
            $g_buttonWidth = _Min(180, _Max(55, Number(GUICtrlRead($g_buttonWidthInput))))
            $g_buttonHeight = _Min(60, _Max(20, Number(GUICtrlRead($g_buttonHeightInput))))
            $g_buttonSpacing = _Min(20, _Max(0, Number(GUICtrlRead($g_buttonSpacingInput))))
            For $i = 0 To 4
                $g_showColumns[$i] = CheckboxValue($g_columnChecks[$i])
            Next
            ApplyAppearance()
            SavePreferences()
            Return True
    EndSwitch
    Return False
EndFunc

Global $g_mainWindow = 0, $g_recentLabel = 0, $g_pidControl = 0, $g_playerNameControl = 0
Global $g_mainButtons[7], $g_onTopControl = 0
Global $g_pageBackgrounds[5]

Func CreateThemedTabBackground($index)
    $g_pageBackgrounds[$index] = GUICtrlCreateLabel("", 2, 26, 395, 1400)
EndFunc

Func ApplyAppearance()
    If $g_mainWindow = 0 Then Return
    Local $buttonColumns = Int((380 + $g_buttonSpacing) / ($g_buttonWidth + $g_buttonSpacing))
    If $buttonColumns < 1 Then $buttonColumns = 1
    If $buttonColumns > 4 Then $buttonColumns = 4
    Local $buttonRows = Int((7 + $buttonColumns - 1) / $buttonColumns)
    Local $recentLabelY = 63 + $g_listHeight + 5
    Local $recentY = $recentLabelY + 20, $inputY = $recentY + 132
    Local $buttonsY = $inputY + 55
    Local $onTopY = $buttonsY + $buttonRows * ($g_buttonHeight + $g_buttonSpacing)
    Local $logY = $onTopY + 26
    Local $minimumHeight = $logY + 180
    If $g_windowHeight < $minimumHeight Then $g_windowHeight = $minimumHeight
    If $g_windowHeight < 730 Then $g_windowHeight = 730
    WinMove($g_mainWindow, "", Default, Default, Default, $g_windowHeight)
    Local $client = WinGetClientSize($g_mainWindow)
    Local $clientHeight = $g_windowHeight - 40
    If IsArray($client) Then $clientHeight = $client[1]
    GUICtrlSetPos($g_categoryTab, 0, 0, 400, $clientHeight - 4)
    GUICtrlSetPos($g_listview, 10, 63, 380, $g_listHeight)
    GUICtrlSetPos($g_recentLabel, 10, $recentLabelY, 180, 20)
    GUICtrlSetPos($g_categoryLabel, 190, $recentLabelY, 200, 20)
    GUICtrlSetPos($g_recentListview, 10, $recentY, 380, 125)
    GUICtrlSetPos($g_input, 10, $inputY, 225, 22)
    GUICtrlSetPos($g_pidControl, 250, $inputY, 60, 50)
    GUICtrlSetPos($g_playerNameControl, 315, $inputY, 60, 50)
    For $i = 0 To 6
        Local $x = 10 + Mod($i, $buttonColumns) * ($g_buttonWidth + $g_buttonSpacing)
        Local $y = $buttonsY + Int($i / $buttonColumns) * ($g_buttonHeight + $g_buttonSpacing)
        GUICtrlSetPos($g_mainButtons[$i], $x, $y, $g_buttonWidth, $g_buttonHeight)
    Next
    GUICtrlSetPos($g_onTopControl, 10, $onTopY, 75, 20)
    GUICtrlSetPos($g_log, 10, $logY, 380, _Max(100, $clientHeight - $logY - 12))
    GUICtrlSetPos($g_categoryGrid, 10, 40, 380, _Max(200, $clientHeight - 55))
    Local $widths[5] = [58, 58, 52, 37, 55]
    For $i = 0 To 4
        Local $width = 0
        If $g_showColumns[$i] Then $width = $widths[$i]
        _GUICtrlListView_SetColumnWidth($g_listview, $i + 1, $width)
    Next
    WinSetTrans($g_mainWindow, "", Round(255 * $g_opacity / 100))
    Local $background = 0xF1F1F1, $surface = 0xFFFFFF, $text = 0x202020
    If $g_theme = "dark" Then
        $background = 0x252525
        $surface = 0x303030
        $text = 0xF0F0F0
    EndIf
    GUISetBkColor($background, $g_mainWindow)
    GUISwitch($g_mainWindow)
    For $i = 0 To 4
        If $g_pageBackgrounds[$i] = 0 Then ContinueLoop
        GUICtrlSetPos($g_pageBackgrounds[$i], 2, 26, 395, $clientHeight - 30)
        GUICtrlSetBkColor($g_pageBackgrounds[$i], $background)
    Next
    For $id = 3 To 1000
        Local $handle = GUICtrlGetHandle($id)
        If Not IsHWnd($handle) Then ContinueLoop
        Local $class = _WinAPI_GetClassName($handle)
        Switch $class
            Case "Static", "Button"
                If $class = "Button" Then
                    If $g_theme = "dark" Then
                        DllCall("uxtheme.dll", "long", "SetWindowTheme", "hwnd", $handle, "wstr", "", "wstr", "")
                    Else
                        DllCall("uxtheme.dll", "long", "SetWindowTheme", "hwnd", $handle, "ptr", 0, "ptr", 0)
                    EndIf
                EndIf
                GUICtrlSetColor($id, $text)
                GUICtrlSetBkColor($id, $background)
            Case "Edit", "ListBox", "ComboBox"
                GUICtrlSetColor($id, $text)
                GUICtrlSetBkColor($id, $surface)
        EndSwitch
    Next
    Local $listControls[3] = [$g_listview, $g_recentListview, $g_categoryGrid]
    For $i = 0 To 2
        _GUICtrlListView_SetBkColor($listControls[$i], $surface)
        _GUICtrlListView_SetTextBkColor($listControls[$i], $surface)
        _GUICtrlListView_SetTextColor($listControls[$i], $text)
    Next
    If $g_windowHeightInput <> 0 Then GUICtrlSetData($g_windowHeightInput, $g_windowHeight)
    If $g_listHeightInput <> 0 Then GUICtrlSetData($g_listHeightInput, $g_listHeight)
    If $g_buttonWidthInput <> 0 Then GUICtrlSetData($g_buttonWidthInput, $g_buttonWidth)
    If $g_buttonHeightInput <> 0 Then GUICtrlSetData($g_buttonHeightInput, $g_buttonHeight)
    If $g_buttonSpacingInput <> 0 Then GUICtrlSetData($g_buttonSpacingInput, $g_buttonSpacing)
    If $g_opacityInput <> 0 Then GUICtrlSetData($g_opacityInput, $g_opacity)
EndFunc

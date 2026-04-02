Global $g_category_selected = "所有"

; 使用 Scripting.Dictionary 动态存储分类
; Key: 分类名称 (如 "副本60", "西部荒野" 等)
; Value: 该分类的传送点数组
Global $g_teleListDict = ObjCreate("Scripting.Dictionary")

; "所有" 分类单独存储
Global $g_teleList_whole[0]

; 初始化所有传送点列表（清空）
Func InitGlobalTeleportList()
    Redim $g_teleList_whole[0]
    
    ; 清空字典中所有分类
    $g_teleListDict.RemoveAll()
EndFunc

; 确保分类存在（不存在则创建空数组）
Func EnsureCategoryExists($categoryName)
    If $categoryName <> "所有" And Not $g_teleListDict.Exists($categoryName) Then
        Local $emptyArray[0]
        $g_teleListDict.Add($categoryName, $emptyArray)
    EndIf
EndFunc

; 获取所有分类名称数组（用于填充下拉框）
Func GetAllCategoryNames()
    If $g_teleListDict.Count > 0 Then
        Return $g_teleListDict.Keys
    Else
        Local $emptyArray[0]
        Return $emptyArray
    EndIf
EndFunc

Func _Func_telelist($paramCnt, $_func, ByRef $teleList, $p1=0, $p2=0, $p3=0, $p4=0, $p5=0)
    If $paramCnt = 0 Then
        return $_func($teleList)
    ElseIf $paramCnt = 1 Then
        return $_func($teleList, $p1)
    ElseIf $paramCnt = 2 Then
        return $_func($teleList, $p1, $p2)
    ElseIf $paramCnt = 3 Then
        return $_func($teleList, $p1, $p2, $p3)
    ElseIf $paramCnt = 4 Then
        return $_func($teleList, $p1, $p2, $p3, $p4)
    ElseIf $paramCnt = 5 Then
        return $_func($teleList, $p1, $p2, $p3, $p4, $p5)
    Else
        print("_Func_telelist function param is > 5, not supported now")
    EndIf
EndFunc

; 判断是否为修改数组的操作
Func _IsModifyOperation($_func)
    Return ($_func = _InsertPos_telelist Or $_func = _AddPos_telelist Or $_func = _EditPos_telelist Or $_func = _DelPos_telelist Or $_func = _GenTeleListByCategory)
EndFunc

Func Func_telelist($cateText, $_func, $p1=0, $p2=0, $p3=0, $p4=0, $p5=0)
    Local $paramCnt = @NumParams - 2
    Local $teleList
    Local $needUpdate = _IsModifyOperation($_func)

    ;~ print("paramCnt " & $paramCnt)
    
    If $cateText = "所有" Then
        ; "所有" 分类使用全局数组
        $teleList = $g_teleList_whole
        Local $result = _Func_telelist($paramCnt, $_func, $teleList, $p1, $p2, $p3, $p4, $p5)
        If $needUpdate Then
            $g_teleList_whole = $teleList
        EndIf
        Return $result
        
    ElseIf $g_teleListDict.Exists($cateText) Then
        ; 分类已存在
        $teleList = $g_teleListDict.Item($cateText)
        Local $result = _Func_telelist($paramCnt, $_func, $teleList, $p1, $p2, $p3, $p4, $p5)
        If $needUpdate Then
            $g_teleListDict.Item($cateText) = $teleList
        EndIf
        Return $result
        
    Else
        ; 分类不存在，创建新分类（用于 _GenTeleListByCategory）
        ; 或者使用 "其他" 分类
        If $_func = _GenTeleListByCategory Then
            ; 创建新分类
            Local $emptyArray[0]
            $g_teleListDict.Add($cateText, $emptyArray)
            $teleList = $emptyArray
        Else
            ; 使用 "其他" 分类
            $cateText = "其他"
            If Not $g_teleListDict.Exists($cateText) Then
                Local $emptyArray[0]
                $g_teleListDict.Add($cateText, $emptyArray)
            EndIf
            $teleList = $g_teleListDict.Item($cateText)
            If $_func = _GenTeleListByCategory Then
                $p2 = $cateText
            EndIf
        EndIf
        
        Local $result = _Func_telelist($paramCnt, $_func, $teleList, $p1, $p2, $p3, $p4, $p5)
        If $needUpdate Then
            $g_teleListDict.Item($cateText) = $teleList
        EndIf
        Return $result
    EndIf
EndFunc

Func _InsertPos_telelist(ByRef $teleList, $selectedLine, $text, $currPosArr)
    $columnCount = _GUICtrlListView_GetColumnCount($g_listview)
    _ArrayInsert($teleList, $selectedLine*$columnCount, $text)
    ;~ print(" insert " & $text & " UBound($teleList) is " & UBound($teleList))
    For $i = 1 to $columnCount - 1
        _ArrayInsert($teleList, $selectedLine*$columnCount+$i, $currPosArr[$i-1])
        ;~ print(" insert " & $currPosArr[$i-1] & " UBound($teleList) is " & UBound($teleList))
    Next
    ;~ For $i = 0 to UBound($teleList) - 1
    ;~     print($i & " teleList " & $teleList[$i])
    ;~ Next
EndFunc

Func InsertPos_telelist($cateText, $selectedLine, $text, $currPosArr)
    Func_telelist($cateText, _InsertPos_telelist, $selectedLine, $text, $currPosArr)
EndFunc

Func _AddPos_telelist(ByRef $teleList, $text, $currPosArr)
    _ArrayAdd($teleList, $text)
    ;~ print(" add " & $text & " UBound($teleList) is " & UBound($teleList))
    ;~ For $i = 0 to UBound($teleList) - 1
    ;~     print($i & " teleList " & $teleList[$i])
    ;~ Next
EndFunc

Func AddPos_telelist($cateText, $text, $currPosArr)
    Func_telelist($cateText, _AddPos_telelist, $text, $currPosArr)
EndFunc

Func _EditPos_telelist(ByRef $teleList, $selectedLine, $text, $currPosArr)
    $columnCount = _GUICtrlListView_GetColumnCount($g_listview)
    ;~ print("before")
    ;~ print($teleList[$columnCount*$selectedLine])
    ;~ print($teleList[$columnCount*$selectedLine+1])
    ;~ print($teleList[$columnCount*$selectedLine+2])
    ;~ print($teleList[$columnCount*$selectedLine+3])
    $teleList[$columnCount*$selectedLine] = $text
    $teleList[$columnCount*$selectedLine+1] = $currPosArr[0]
    $teleList[$columnCount*$selectedLine+2] = $currPosArr[1]
    $teleList[$columnCount*$selectedLine+3] = $currPosArr[2]
    ;~ print("after columnCount" & $columnCount & " selectedLine " & $selectedLine)
    ;~ print($teleList[$columnCount*$selectedLine])
    ;~ print($teleList[$columnCount*$selectedLine+1])
    ;~ print($teleList[$columnCount*$selectedLine+2])
    ;~ print($teleList[$columnCount*$selectedLine+3])
EndFunc

Func EditPos_telelist($cateText, $selectedLine, $text, $currPosArr)
    Func_telelist($cateText, _EditPos_telelist, $selectedLine, $text, $currPosArr)
EndFunc

Func _DelPos_telelist(ByRef $teleList, $selectedLine)
    Local $range = $selectedLine*4 & "-" & ($selectedLine*4+3)
    _ArrayDelete($teleList, $range)
    ;~ For $i = 0 to UBound($teleList) - 1
        ;~ print("delete " & $selectedLine)
    ;~ Endif
EndFunc

Func DelPos_telelist($cateText, $selectedLine)
    If $selectedLine >= 0 Then
        Func_telelist($cateText, _DelPos_telelist, $selectedLine)
    EndIf
EndFunc

Func _Save_telelist(ByRef $teleList)
    return $teleList
EndFunc

Func Save_telelist($cateText)
    return Func_telelist($cateText, _Save_telelist)
EndFunc

Func _GenTeleListByCategory(ByRef $teleList, $category, $cateText, $telePointText)
    _ArrayAdd($teleList, $telePointText)
    Set_Add($category, $cateText)
    return $category
EndFunc

Func GenTeleListByCategory($category, $cateText, $telePointText)
    return Func_telelist($cateText, _GenTeleListByCategory, $category, $cateText, $telePointText)
EndFunc

Func _SwitchListviewWithCategory(ByRef $telelist, $cateText)
    Local $listview
    $listview = InitListviewWithList($telelist, $cateText)
    return $listview
EndFunc

Func SwitchListviewWithCategory($cateText)
    return Func_telelist($cateText, _SwitchListviewWithCategory, $cateText)
EndFunc

Func InitListviewWithList(ByRef $array, $info="")
    Local $listview = $g_listview

    ; 暂停重绘，避免逐条添加时每次都触发ListView重绘
    _GUICtrlListView_BeginUpdate($listview)

    _GUICtrlListView_DeleteAllItems($listview)

    print("reload with category:")
    print($info)

    $columnCount = _GUICtrlListView_GetColumnCount($listview)
    
    print("array ubound : " & UBound($array))
    Local $lineCount = UBound($array)
    print("$lineCount : " & $lineCount)

    Local $i = 0
    While $i + $columnCount-1 < $lineCount
        $text = $array[$i]
        For $c = 1 to $columnCount - 1
            $text = $text & "|" & $array[$i+$c]
        Next
        $i = $i + $columnCount
        GUICtrlCreateListViewItem($text, $listview)
    WEnd

    ; 恢复重绘，一次性渲染所有条目
    _GUICtrlListView_EndUpdate($listview)

    return $listview
EndFunc

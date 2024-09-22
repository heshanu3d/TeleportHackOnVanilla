Global $g_category_selected = "所有"

Global $g_teleList_fuben[0]
Global $g_teleList_arwsl[0]
Global $g_teleList_city[0]
Global $g_teleList_other[0]

Func InitGlobalTeleportList()
    Redim $g_teleList_whole[0]
    Redim $g_teleList_fuben[0]
    Redim $g_teleList_arwsl[0]
    Redim $g_teleList_city[0]
    Redim $g_teleList_other[0]
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

Func Func_telelist($cateText, $_func, $p1=0, $p2=0, $p3=0, $p4=0, $p5=0)
    Local $paramCnt = @NumParams - 2
    ;~ print("paramCnt " & $paramCnt)
    If $cateText = "所有" Then
        return _Func_telelist($paramCnt, $_func, $g_teleList_whole, $p1, $p2, $p3, $p4, $p5)
    ElseIf $cateText = "副本" Then
        return _Func_telelist($paramCnt, $_func, $g_teleList_fuben, $p1, $p2, $p3, $p4, $p5)
    ElseIf $cateText = "艾尔文森林" Then
        return _Func_telelist($paramCnt, $_func, $g_teleList_arwsl, $p1, $p2, $p3, $p4, $p5)
    ElseIf $cateText = "主城" Then
        return _Func_telelist($paramCnt, $_func, $g_teleList_city,  $p1, $p2, $p3, $p4, $p5)
    Else
        $cateText = "其他"
        If $_func = _GenTeleListByCategory Then
            $p2 = $cateText
        EndIf
        return _Func_telelist($paramCnt, $_func, $g_teleList_other, $p1, $p2, $p3, $p4, $p5)
    Endif
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
    ;~     print($i & " teleList " & $teleList[$i])
    ;~ Next
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
    ;~ If $cateText = "所有" Then
    ;~ ElseIf $cateText = "副本" Then
    ;~ ElseIf $cateText = "艾尔文森林" Then
    ;~ ElseIf $cateText = "主城" Then
    ;~ Else
    ;~     $cateText = "其他"
    ;~ EndIf
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
    ;~ refactor
    ;~ GUICtrlDelete($g_listview)
    Local $listview = $g_listview
    _GUICtrlListView_Scroll($listview, 0, -10000)
    _GUICtrlListView_DeleteAllItems($listview)

    print("reload with category:")
    print($info)

    ;~ refactor
    ;~ $listview = GUICtrlCreateListView("        描述        |      x      |      y      |      z      ", 10, 20, 380, 490)
    ;~ GUICtrlSendMsg($listview, $LVM_SETCOLUMNWIDTH, 0, 250)
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

    return $listview
EndFunc

Global $logLineCnt = 0
Func print($content)
    ;~ _GUICtrlRichEdit_AppendText($g_log, $content & @CR)
    $logLineCnt = $logLineCnt + 1
    If $logLineCnt > 80 Then
        _GUICtrlEdit_SetText($g_log, "")
        $logLineCnt = 0
    EndIf
    _GUICtrlEdit_AppendText($g_log, $content & @CRLF)
    ConsoleWrite($content & @CR)
EndFunc

Func _WinGetHandleByPidAndCls($pid, $class)
   ; 这里使用枚举所有顶层窗口方法，WinList方法会返回大量隐藏窗口
   Local $winArr = _WinAPI_EnumWindowsTop()
   ; 遍历所有窗口,进程id与指定进程id比较
   For $i=1 To $winArr[0][0]
      If $pid=WinGetProcess($winArr[$i][0]) And $winArr[$i][1]=$class Then
         ; 一个进程会有多个窗口，所以要用class来筛选
         return $winArr[$i][0]
      EndIf
   Next
   Return 0
EndFunc

; 根据pname和class获取窗口句柄，找不到则返回0
Func _WinGetHandleByPnmAndCls($pname, $class)
   ; 根据进程名查找进程id
   Local $pid = ProcessExists($pname)
   ; 如果进程存在，继续
   If $pid Then
      return _WinGetHandleByPidAndCls($pid, $class)
   Else
      Return 0
   EndIf
EndFunc

Func _CodepageToString($sCP, $iCodepage = Default)
    If $iCodepage = Default Then $iCodepage = Int(RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Nls\Codepage", "OEMCP"))
    Local $tText = DllStructCreate("byte[" & StringLen($sCP) & "]")
    DllStructSetData($tText, 1, $sCP)
    Local $aResult = DllCall("kernel32.dll", "int", "MultiByteToWideChar", "uint", $iCodepage, "dword", 0, "struct*", $tText, "int", -1, _
            "ptr", 0, "int", 0)
    Local $tWstr = DllStructCreate("wchar[" & ($aResult[0]+1)*2 & "]")
    $aResult = DllCall("kernel32.dll", "int", "MultiByteToWideChar", "uint", $iCodepage, "dword", 0, "struct*", $tText, "int", -1, _
            "struct*", $tWstr, "int", $aResult[0])
    Return DllStructGetData($tWstr, 1)
EndFunc   ;==>_CodepageToString

Func _CodepageToStringRRR($sCP, $iCodepage = Default)
    If $iCodepage = Default Then $iCodepage = Int(RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Nls\Codepage", "OEMCP"))
    Local $tText = DllStructCreate("byte[" & StringLen($sCP) & "]")
    DllStructSetData($tText, 1, $sCP)
    Local $aResult = DllCall("kernel32.dll", "int", "MultiByteToWideChar", "uint", $iCodepage, "dword", 0, "struct*", $tText, "int", StringLen($sCP), _
            "ptr", 0, "int", 0)
    Local $tWstr = DllStructCreate("wchar[" & $aResult[0] & "]")
    $aResult = DllCall("kernel32.dll", "int", "MultiByteToWideChar", "uint", $iCodepage, "dword", 0, "struct*", $tText, "int", StringLen($sCP), _
            "struct*", $tWstr, "int", $aResult[0])
    Return DllStructGetData($tWstr, 1)
EndFunc   ;==>_CodepageToString

Func _StringToCodepage($sStr, $iCodepage = Default)
    If $iCodepage = Default Then $iCodepage = Int(RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Nls\Codepage", "OEMCP"))
    Local $aResult = DllCall("kernel32.dll", "int", "WideCharToMultiByte", "uint", $iCodepage, "dword", 0, "wstr", $sStr, "int", StringLen($sStr), _
            "ptr", 0, "int", 0, "ptr", 0, "ptr", 0)
    Local $tCP = DllStructCreate("char[" & $aResult[0] & "]")
    $aResult = DllCall("Kernel32.dll", "int", "WideCharToMultiByte", "uint", $iCodepage, "dword", 0, "wstr", $sStr, "int", StringLen($sStr), _
            "struct*", $tCP, "int", $aResult[0], "ptr", 0, "ptr", 0)
    Return DllStructGetData($tCP, 1)
EndFunc   ;==>_StringToCodepage

Func Asc2Unicode($AscString)
    Local $BufferSize = StringLen($AscString) * 2
    Local $Buffer = DllStructCreate("byte[" & $BufferSize & "]")
    Local $Return = DllCall("Kernel32.dll", "int", "MultiByteToWideChar", _
        "int", 0, _
        "int", 0, _
        "str", $AscString, _
        "int", StringLen($AscString), _
        "ptr", DllStructGetPtr($Buffer), _
        "int", $BufferSize)
    Local $UnicodeString = StringLeft(DllStructGetData($Buffer, 1), $Return[0] * 2)
    $Buffer = 0
    Return $UnicodeString
EndFunc

Func Unicode2Asc($UniString)
    If Not IsBinary($UniString) Then
        SetError(1)
        Return $UniString
    EndIf

    Local $BufferLen = StringLen($UniString)
    Local $Input = DllStructCreate("byte[" & $BufferLen & "]")
    Local $Output = DllStructCreate("char[" & $BufferLen & "]")
    DllStructSetData($Input, 1, $UniString)
    Local $Return = DllCall("kernel32.dll", "int", "WideCharToMultiByte", _
        "int", 0, _
        "int", 0, _
        "ptr", DllStructGetPtr($Input), _
        "int", $BufferLen / 2, _
        "ptr", DllStructGetPtr($Output), _
        "int", $BufferLen, _
        "int", 0, _
        "int", 0)
    Local $AscString = DllStructGetData($Output, 1)
    $Output = 0
    $Input = 0
    Return $AscString
EndFunc

Func Unicode2Utf8($UniString)
    If Not IsBinary($UniString) Then
        SetError(1)
        Return $UniString
    EndIf

    Local $UniStringLen = StringLen($UniString)
    Local $BufferLen = $UniStringLen * 2
    Local $Input = DllStructCreate("byte[" & $BufferLen & "]")
    Local $Output = DllStructCreate("char[" & $BufferLen & "]")
    DllStructSetData($Input, 1, $UniString)
    Local $Return = DllCall("kernel32.dll", "int", "WideCharToMultiByte", _
        "int", 65001, _
        "int", 0, _
        "ptr", DllStructGetPtr($Input), _
        "int", $UniStringLen / 2, _
        "ptr", DllStructGetPtr($Output), _
        "int", $BufferLen, _
        "int", 0, _
        "int", 0)
    Local $Utf8String = DllStructGetData($Output, 1)
    $Output = 0
    $Input = 0
    Return $Utf8String
EndFunc

Func Utf82Unicode($Utf8String)
    Local $BufferSize = StringLen($Utf8String) * 2
    Local $Buffer = DllStructCreate("byte[" & $BufferSize & "]")
    Local $Return = DllCall("Kernel32.dll", "int", "MultiByteToWideChar", _
        "int", 65001, _
        "int", 0, _
        "str", $Utf8String, _
        "int", StringLen($Utf8String), _
        "ptr", DllStructGetPtr($Buffer), _
        "int", $BufferSize)
    Local $UnicodeString = StringLeft(DllStructGetData($Buffer, 1), $Return[0] * 2)
    $Buffer = 0
    Return $UnicodeString
EndFunc

Func Set_Add(ByRef $set, $value)
    If _ArraySearch($set, $value, 0, False, -1) = -1 Then
        _ArrayAdd($set, $value)
    EndIf
EndFunc

Func Set_Contains(ByRef $set, $value)
    Return _ArraySearch($set, $value, 0, False, -1) <> -1
EndFunc

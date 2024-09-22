Func HotKeyInit()
	HotKeyRegFromConfigFile()
	HotKeyReg()
EndFunc

Func HotKeyReg()
	HotKeySet("!a", "HotKeyProcs")
	HotKeySet("!c", "HotKeyProcs")
	HotKeySet("!j", "HotKeyProcs")
	HotKeySet("!l", "HotKeyProcs")
	HotKeySet("!p", "HotKeyProcs")
	HotKeySet("!x", "HotKeyProcs")
	;HotKeySet("!1", "HotKeyProcs")
	;HotKeySet("!2", "HotKeyProcs")
	;HotKeySet("!3", "HotKeyProcs")
	For $i = 0 To $hotkeyRegFromFileConfigArrayLen
		HotKeySet($hotkeyRegFromFileConfigArray[$i][0], "HotKeyProcs")
	Next
EndFunc

Func HotKeyProcs()
	$keyPressed = @HotKeyPressed
	Switch $keyPressed
		Case "!a"
			Autoloot()
		Case "!c"
			$g_startBot = False
		Case "!j"
			AntiJump()
		Case "!l"
			LuaUnlock()
		Case "!p"
			PatchLoot()
		Case "!x"
			Teleport($g_listview)
	EndSwitch
	For $i = 0 To $hotkeyRegFromFileConfigArrayLen
		If $keyPressed = $hotkeyRegFromFileConfigArray[$i][0] Then
			TeleportInterface($hotkeyRegFromFileConfigArray[$i][2], $hotkeyRegFromFileConfigArray[$i][3], $hotkeyRegFromFileConfigArray[$i][4])
			Return
		EndIf
	Next
EndFunc

Func FindPostionFromFavFile($postionText, $tpInfoArray, $tpInfoCount)
	$columnCount = 4 ; $columnCount = _GUICtrlListView_GetColumnCount($listview), this should be 4,  modified later
    If @error Then
        MsgBox($MB_SYSTEMMODAL, "", "There was an error reading the file. @error: " & @error)
		Local $posArr[1] = [0]
		Return $posArr
    Else
        Local $i = 0
        While $i + $columnCount-1 < $tpInfoCount
			If $tpInfoArray[$i] = $postionText Then
				Local $posArr[3] = [$tpInfoArray[$i+1], $tpInfoArray[$i+2], $tpInfoArray[$i+3]]
				return $posArr
			EndIf
            $i = $i + $columnCount
        WEnd
    EndIf
EndFunc

Func HotKeyRegFromConfigFile()
	Local $tpInfoArray = FileReadToArray($teleport_file)
    Local $tpInfoArrayCount = @extended
	If @error Then
        MsgBox($MB_SYSTEMMODAL, "", "There was an error reading tp file. @error: " & @error)
		$fileHandle = FileOpen($teleport_file, $FO_OVERWRITE)
		Return
	EndIf

	Local $hotkeyInfoArray = FileReadToArray($hotkey_file)
    Local $lineCount = @extended
	print("hotkeyfile len:" & $lineCount)
    If @error Then
        MsgBox($MB_SYSTEMMODAL, "", "There was an error reading hotkey file. @error: " & @error)
    Else
        Local $i = 1 								; start from 1 because the first line is comment
		Local $columnCount = 2 						; first line is hotkey, second line is position key
        While $i + $columnCount-1 < $lineCount
            $hotkey = $hotkeyInfoArray[$i]
            $posKey = $hotkeyInfoArray[$i+1]
			$posInfo = FindPostionFromFavFile($posKey, $tpInfoArray, $tpInfoArrayCount)
            If UBound($posInfo) = 3 Then
				If $hotkeyRegFromFileConfigArrayLen < $hotkeyRegFromFileConfigArrayMaxLen Then
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][0] = $hotkey
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][1] = $posKey
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][2] = $posInfo[0]
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][3] = $posInfo[1]
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][4] = $posInfo[2]
					$hotkeyRegFromFileConfigArrayLen = $hotkeyRegFromFileConfigArrayLen + 1
					print("reg " & $posKey & "hot key success")
				EndIf
			EndIf
			$i = $i + $columnCount
        WEnd
    EndIf
EndFunc